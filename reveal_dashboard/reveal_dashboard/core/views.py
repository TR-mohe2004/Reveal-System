from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import authenticate, login, logout, get_user_model
from django.contrib.auth.decorators import login_required
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from django.contrib import messages
from django.conf import settings
from django.db import transaction
from django.db.models import Q
from decimal import Decimal
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.authtoken.models import Token
from .models import Product, Cafe, Category, Order
from users.models import User
from wallet.models import Wallet, Transaction
from .forms import ProductForm
from .serializers import ProductSerializer, OrderSerializer, UserSerializer, WalletSerializer 

# --- API للموبايل (معدل ليقبل البيانات من التطبيق كما هي) ---

@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny])
def api_login(request):
    print(f" [Login Attempt] Data Received: {request.data}")
    
    # 1. نستقبل البيانات سواء أرسلها التطبيق باسم 'phone_number' أو 'email'
    raw_identifier = request.data.get('phone_number') or request.data.get('email')
    password = request.data.get('password')
    
    if not raw_identifier or not password:
        return Response({'error': 'الرجاء إدخال رقم الهاتف وكلمة المرور'}, status=400)

    # 2. تنظيف رقم الهاتف (حذف الشرطات - والمسافات) ليتطابق مع قاعدة البيانات
    # لأن التطبيق يرسل 091-5199569 ونحن نخزنه 0915199569
    clean_phone = raw_identifier.replace('-', '').replace(' ', '')
    
    print(f" Trying to auth with: {clean_phone}") # للتأكد في السجل

    # 3. محاولة الدخول
    user = authenticate(username=clean_phone, password=password)

    if user is not None:
        print(f" Login Success: {user.phone_number}")
        token, _ = Token.objects.get_or_create(user=user)
        return Response({
            'token': token.key, 
            'user': {'phone_number': user.phone_number, 'full_name': user.full_name, 'email': user.email}
        })
    else:
        print(" Invalid Credentials")
        return Response({'error': 'رقم الهاتف أو كلمة المرور غير صحيحة'}, status=400)


@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny])
def api_signup(request):
    print(f" [Signup Attempt] Data: {request.data}")
    
    # نستقبل البيانات بمرونة
    raw_identifier = request.data.get('phone_number') or request.data.get('email')
    password = request.data.get('password')
    full_name = request.data.get('full_name')
    
    # تنظيف الرقم قبل الحفظ
    if raw_identifier:
        phone_number = raw_identifier.replace('-', '').replace(' ', '')
    else:
        return Response({'error': 'رقم الهاتف مطلوب'}, status=400)

    # التحقق من التكرار
    if User.objects.filter(phone_number=phone_number).exists():
        return Response({'error': 'رقم الهاتف مسجل مسبقاً'}, status=400)
        
    try:
        user = User.objects.create_user(
            phone_number=phone_number,
            password=password, 
            full_name=full_name,
            email="" # نتركه فارغاً
        )
        token, _ = Token.objects.get_or_create(user=user)
        return Response({
            'token': token.key, 
            'user': {'phone_number': user.phone_number, 'full_name': user.full_name}
        }, status=201)
    except Exception as e:
        print(f" Signup Error: {e}")
        return Response({'error': str(e)}, status=400)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_products(request):
    products = Product.objects.select_related('cafe', 'category').order_by('-created_at')

    category_id = request.GET.get('category_id')
    category_name = request.GET.get('category') or request.GET.get('category_name')
    cafe_id = request.GET.get('cafe_id')
    college_id = request.GET.get('college_id')
    available_only = request.GET.get('available')

    if category_id:
        products = products.filter(category_id=category_id)
    elif category_name:
        products = products.filter(category__name__iexact=category_name)

    if cafe_id:
        products = products.filter(cafe_id=cafe_id)

    if college_id:
        # Allow filtering by the college value stored on the cafe owner's wallet
        products = products.filter(cafe__owner__wallet__college__icontains=college_id)

    if available_only and available_only.lower() in ['1', 'true', 'yes']:
        products = products.filter(is_available=True)

    serializer = ProductSerializer(products, many=True, context={'request': request})
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_wallet(request):
    wallet = None
    user = request.user if request.user.is_authenticated else None

    # Try Token auth manually if DRF auth didn't populate request.user
    if not user:
        auth_header = request.headers.get('Authorization', '')
        if auth_header.startswith('Token '):
            token_key = auth_header.split(' ', 1)[1]
            try:
                user = Token.objects.select_related('user').get(key=token_key).user
            except Token.DoesNotExist:
                user = None

    # Fallback to identifiers passed explicitly
    if not user:
        phone = request.GET.get('phone_number') or request.GET.get('phone')
        user_id = request.GET.get('user_id')

        if phone:
            cleaned = phone.replace('-', '').replace(' ', '')
            user = User.objects.filter(phone_number=cleaned).first()
        elif user_id:
            user = User.objects.filter(id=user_id).first()

    if user:
        wallet = Wallet.objects.filter(user=user).first()

    if not wallet:
        link_code = request.GET.get('link_code')
        if link_code:
            wallet = Wallet.objects.filter(link_code=link_code).first()

    if wallet:
        serializer = WalletSerializer(wallet, context={'request': request})
        return Response(serializer.data)

    return Response({'balance': 0.0, 'currency': 'LYD'}, status=404)

@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny]) 
def create_order(request):
    print(f" [New Order] Data: {request.data}")
    return Response({'message': 'تم استلام الطلب', 'order_id': 123}, status=201)


# --- صفحات المنظومة (لوحة الإدارة) ---
def custom_login(request):
    if request.user.is_authenticated:
        return redirect('core:dashboard')
    
    if request.method == 'POST':
        username = request.POST.get('username') 
        password = request.POST.get('password')
        
        # تنظيف الرقم هنا أيضاً للاحتياط
        if username:
            username = username.replace('-', '').replace(' ', '')

        user = authenticate(request, username=username, password=password) 

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
    context = {
        'total_products': Product.objects.count(),
        'total_cafes': Cafe.objects.count(),
        'total_wallets': Wallet.objects.count(),
        'user': request.user
    }
    return render(request, 'core/dashboard.html', context)

@login_required(login_url='core:login')
def products(request):
    products = Product.objects.all()
    categories = Category.objects.all()
    return render(request, 'core/products.html', {'products': products, 'categories': categories})

@login_required(login_url='core:login')
def orders(request):
    all_orders = Order.objects.all().order_by('-created_at')
    context = {
        'orders': all_orders,
        'new_orders': all_orders.filter(status='PENDING'),
        'preparing_orders': all_orders.filter(status='PREPARING'),
        'ready_orders': all_orders.filter(status='READY'),
    }
    return render(request, 'core/orders.html', context)

@login_required(login_url='core:login')
def customers(request): return render(request, 'core/customers.html')
@login_required(login_url='core:login')
def stock(request): return render(request, 'core/stock.html')
@login_required(login_url='core:login')
def reports(request): return render(request, 'core/reports.html')
@login_required(login_url='core:login')
def settings_page(request): return render(request, 'core/settings.html')
@login_required(login_url='core:login')
def wallet_list(request):
    wallets = Wallet.objects.all()
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
def wallet_history(request): return render(request, 'core/wallet_history.html')

# Actions
@login_required(login_url='core:login')
def add_product(request):
    if request.method == 'POST':
        form = ProductForm(request.POST)
        if form.is_valid():
            p = form.save(commit=False)
            cafe = Cafe.objects.first()
            if cafe:
                p.cafe = cafe
                p.save()
            else:
                pass 
    return redirect('core:products')

@login_required(login_url='core:login')
def edit_product(request, product_id): return redirect('core:products')
@login_required(login_url='core:login')
def delete_product(request, product_id):
    Product.objects.filter(id=product_id).delete()
    return redirect('core:products')
@login_required(login_url='core:login')
def add_user(request): return redirect('core:customers')
@login_required(login_url='core:login')
def delete_user(request, user_id): return redirect('core:customers')
@login_required(login_url='core:login')
def create_wallet(request): return redirect('core:wallet_recharge')
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

    if wallet.balance < amount:
        messages.error(request, "الرصيد غير كافٍ لتنفيذ الخصم.")
        return redirect('core:wallet_recharge')

    try:
        with transaction.atomic():
            Transaction.objects.create(
                wallet=wallet,
                amount=amount,
                transaction_type='WITHDRAWAL',
                source='SYSTEM',
                description=f"خصم من اللوحة بواسطة {request.user}"
            )
        messages.success(request, f"تم خصم {amount} د.ل من محفظة {wallet.user.full_name}")
    except Exception as e:
        messages.error(request, f"تعذر الخصم: {e}")

    return redirect('core:wallet_recharge')
@login_required(login_url='core:login')
def accept_order(request, order_id):
    Order.objects.filter(id=order_id).update(status='PREPARING')
    return redirect('core:orders')
@login_required(login_url='core:login')
def ready_order(request, order_id):
    Order.objects.filter(id=order_id).update(status='READY')
    return redirect('core:orders')
@login_required(login_url='core:login')
def complete_order(request, order_id):
    Order.objects.filter(id=order_id).update(status='COMPLETED')
    return redirect('core:orders')
def manifest(request): return JsonResponse({}, safe=False)      
