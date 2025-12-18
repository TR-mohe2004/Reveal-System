from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from decimal import Decimal
from django.db import transaction
from django.core.cache import cache
from django.conf import settings
from firebase_admin import auth as fb_auth

from .models import Product, Order, OrderItem, Cafe
from wallet.models import Wallet, Transaction
from .serializers import ProductSerializer, OrderSerializer, CafeSerializer, UserSerializer
from .utils import send_real_notification
from services.payment_service import execute_purchase_transaction


def verify_token_get_phone(request):
    """
    يتحقق من Firebase ID Token ويعيد رقم الهاتف.
    """
    auth_header = request.META.get('HTTP_AUTHORIZATION', '')
    if not auth_header.startswith('Bearer '):
        raise ValueError("Missing Authorization")
    token = auth_header.split(' ', 1)[1]
    decoded = fb_auth.verify_id_token(token)
    phone = decoded.get('phone_number')
    if not phone:
        raise ValueError("Missing phone in token")
    return phone


PRODUCTS_CACHE_KEY = "products:list"
PRODUCTS_TTL = 1800  # 30 دقيقة


def get_products_cached():
    cached = cache.get(PRODUCTS_CACHE_KEY)
    if cached:
        return cached
    products = list(Product.objects.select_related('cafe', 'category').filter(is_available=True).order_by('-created_at'))
    cache.set(PRODUCTS_CACHE_KEY, products, PRODUCTS_TTL)
    return products


def invalidate_products_cache():
    cache.delete(PRODUCTS_CACHE_KEY)


@api_view(['GET'])
@permission_classes([AllowAny])
def get_cafes_list(request):
    """
    قائمة المقاهي/الكليات المتاحة للتطبيق.
    """
    cafes = Cafe.objects.all().order_by('name')
    serializer = CafeSerializer(cafes, many=True)
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([AllowAny])
def get_products(request):
    """
    إرجاع منتجات مقهى محدد. يتطلب cafe_id.
    """
    cafe_id = request.GET.get('cafe_id')
    if not cafe_id:
        return Response({'error': 'cafe_id مطلوب'}, status=400)

    products = [p for p in get_products_cached() if str(p.cafe_id) == str(cafe_id)]

    category_id = request.GET.get('category_id')
    category_name = request.GET.get('category') or request.GET.get('category_name')
    available_only = request.GET.get('available')

    if category_id:
        products = products.filter(category_id=category_id)
    elif category_name:
        products = products.filter(category__name__iexact=category_name)

    if available_only and str(available_only).lower() in ['1', 'true', 'yes']:
        products = products.filter(is_available=True)

    serializer = ProductSerializer(products, many=True, context={'request': request})
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_profile(request):
    serializer = UserSerializer(request.user)
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_order(request):
    user = request.user
    total_price_raw = request.data.get('total_price')
    items_data = request.data.get('items')

    if total_price_raw is None or not items_data:
        return Response({'error': 'إجمالي الطلب أو العناصر مفقود'}, status=400)

    if len(items_data) == 0:
        return Response({'error': 'السلة فارغة'}, status=400)

    try:
        total_price = Decimal(str(total_price_raw))
    except Exception:
        return Response({'error': 'Invalid total_price'}, status=400)

    try:
        with transaction.atomic():
            wallet = Wallet.objects.get(user=user)
            if wallet.balance < total_price:
                return Response({'error': 'الرصيد غير كافٍ'}, status=400)

            # تأكد أن كل المنتجات من نفس المقهى
            product_ids = [item.get('product_id') for item in items_data]
            products = Product.objects.filter(id__in=product_ids).select_related('cafe')
            cafes = {p.cafe_id for p in products}
            if not products or len(cafes) != 1:
                return Response({'error': 'كل عناصر السلة يجب أن تتبع نفس المقهى'}, status=400)
            target_cafe_id = cafes.pop()

            new_order = Order.objects.create(
                user=user,
                cafe_id=target_cafe_id,
                total_price=total_price,
                status='PENDING'
            )

            for item in items_data:
                product_id = item.get('product_id')
                qty = item.get('quantity', item.get('qty', 1))
                product = products.filter(id=product_id).first()
                if not product:
                    raise Product.DoesNotExist()
                OrderItem.objects.create(
                    order=new_order,
                    product=product,
                    quantity=qty,
                    price=product.price
                )

            Transaction.objects.create(
                wallet=wallet,
                amount=total_price,
                transaction_type='WITHDRAWAL',
                source='APP',
                description=f'طلب #{new_order.order_number}'
            )

        send_real_notification(user, "تم استلام طلبك", f"طلبك #{new_order.order_number} قيد المعالجة.")
        return Response({'message': 'تم إنشاء الطلب بنجاح', 'order_id': new_order.id}, status=201)

    except Wallet.DoesNotExist:
        return Response({'error': 'المحفظة غير موجودة'}, status=404)
    except Product.DoesNotExist:
        return Response({'error': 'منتج غير متوفر'}, status=400)
    except Exception as e:
        print(f"Order Error: {e}")
        return Response({'error': str(e)}, status=500)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_orders(request):
    orders = Order.objects.filter(user=request.user).order_by('-created_at')
    serializer = OrderSerializer(orders, many=True)
    return Response(serializer.data)


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def orders_endpoint(request):
    """
    Combined endpoint to list user orders (GET) or create a new order (POST).
    """
    if request.method == 'GET':
        return get_user_orders(request)
    return create_order(request)


@api_view(['POST'])
@permission_classes([AllowAny])
def api_purchase(request):
    """
    عملية شراء تعتمد على Firebase ID Token + معاملة ذرية في Firestore.
    """
    try:
        phone = verify_token_get_phone(request)
    except Exception as e:
        return Response({'error': str(e)}, status=401)

    items = request.data.get('items', [])
    if not items:
        return Response({'error': 'items required'}, status=400)

    # احتساب الإجمالي من البيانات المرسلة
    try:
        total_price = float(request.data.get('total_price', 0)) or sum(
            float(i.get('price', 0)) * float(i.get('quantity', i.get('qty', 1))) for i in items
        )
    except Exception:
        return Response({'error': 'invalid pricing data'}, status=400)

    if total_price <= 0:
        return Response({'error': 'invalid total'}, status=400)

    if not settings.FIRESTORE_DB:
        return Response({'error': 'payment service unavailable'}, status=503)

    try:
        new_balance = execute_purchase_transaction(settings.FIRESTORE_DB, phone, total_price, items)
        return Response({'message': 'success', 'balance': new_balance})
    except ValueError as e:
        msg = str(e)
        code = msg.split(':')[0] if ':' in msg else 'ERROR'
        return Response({'error': msg, 'code': code}, status=400)
    except Exception as e:
        print("Purchase error:", e)
        return Response({'error': 'internal'}, status=500)
