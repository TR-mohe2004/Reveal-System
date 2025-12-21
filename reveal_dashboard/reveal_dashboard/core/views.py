from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib import messages
from django.conf import settings
from django.db import transaction
from django.db.models import Q
from decimal import Decimal
import re

# --- DRF Imports ---
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.authtoken.models import Token

# --- Models & Serializers ---
from .models import Product, Cafe, Category, Order, OrderItem
from users.models import User
from wallet.models import Wallet, Transaction
from .forms import ProductForm
from .serializers import ProductSerializer, OrderSerializer, UserSerializer, CafeSerializer
from .utils import normalize_libyan_phone, send_real_notification, get_smart_image_for_product

DEFAULT_CATEGORY_NAMES = ['Food', 'Drinks', 'Snacks']

# --- Helper Functions ---

def get_cafe_for_user(user):
    """
    جلب المقهى المرتبط بالمستخدم، أو أول مقهى للأدمن.
    """
    cafe = getattr(user, 'my_cafe', None)
    if not cafe and user.is_superuser:
        cafe = Cafe.objects.first()
    return cafe

def ensure_categories_for_cafe(cafe):
    """
    التأكد من وجود تصنيفات افتراضية للمقهى.
    """
    categories_qs = Category.objects.filter(products__cafe=cafe).distinct()
    if not categories_qs.exists():
        for name in DEFAULT_CATEGORY_NAMES:
            Category.objects.get_or_create(name=name)
        categories_qs = Category.objects.filter(name__in=DEFAULT_CATEGORY_NAMES)
    return categories_qs


# =========================================================
#  SECTION 1: API (MOBILE APP)
# =========================================================

@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny])
def api_login(request):
    raw_identifier = request.data.get('phone_number') or request.data.get('email')
    password = request.data.get('password')
    fcm_token = request.data.get('fcm_token')

    if not raw_identifier or not password:
        return Response({'error': 'الهاتف/البريد وكلمة المرور مطلوبة'}, status=400)      

    # محاولة التطبيع كرقم هاتف
    phone = normalize_libyan_phone(raw_identifier)
    
    user_obj = None
    if phone:
        user_obj = User.objects.filter(phone_number=phone).first()
    
    # إذا لم يوجد بالهاتف، نجرب كبريد إلكتروني
    if not user_obj and '@' in str(raw_identifier):
        user_obj = User.objects.filter(email__iexact=str(raw_identifier).strip()).first()

    if not user_obj:
        return Response({'error': 'المستخدم غير موجود'}, status=400)

    # المصادقة باستخدام الايميل دائماً (لأن Django auth يعتمد عليه في هذا المشروع)
    user = authenticate(request, username=user_obj.email, password=password)
    
    if user:
        # تحديث توكن الإشعارات
        if fcm_token and hasattr(user, 'fcm_token'):
            user.fcm_token = fcm_token
            user.save(update_fields=['fcm_token'])

        token, _ = Token.objects.get_or_create(user=user)
        
        # جلب رصيد المحفظة بأمان
        balance = 0
        if hasattr(user, 'wallet'):
            balance = user.wallet.balance

        return Response({
            'token': token.key,
            'user': {
                'id': user.id,
                'phone_number': user.phone_number,
                'full_name': user.full_name,
                'email': user.email,
                'wallet_balance': balance
            }
        })

    return Response({'error': 'كلمة المرور غير صحيحة'}, status=400)


@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny])
def api_signup(request):
    raw_phone = request.data.get('phone_number')
    password = request.data.get('password')
    full_name = request.data.get('full_name') or ''
    email = (request.data.get('email') or '').strip()

    phone_number = normalize_libyan_phone(raw_phone)
    if not phone_number or not re.fullmatch(r'09\d{8}', phone_number):
        return Response({'error': 'رقم الهاتف غير صالح (الصيغة الصحيحة: 09XXXXXXXX)'}, status=400)

    if not password:
        return Response({'error': 'كلمة المرور مطلوبة'}, status=400)

    if User.objects.filter(phone_number=phone_number).exists():
        return Response({'error': 'رقم الهاتف مسجّل سابقاً'}, status=400)

    if not email:
        email = f"{phone_number}@auto.local"

    try:
        user = User.objects.create_user(
            phone_number=phone_number,
            password=password,
            full_name=full_name or phone_number,
            email=email
        )
        # إنشاء محفظة تلقائياً (Signals should handle this, but for safety)
        if not hasattr(user, 'wallet'):
             Wallet.objects.create(user=user)

        token, _ = Token.objects.get_or_create(user=user)
        return Response({
            'token': token.key,
            'user': {'phone_number': user.phone_number, 'full_name': user.full_name, 'email': user.email}
        }, status=201)
    except Exception as e:
        return Response({'error': str(e)}, status=400)


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
    
    # منطق افتراضي: إذا لم يحدد مقهى، نرجع الأول
    if not cafe_id:
        first_cafe = Cafe.objects.filter(is_active=True).first()
        if first_cafe:
            cafe_id = first_cafe.id
        else:
            return Response([])

    products = Product.objects.select_related('cafe', 'category').filter(cafe_id=cafe_id).order_by('-created_at')

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
            # 1. قفل المحفظة لمنع التضارب
            try:
                wallet = Wallet.objects.select_for_update().get(user=user)
            except Wallet.DoesNotExist:
                return Response({'error': 'المحفظة غير موجودة'}, status=404)

            # 2. التحقق المبدئي من الرصيد
            if wallet.balance < total_price:
                return Response({'error': 'الرصيد غير كافٍ'}, status=400)

            # 3. التحقق من المنتجات والمقهى
            product_ids = [item.get('product_id') for item in items_data]
            products = Product.objects.filter(id__in=product_ids).select_related('cafe')
            cafes = {p.cafe_id for p in products}
            
            if not products or len(cafes) != 1:
                return Response({'error': 'كل عناصر السلة يجب أن تتبع نفس المقهى'}, status=400)
            target_cafe_id = cafes.pop()

            # 4. ✅ إنشاء المعاملة المالية (هنا يتم الخصم تلقائياً بواسطة مودل Transaction)
            Transaction.objects.create(
                wallet=wallet,
                amount=total_price,
                transaction_type='WITHDRAWAL',
                source='APP',
                description=f'طلب جديد'
            )

            # 5. إنشاء الطلب
            new_order = Order.objects.create(
                user=user,
                cafe_id=target_cafe_id,
                total_price=total_price,
                status='PENDING'
            )

            # 6. إضافة العناصر للطلب
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

        # إرسال إشعار (خارج الـ atomic block لتجنب التأخير)
        try:
            send_real_notification(user, "تم استلام طلبك", f"طلبك #{new_order.order_number} قيد المعالجة.")
        except:
            pass

        return Response({'message': 'تم إنشاء الطلب بنجاح', 'order_id': new_order.id}, status=201)   

    except Product.DoesNotExist:
        return Response({'error': 'منتج غير متوفر'}, status=400)
    except ValueError as e:
         return Response({'error': str(e)}, status=400) # لالتقاط أخطاء الرصيد من المودل
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
    if request.method == 'GET':
        return get_user_orders(request)
    return create_order(request)


# =========================================================
#  SECTION 2: DASHBOARD (WEB VIEWS)
# =========================================================

def custom_login(request):
    if request.user.is_authenticated:
        return redirect('core:dashboard')

    if request.method == 'POST':
        username = request.POST.get('username')
        password = request.POST.get('password')

        if username:
            username = username.replace('-', '').replace(' ', '')

        phone = normalize_libyan_phone(username)
        user_obj = User.objects.filter(phone_number=phone).first()
        # Fallback to checking email if phone fails
        if not user_obj:
             user_obj = User.objects.filter(email__iexact=username).first()

        email_for_auth = user_obj.email if user_obj else username

        user = authenticate(request, username=email_for_auth, password=password)

        if user:
            login(request, user)
            return redirect('core:dashboard')
        else:
            return render(request, 'login.html', {'error': 'بيانات الدخول غير صحيحة'})

    return render(request, 'login.html')


def custom_logout(request):
    logout(request)
    return redirect('core:login')


@login_required(login_url='core:login')
def dashboard(request):
    """
    لوحة التحكم الرئيسية: تعرض الإحصائيات + المنتجات المتاحة (لحل مشكلة اختفاء الصناديق)
    """
    cafe = get_cafe_for_user(request.user)
    
    products_count = 0
    orders_count = 0
    # ✅ قائمة المنتجات لعرضها في الصناديق
    products_list = [] 
    
    if cafe:
        products_count = Product.objects.filter(cafe=cafe).count()
        orders_count = Order.objects.filter(cafe=cafe).count()
        wallets_count = Wallet.objects.count()
        # جلب المنتجات للمقهى الحالي
        products_list = Product.objects.filter(cafe=cafe, is_available=True).order_by('-created_at')[:20]
    else:
        wallets_count = Wallet.objects.count()
        # إذا كان سوبر يوزر، قد يرغب برؤية منتجات عامة أو فارغة
        if request.user.is_superuser:
             products_list = Product.objects.filter(is_available=True).order_by('-created_at')[:20]

    context = {
        'total_products': products_count,
        'total_cafes': Cafe.objects.count() if request.user.is_superuser else (1 if cafe else 0),
        'total_wallets': wallets_count,
        'user': request.user,
        'cafe_name': cafe.name if cafe else "لوحة الإدارة العامة",
        'products': products_list, # ✅ تم تمرير المنتجات هنا ليراها ملف dashboard.html
    }
    return render(request, 'core/dashboard.html', context)


@login_required(login_url='core:login')
def products(request):
    cafe = get_cafe_for_user(request.user)
    
    if not cafe:
        return render(request, 'core/products.html', {
            'products': [], 'categories': [], 'cafe_name': "لا يوجد مقهى محدد"
        })

    categories = ensure_categories_for_cafe(cafe)
    products_qs = Product.objects.filter(cafe=cafe).order_by('-created_at')

    return render(request, 'core/products.html', {
        'products': products_qs,
        'categories': categories,
        'cafe_name': cafe.name,
    })


@login_required(login_url='core:login')
def orders(request):
    cafe = get_cafe_for_user(request.user)
    
    if not cafe:
         return render(request, 'core/orders.html', {'orders': [], 'new_orders': [], 'preparing_orders': [], 'ready_orders': []})

    all_orders = Order.objects.filter(cafe=cafe).order_by('-created_at')
    context = {
        'orders': all_orders,
        'new_orders': all_orders.filter(status='PENDING'),
        'preparing_orders': all_orders.filter(status='PREPARING'),
        'ready_orders': all_orders.filter(status='READY'),
    }
    return render(request, 'core/orders.html', context)


@login_required(login_url='core:login')
def customers(request):
    return render(request, 'core/customers.html')


@login_required(login_url='core:login')
def stock(request):
    return render(request, 'core/stock.html')


@login_required(login_url='core:login')
def reports(request):
    return render(request, 'core/reports.html')


@login_required(login_url='core:login')
def settings_page(request):
    return render(request, 'core/settings.html')


@login_required(login_url='core:login')
def wallet_list(request):
    wallets = Wallet.objects.all().select_related('user').order_by('-updated_at')
    return render(request, 'core/wallet.html', {'wallets': wallets})


@login_required(login_url='core:login')
def wallet_recharge(request):
    search_query = request.GET.get('q', '').strip()
    wallets = Wallet.objects.select_related('user').all().order_by('-updated_at')

    if search_query:
        wallets = wallets.filter(
            Q(user__full_name__icontains=search_query) |
            Q(user__email__icontains=search_query) |
            Q(user__phone_number__icontains=search_query) |
            Q(link_code__icontains=search_query)
        )

    context = {
        'wallets': wallets,
        'min_charge_amount': getattr(settings, 'MIN_CHARGE_AMOUNT', 1.0),
    }
    return render(request, 'core/wallet_recharge.html', context)


@login_required(login_url='core:login')
def wallet_history(request):
    return render(request, 'core/wallet_history.html')


# --- Actions ---

@login_required(login_url='core:login')
def add_product(request):
    my_cafe = get_cafe_for_user(request.user)
    if not my_cafe:
        messages.error(request, "لا يوجد مقهى لربط المنتج به.")
        return redirect('core:products')

    # Get Categories
    categories_qs = ensure_categories_for_cafe(my_cafe)

    if request.method == 'POST':
        form = ProductForm(request.POST, request.FILES)
        # Filter category dropdown
        form.fields['category'].queryset = categories_qs
        
        if form.is_valid():
            try:
                product = form.save(commit=False)
                product.cafe = my_cafe

                # Default Category Logic
                if not product.category:
                     product.category = categories_qs.first()

                # Smart Image Logic
                if not product.image:
                    product.image = get_smart_image_for_product(product.name)

                product.save()
                messages.success(request, f"✅ Product {product.name} added!")
                return redirect('core:products')
            except Exception as e:
                messages.error(request, f"Database Error: {e}")
        else:
             messages.error(request, "يرجى التحقق من البيانات المدخلة.")

    return redirect('core:products')


@login_required(login_url='core:login')
def edit_product(request, product_id):
    my_cafe = get_cafe_for_user(request.user)
    if not my_cafe:
        return redirect('core:products')

    product = get_object_or_404(Product, id=product_id, cafe=my_cafe)
    categories_qs = ensure_categories_for_cafe(my_cafe)

    if request.method == 'POST':
        form = ProductForm(request.POST, request.FILES, instance=product)
        form.fields['category'].queryset = categories_qs

        if form.is_valid():
            try:
                updated_product = form.save(commit=False)
                updated_product.cafe = my_cafe # Ensure ownership
                
                if not updated_product.image and not updated_product.image_url:
                       updated_product.image = get_smart_image_for_product(updated_product.name)
                      
                updated_product.save()
                messages.success(request, "✅ تم التعديل بنجاح")
                return redirect('core:products')
            except Exception as e:
                messages.error(request, f"Error: {e}")

    return redirect('core:products')


@login_required(login_url='core:login')
def delete_product(request, product_id):
    cafe = get_cafe_for_user(request.user)
    if cafe:
        Product.objects.filter(id=product_id, cafe=cafe).delete()
        messages.success(request, "تم حذف المنتج.")
    return redirect('core:products')


@login_required(login_url='core:login')
def add_user(request):
    return redirect('core:customers')


@login_required(login_url='core:login')
def delete_user(request, user_id):
    return redirect('core:customers')


@login_required(login_url='core:login')
def create_wallet(request):
    return redirect('core:wallet_recharge')


@login_required(login_url='core:login')
def charge_wallet(request):
    if request.method != 'POST':
        return redirect('core:wallet_recharge')

    wallet_id = request.POST.get('wallet_code') or request.POST.get('wallet_id')
    amount_raw = request.POST.get('amount', '0')

    try:
        amount = Decimal(amount_raw)
    except Exception:
        messages.error(request, "المبلغ غير صالح.")
        return redirect('core:wallet_recharge')

    min_amount = Decimal(str(getattr(settings, 'MIN_CHARGE_AMOUNT', 1.0)))
    wallet = get_object_or_404(Wallet.objects.select_related('user'), id=wallet_id)

    if amount < min_amount:
        messages.error(request, f"الحد الأدنى للشحن هو {min_amount} د.ل")
        return redirect('core:wallet_recharge')

    try:
        with transaction.atomic():
            # إنشاء معاملة إيداع (المودل سيقوم بزيادة الرصيد تلقائياً)
            Transaction.objects.create(
                wallet=wallet,
                amount=amount,
                transaction_type='DEPOSIT',
                source='SYSTEM',
                description=f"شحن من اللوحة بواسطة {request.user}"
            )
        messages.success(request, f"تم شحن محفظة {wallet.user.full_name} بمبلغ {amount} د.ل")        
    except Exception as e:
        messages.error(request, f"تعذر الشحن: {e}")

    return redirect('core:wallet_recharge')


@login_required(login_url='core:login')
def refund_wallet(request):
    if request.method != 'POST':
        return redirect('core:wallet_recharge')

    wallet_id = request.POST.get('wallet_code') or request.POST.get('wallet_id')
    amount_raw = request.POST.get('amount', '0')

    try:
        amount = Decimal(amount_raw)
    except Exception:
        messages.error(request, "المبلغ غير صالح.")
        return redirect('core:wallet_recharge')

    wallet = get_object_or_404(Wallet.objects.select_related('user'), id=wallet_id)

    if amount <= 0:
        messages.error(request, "يجب أن يكون المبلغ أكبر من صفر.")
        return redirect('core:wallet_recharge')

    try:
        with transaction.atomic():
            # إنشاء معاملة خصم (المودل سيقوم بالتحقق من الرصيد والخصم تلقائياً)
            Transaction.objects.create(
                wallet=wallet,
                amount=amount,
                transaction_type='WITHDRAWAL',
                source='SYSTEM',
                description=f"خصم من اللوحة بواسطة {request.user}"
            )
        messages.success(request, f"تم خصم {amount} د.ل من محفظة {wallet.user.full_name}")
    except ValueError as e:
         messages.error(request, str(e)) # لعرض رسالة "الرصيد لا يكفي"
    except Exception as e:
        messages.error(request, f"تعذر الخصم: {e}")

    return redirect('core:wallet_recharge')


@login_required(login_url='core:login')
def accept_order(request, order_id):
    cafe = get_cafe_for_user(request.user)
    if not cafe:
        return redirect('core:orders')
        
    order = get_object_or_404(Order, id=order_id, cafe=cafe)
    if order.status == 'PENDING':
        order.status = 'PREPARING'
        order.save(update_fields=['status'])
        # Notification handled by Signals now (or keep it here if preferred)
        # send_real_notification(order.user, "تم قبول طلبك", f"طلبك #{order.order_number} قيد التحضير.")
    
    return redirect('core:orders')


@login_required(login_url='core:login')
def ready_order(request, order_id):
    cafe = get_cafe_for_user(request.user)
    if not cafe:
        return redirect('core:orders')

    order = get_object_or_404(Order, id=order_id, cafe=cafe)
    if order.status == 'PREPARING':
        order.status = 'READY'
        order.save(update_fields=['status'])
    
    return redirect('core:orders')


@login_required(login_url='core:login')
def complete_order(request, order_id):
    cafe = get_cafe_for_user(request.user)
    if cafe:
        Order.objects.filter(id=order_id, cafe=cafe).update(status='COMPLETED')
    return redirect('core:orders')


def manifest(request):
    return JsonResponse({}, safe=False)