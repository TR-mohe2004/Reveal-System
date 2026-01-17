from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from decimal import Decimal
import re
from django.db import transaction
from django.db.models import Q
from django.core.cache import cache
from django.conf import settings

# ✅ استدعاءات صحيحة (مودلز جانغو فقط)
from .models import Product, Order, OrderItem, Cafe
from wallet.models import Wallet, Transaction
from .serializers import ProductSerializer, OrderSerializer, CafeSerializer, UserSerializer
from users.models import User
from .utils import send_real_notification, normalize_libyan_phone

# ❌ تم حذف استدعاء payment_service_OLD لأنه يسبب تضارباً
# ❌ تم حذف firebase_admin لأننا نعتمد على توكن جانغو

# --- Caching Setup (ممتاز، أبقينا عليه) ---
PRODUCTS_CACHE_KEY = "products:list:v2"
PRODUCTS_TTL = 1800  # 30 دقيقة

def get_products_cached():
    cached = cache.get(PRODUCTS_CACHE_KEY)
    if cached:
        return cached
    # جلب المنتجات من قاعدة بيانات SQL
    products = list(Product.objects.select_related('cafe', 'category').order_by('-created_at'))
    cache.set(PRODUCTS_CACHE_KEY, products, PRODUCTS_TTL)
    return products

def invalidate_products_cache():
    cache.delete(PRODUCTS_CACHE_KEY)


@api_view(['GET'])
@permission_classes([AllowAny])
def get_cafes_list(request):
    cafes = Cafe.objects.filter(is_active=True).order_by('name')
    serializer = CafeSerializer(cafes, many=True, context={'request': request})
    return Response(serializer.data)


@api_view(['GET'])
@permission_classes([AllowAny])
def get_products(request):
    cafe_id = request.GET.get('cafe_id')
    
    # 1. جلب المنتجات (سواء من الكاش أو الداتابيز)
    # ملاحظة: إذا لم يحدد cafe_id نرسل الكل أو فارغ حسب سياستك
    all_products = get_products_cached()
    
    if cafe_id:
        products = [p for p in all_products if str(p.cafe_id) == str(cafe_id)]
    else:
        products = all_products # أو [] إذا أردت إجبار اختيار المقهى

    # 2. التصفية (Filtering)
    category_id = request.GET.get('category_id')
    category_name = request.GET.get('category') or request.GET.get('category_name')
    available_only = request.GET.get('available')

    if category_id:
        products = [p for p in products if str(p.category_id) == str(category_id)]
    elif category_name:
        products = [p for p in products if p.category.name.lower() == category_name.lower()]

    if available_only and str(available_only).lower() in ['1', 'true', 'yes']:
        products = [p for p in products if p.is_available]

    serializer = ProductSerializer(products, many=True, context={'request': request})
    return Response(serializer.data)



@api_view(['POST'])
@permission_classes([IsAuthenticated])
def update_secondary_phone(request):
    raw_phone = (request.data.get('secondary_phone') or request.data.get('secondary_phone_number') or '').strip()

    if raw_phone == '':
        request.user.secondary_phone_number = None
        request.user.save(update_fields=['secondary_phone_number'])
        return Response({'secondary_phone': None})

    phone = normalize_libyan_phone(raw_phone)
    if not phone or not re.fullmatch(r'09\d{8}', phone):
        return Response({'error': '??? ?????? ??? ????.'}, status=400)

    exists = User.objects.filter(
        Q(phone_number=phone) | Q(secondary_phone_number=phone)
    ).exclude(id=request.user.id).exists()
    if exists:
        return Response({'error': '??? ?????? ?????? ?? ???.'}, status=400)

    request.user.secondary_phone_number = phone
    request.user.save(update_fields=['secondary_phone_number'])
    return Response({'secondary_phone': phone})


@api_view(['GET', 'PATCH'])
@permission_classes([IsAuthenticated])
def get_user_profile(request):
    if request.method == 'GET':
        serializer = UserSerializer(request.user)
        return Response(serializer.data)

    full_name = (request.data.get('full_name') or request.data.get('name') or '').strip()
    profile_image_url = (request.data.get('profile_image_url') or '').strip()

    if not full_name:
        return Response({'error': 'الاسم مطلوب.'}, status=400)

    update_fields = []
    if full_name and request.user.full_name != full_name:
        request.user.full_name = full_name
        update_fields.append('full_name')

    if 'profile_image_url' in request.data:
        request.user.profile_image_url = profile_image_url or None
        update_fields.append('profile_image_url')

    if update_fields:
        request.user.save(update_fields=update_fields)

    serializer = UserSerializer(request.user)
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_order(request):
    """
    ????? ????? ?? ??? ????? ??? ??????? ?? ???.
    """
    user = request.user
    total_price_raw = request.data.get('total_price')
    items_data = request.data.get('items')
    payment_method = 'WALLET'

    if total_price_raw is None or not items_data:
        return Response({'error': '???? ????? ????? ?????????.'}, status=400)

    if len(items_data) == 0:
        return Response({'error': '????? ?????.'}, status=400)

    try:
        total_price = Decimal(str(total_price_raw))
    except Exception:
        return Response({'error': 'Invalid total_price'}, status=400)

    try:
        with transaction.atomic():
            product_ids = [item.get('product_id') for item in items_data]
            products = list(Product.objects.filter(id__in=product_ids).select_related('cafe'))

            if len(products) != len(set(product_ids)):
                return Response({'error': '???? ??? ?????.'}, status=400)

            cafes = {p.cafe_id for p in products}
            if len(cafes) != 1:
                return Response({'error': '??? ?? ???? ???? ???????? ?? ??? ??????.'}, status=400)
            target_cafe_id = cafes.pop()

            if payment_method == 'WALLET':
                try:
                    wallet = Wallet.objects.select_for_update().get(user=user)
                except Wallet.DoesNotExist:
                    return Response({'error': '??????? ??? ??????.'}, status=404)

                if wallet.balance < total_price:
                    return Response({'error': '???? ??????? ??? ????.'}, status=400)

                Transaction.objects.create(
                    wallet=wallet,
                    amount=total_price,
                    transaction_type='WITHDRAWAL',
                    source='APP',
                    description='??? ????'
                )

            new_order = Order.objects.create(
                user=user,
                cafe_id=target_cafe_id,
                total_price=total_price,
                status='PENDING',
                payment_method=payment_method
            )

            for item in items_data:
                product_id = item.get('product_id')
                qty = item.get('quantity', item.get('qty', 1))
                product = next((p for p in products if str(p.id) == str(product_id)), None)

                if not product:
                    return Response({'error': '???? ??? ?????.'}, status=400)

                options = item.get('options') or item.get('note') or ''
                OrderItem.objects.create(
                    order=new_order,
                    product=product,
                    quantity=qty,
                    price=product.price,
                    options=options
                )

        try:
            send_real_notification(user, "?? ?????? ????", f"???? #{new_order.order_number} ??? ????????.")
        except Exception:
            pass

        return Response({'message': '?? ????? ????? ?????', 'order_id': new_order.id}, status=201)

    except Exception as e:
        print(f"Order Error: {e}")
        return Response({'error': '??? ??? ????? ????? ?????.'}, status=500)

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
    نقطة تجمع الطلبات لعرضها أو إنشائها.
    """
    if request.method == 'GET':
        # تمرير الطلب الأصلي لتجنب مشاكل الصلاحيات
        return get_user_orders(request._request)
    return create_order(request._request)

# ❌ تم حذف api_purchase نهائياً لأنه يعتمد على Firebase
