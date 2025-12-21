from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from decimal import Decimal
from django.db import transaction
from django.core.cache import cache
from django.conf import settings

# ✅ استدعاءات صحيحة (مودلز جانغو فقط)
from .models import Product, Order, OrderItem, Cafe
from wallet.models import Wallet, Transaction
from .serializers import ProductSerializer, OrderSerializer, CafeSerializer, UserSerializer
from .utils import send_real_notification

# ❌ تم حذف استدعاء payment_service_OLD لأنه يسبب تضارباً
# ❌ تم حذف firebase_admin لأننا نعتمد على توكن جانغو

# --- Caching Setup (ممتاز، أبقينا عليه) ---
PRODUCTS_CACHE_KEY = "products:list"
PRODUCTS_TTL = 1800  # 30 دقيقة

def get_products_cached():
    cached = cache.get(PRODUCTS_CACHE_KEY)
    if cached:
        return cached
    # جلب المنتجات من قاعدة بيانات SQL
    products = list(Product.objects.select_related('cafe', 'category').filter(is_available=True).order_by('-created_at'))
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


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_profile(request):
    serializer = UserSerializer(request.user)
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_order(request):
    """
    ✅ هذه هي دالة الشراء الوحيدة المعتمدة.
    تقوم بالخصم من المحفظة وإنشاء الطلب في نفس الوقت داخل قاعدة بيانات Django.
    """
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
            # 1. قفل المحفظة وجلبها
            wallet = Wallet.objects.select_for_update().get(user=user)
            
            # 2. التحقق من الرصيد
            if wallet.balance < total_price:
                return Response({'error': 'الرصيد غير كافٍ'}, status=400)

            # 3. التحقق من المنتجات (يجب أن تكون من نفس المقهى)
            product_ids = [item.get('product_id') for item in items_data]
            products = Product.objects.filter(id__in=product_ids).select_related('cafe')
            
            if len(products) != len(set(product_ids)):
                 return Response({'error': 'بعض المنتجات غير موجودة'}, status=400)

            cafes = {p.cafe_id for p in products}
            if len(cafes) != 1:
                return Response({'error': 'كل عناصر السلة يجب أن تتبع نفس المقهى'}, status=400)
            target_cafe_id = cafes.pop()

            # 4. ✅ إنشاء المعاملة المالية (Transaction Model)
            # هذا الإجراء سيقوم بخصم الرصيد تلقائياً لأننا برمجنا ذلك في المودل
            Transaction.objects.create(
                wallet=wallet,
                amount=total_price,
                transaction_type='WITHDRAWAL',
                source='APP',
                description='طلب تطبيق'
            )

            # 5. إنشاء الطلب (Order Model)
            new_order = Order.objects.create(
                user=user,
                cafe_id=target_cafe_id,
                total_price=total_price,
                status='PENDING'
            )

            # 6. إضافة العناصر (Order Items)
            for item in items_data:
                product_id = item.get('product_id')
                qty = item.get('quantity', item.get('qty', 1))
                # البحث عن المنتج في القائمة التي جلبناها سابقاً لتقليل الاستعلامات
                product = next((p for p in products if str(p.id) == str(product_id)), None)
                
                OrderItem.objects.create(
                    order=new_order,
                    product=product,
                    quantity=qty,
                    price=product.price
                )

        # إرسال الإشعار (خارج الترانزكشن لتسريع الاستجابة)
        try:
            send_real_notification(user, "تم استلام طلبك", f"طلبك #{new_order.order_number} قيد المعالجة.")
        except:
            pass

        return Response({'message': 'تم إنشاء الطلب بنجاح', 'order_id': new_order.id}, status=201)

    except Wallet.DoesNotExist:
        return Response({'error': 'المحفظة غير موجودة، يرجى التواصل مع الدعم'}, status=404)
    except ValueError as e:
        return Response({'error': str(e)}, status=400)
    except Exception as e:
        print(f"Order Error: {e}")
        return Response({'error': 'حدث خطأ غير متوقع'}, status=500)


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