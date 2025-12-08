from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from .models import Product, Cafe, Category, Order
from users.models import User
from wallet.models import Wallet, Transaction
from .forms import ProductForm
from .serializers import ProductSerializer, OrderSerializer, UserSerializer

# --- API للموبايل (محدث ومصحح) ---

@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny])
def api_login(request):
    # طباعة البيانات الواصلة للتشخيص
    print(f" [Login Attempt] Data Received: {request.data}")
    
    email = request.data.get('email')
    password = request.data.get('password')
    
    if not email or not password:
        print(" Missing email or password")
        return Response({'error': 'الرجاء إدخال البريد وكلمة المرور'}, status=400)

    user = authenticate(email=email, password=password)
    if user is not None:
        print(f" Login Success: {user.email}")
        return Response({
            'token': 'demo-token-123', 
            'user': {'email': user.email, 'full_name': user.full_name}
        })
    else:
        print(" Invalid Credentials")
        return Response({'error': 'بيانات الدخول غير صحيحة'}, status=400)

@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny])
def api_signup(request):
    print(f" [Signup Attempt] Data: {request.data}")
    
    email = request.data.get('email')
    password = request.data.get('password')
    full_name = request.data.get('full_name')
    phone_number = request.data.get('phone_number', '0000000000')
    
    if User.objects.filter(email=email).exists():
        return Response({'error': 'البريد الإلكتروني مسجل مسبقاً'}, status=400)
        
    try:
        user = User.objects.create_user(
            email=email, 
            password=password, 
            full_name=full_name, 
            phone_number=phone_number
        )
        return Response({
            'token': 'demo-token-123', 
            'user': {'email': user.email, 'full_name': user.full_name}
        }, status=201)
    except Exception as e:
        print(f" Signup Error: {e}")
        return Response({'error': str(e)}, status=400)

@api_view(['GET'])
@permission_classes([AllowAny])
def get_products(request):
    products = Product.objects.all().order_by('-created_at')
    serializer = ProductSerializer(products, many=True, context={'request': request})
    return Response(serializer.data)

@api_view(['GET'])
@permission_classes([AllowAny]) # جعلناها عامة للتجربة
def get_wallet(request):
    # محاولة جلب محفظة للتجربة
    wallet = Wallet.objects.first()
    if wallet:
        return Response({
            'id': wallet.id,
            'balance': wallet.balance,
            'updated_at': wallet.updated_at
        })
    return Response({'balance': 0.0})

@csrf_exempt
@api_view(['POST'])
@permission_classes([AllowAny]) 
def create_order(request):
    print(f" [New Order] Data: {request.data}")
    return Response({'message': 'تم استلام الطلب', 'order_id': 123}, status=201)


# --- صفحات المنظومة (كما هي) ---
def custom_login(request):
    if request.user.is_authenticated:
        return redirect('core:dashboard')
    if request.method == 'POST':
        email = request.POST.get('email')
        password = request.POST.get('password')
        user = authenticate(request, email=email, password=password)
        if user:
            login(request, user)
            return redirect('core:dashboard')
        return render(request, 'login.html', {'error': 'بيانات غير صحيحة'})
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
def wallet_recharge(request): return render(request, 'core/wallet_recharge.html')
@login_required(login_url='core:login')
def wallet_history(request): return render(request, 'core/wallet_history.html')

# Actions
@login_required(login_url='core:login')
def add_product(request):
    if request.method == 'POST':
        form = ProductForm(request.POST)
        if form.is_valid():
            p = form.save(commit=False)
            p.cafe = Cafe.objects.first()
            p.save()
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
def charge_wallet(request): return redirect('core:wallet_recharge')
@login_required(login_url='core:login')
def refund_wallet(request): return redirect('core:wallet_recharge')
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
