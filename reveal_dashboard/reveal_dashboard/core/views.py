from decimal import Decimal
import re

from django.conf import settings
from django.contrib import messages
from django.contrib.auth import authenticate, login, logout
from django.contrib.auth.decorators import login_required
from django.db import transaction
from django.db.models import Count, Q, Sum
from django.http import JsonResponse
from django.shortcuts import get_object_or_404, redirect, render
from django.urls import reverse
from django.utils import timezone
from django.views.decorators.csrf import csrf_exempt

from rest_framework.authtoken.models import Token
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response

from .api_views import invalidate_products_cache
from .forms import InventoryItemForm, ProductForm
from .models import Cafe, Category, InventoryItem, Order, OrderItem, Product, SystemSettings
from .serializers import CafeSerializer, OrderSerializer, ProductSerializer, UserSerializer
from .utils import normalize_libyan_phone, send_real_notification
from users.models import User
from wallet.models import Transaction, Wallet

DEFAULT_CATEGORY_NAMES = ['برغر', 'بيتزا', 'حلويات', 'مشروبات', 'قهوة']


def get_cafe_for_user(user):
    cafe = getattr(user, 'my_cafe', None)
    if cafe:
        return cafe
    if user.is_superuser:
        return Cafe.objects.first()
    if user.is_staff:
        active_cafes = Cafe.objects.filter(is_active=True)
        if active_cafes.count() == 1:
            return active_cafes.first()
    return None


def ensure_categories_for_cafe(cafe):
    existing_defaults = set(
        Category.objects.filter(name__in=DEFAULT_CATEGORY_NAMES).values_list('name', flat=True)
    )
    for name in DEFAULT_CATEGORY_NAMES:
        if name not in existing_defaults:
            Category.objects.get_or_create(name=name)
    return Category.objects.filter(
        Q(name__in=DEFAULT_CATEGORY_NAMES) | Q(products__cafe=cafe)
    ).distinct().order_by('name')


def get_system_settings():
    return SystemSettings.get_solo()


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
        return Response({'error': 'رقم الهاتف/البريد وكلمة المرور مطلوبة.'}, status=400)

    phone = normalize_libyan_phone(raw_identifier)
    user_obj = None
    if phone:
        user_obj = User.objects.filter(Q(phone_number=phone) | Q(secondary_phone_number=phone)).first()

    if not user_obj and '@' in str(raw_identifier):
        user_obj = User.objects.filter(email__iexact=str(raw_identifier).strip()).first()

    if not user_obj:
        return Response({'error': 'الحساب غير موجود.'}, status=400)

    user = authenticate(request, username=user_obj.email, password=password)
    if user:
        if fcm_token and hasattr(user, 'fcm_token'):
            user.fcm_token = fcm_token
            user.save(update_fields=['fcm_token'])

        token, _ = Token.objects.get_or_create(user=user)
        balance = user.wallet.balance if hasattr(user, 'wallet') else 0

        return Response({
            'token': token.key,
            'user': {
                'id': user.id,
                'phone_number': user.phone_number,
                'full_name': user.full_name,
                'email': user.email,
                'wallet_balance': balance,
            },
        })

    return Response({'error': 'بيانات الدخول غير صحيحة.'}, status=400)


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
        return Response({'error': 'رقم الهاتف غير صحيح (مثال: 09XXXXXXXX).'}, status=400)

    if not password:
        return Response({'error': 'كلمة المرور مطلوبة.'}, status=400)

    if User.objects.filter(phone_number=phone_number).exists():
        return Response({'error': 'رقم الهاتف مسجل مسبقاً.'}, status=400)

    if not email:
        email = f"{phone_number}@auto.local"

    try:
        user = User.objects.create_user(
            phone_number=phone_number,
            password=password,
            full_name=full_name or phone_number,
            email=email,
        )
        if not hasattr(user, 'wallet'):
            Wallet.objects.create(user=user)

        token, _ = Token.objects.get_or_create(user=user)
        return Response({
            'token': token.key,
            'user': {
                'phone_number': user.phone_number,
                'full_name': user.full_name,
                'email': user.email,
            },
        }, status=201)
    except Exception as exc:
        return Response({'error': str(exc)}, status=400)


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
    payment_method = 'WALLET'

    if total_price_raw is None or not items_data:
        return Response({'error': 'بيانات الطلب ناقصة.'}, status=400)

    if len(items_data) == 0:
        return Response({'error': 'لا توجد عناصر في الطلب.'}, status=400)

    try:
        total_price = Decimal(str(total_price_raw))
    except Exception:
        return Response({'error': 'قيمة الطلب غير صحيحة.'}, status=400)

    try:
        with transaction.atomic():
            product_ids = [item.get('product_id') for item in items_data]
            products = list(Product.objects.filter(id__in=product_ids).select_related('cafe'))

            if len(products) != len(set(product_ids)):
                return Response({'error': 'بعض المنتجات غير موجودة.'}, status=400)

            cafes = {product.cafe_id for product in products}
            if len(cafes) != 1:
                return Response({'error': 'لا يمكن طلب منتجات من أكثر من مقهى في نفس الطلب.'}, status=400)
            target_cafe_id = cafes.pop()

            if payment_method == 'WALLET':
                try:
                    wallet = Wallet.objects.select_for_update().get(user=user)
                except Wallet.DoesNotExist:
                    return Response({'error': 'المحفظة غير موجودة.'}, status=404)

                if wallet.balance < total_price:
                    return Response({'error': 'رصيد المحفظة غير كافٍ.'}, status=400)

                Transaction.objects.create(
                    wallet=wallet,
                    amount=total_price,
                    transaction_type='WITHDRAWAL',
                    source='APP',
                    description='خصم طلب',
                )

            new_order = Order.objects.create(
                user=user,
                cafe_id=target_cafe_id,
                total_price=total_price,
                status='PENDING',
                payment_method=payment_method,
            )

            for item in items_data:
                product_id = item.get('product_id')
                qty = item.get('quantity', item.get('qty', 1))
                product = next((p for p in products if str(p.id) == str(product_id)), None)

                if not product:
                    return Response({'error': 'منتج غير موجود.'}, status=400)

                options = item.get('options') or item.get('note') or ''
                OrderItem.objects.create(
                    order=new_order,
                    product=product,
                    quantity=qty,
                    price=product.price,
                    options=options,
                )

        try:
            send_real_notification(user, "تم استلام طلبك", f"طلبك #{new_order.order_number} قيد المراجعة.")
        except Exception:
            pass

        return Response({'message': 'تم إرسال الطلب بنجاح', 'order_id': new_order.id}, status=201)

    except Exception:
        return Response({'error': 'حدث خطأ أثناء إنشاء الطلب.'}, status=500)


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

    prefill_username = request.GET.get('phone') or request.GET.get('username') or ''

    if request.method == 'POST':
        username = request.POST.get('username')
        password = request.POST.get('password')

        if username:
            username = username.replace('-', '').replace(' ', '')

        phone = normalize_libyan_phone(username)
        user_obj = User.objects.filter(Q(phone_number=phone) | Q(secondary_phone_number=phone)).first()
        if not user_obj:
            user_obj = User.objects.filter(email__iexact=username).first()

        email_for_auth = user_obj.email if user_obj else username
        user = authenticate(request, username=email_for_auth, password=password)

        if user:
            login(request, user)
            return redirect('core:dashboard')
        return render(request, 'login.html', {
            'error': 'بيانات الدخول غير صحيحة.',
            'prefill_username': username or prefill_username,
        })

    return render(request, 'login.html', {'prefill_username': prefill_username})


def custom_logout(request):
    logout(request)
    next_url = request.GET.get('next')
    if next_url and next_url.startswith('/'):
        return redirect(next_url)
    return redirect('core:login')


def switch_cafe(request, cafe_id):
    logout(request)
    cafe = Cafe.objects.filter(id=cafe_id, owner__isnull=False).select_related('owner').first()
    if cafe and cafe.owner and cafe.owner.phone_number:
        return redirect(f"{reverse('core:login')}?phone={cafe.owner.phone_number}")
    return redirect('core:login')


@login_required(login_url='core:login')
def dashboard(request):
    cafe = get_cafe_for_user(request.user)
    products_count = 0
    orders_count = 0
    products_list = []

    if cafe:
        products_count = Product.objects.filter(cafe=cafe).count()
        orders_count = Order.objects.filter(cafe=cafe).count()
        wallets_count = Wallet.objects.count()
        products_list = Product.objects.filter(cafe=cafe, is_available=True).order_by('-created_at')[:20]
    else:
        wallets_count = Wallet.objects.count()
        if request.user.is_superuser:
            products_list = Product.objects.filter(is_available=True).order_by('-created_at')[:20]

    context = {
        'total_products': products_count,
        'orders_count': orders_count,
        'total_cafes': Cafe.objects.count() if request.user.is_superuser else (1 if cafe else 0),
        'total_wallets': wallets_count,
        'user': request.user,
        'cafe_name': cafe.name if cafe else "لا يوجد مقهى مرتبط",
        'products': products_list,
    }
    return render(request, 'core/dashboard.html', context)


@login_required(login_url='core:login')
def products(request):
    cafe = get_cafe_for_user(request.user)
    system_settings = get_system_settings()

    if not cafe:
        return render(request, 'core/products.html', {
            'products': [],
            'categories': [],
            'cafe_name': "لا يوجد مقهى مرتبط",
            'system_settings': system_settings,
        })

    categories = ensure_categories_for_cafe(cafe)
    products_qs = Product.objects.filter(cafe=cafe).order_by('-created_at')

    return render(request, 'core/products.html', {
        'products': products_qs,
        'categories': categories,
        'cafe_name': cafe.name,
        'system_settings': system_settings,
    })


@login_required(login_url='core:login')
def orders(request):
    cafe = get_cafe_for_user(request.user)
    system_settings = get_system_settings()

    if request.user.is_superuser:
        all_orders = Order.objects.all().order_by('-created_at')
    elif not cafe:
        return render(request, 'core/orders.html', {
            'orders': [],
            'new_orders': [],
            'accepted_orders': [],
            'preparing_orders': [],
            'ready_orders': [],
            'system_settings': system_settings,
        })
    else:
        all_orders = Order.objects.filter(cafe=cafe).order_by('-created_at')

    context = {
        'orders': all_orders,
        'new_orders': all_orders.filter(status='PENDING'),
        'accepted_orders': all_orders.filter(status='ACCEPTED'),
        'preparing_orders': all_orders.filter(status='PREPARING'),
        'ready_orders': all_orders.filter(status='READY'),
        'system_settings': system_settings,
    }
    return render(request, 'core/orders.html', context)


@login_required(login_url='core:login')
def customers(request):
    cafe = get_cafe_for_user(request.user)

    if cafe and not request.user.is_superuser:
        users_qs = User.objects.filter(orders__cafe=cafe).distinct()
        users_qs = users_qs.annotate(orders_count=Count('orders', filter=Q(orders__cafe=cafe)))
    else:
        users_qs = User.objects.all().annotate(orders_count=Count('orders'))

    users_qs = users_qs.order_by('-date_joined')
    users = []
    for user in users_qs:
        if user.is_superuser:
            role = 'super_admin'
        elif user.is_staff:
            role = 'manager'
        else:
            role = 'customer'
        users.append({
            'full_name': user.full_name,
            'email': user.email,
            'phone_number': user.phone_number,
            'role': role,
            'created_at': user.date_joined,
            'orders_count': getattr(user, 'orders_count', 0),
            'uid': user.id,
        })

    return render(request, 'core/customers.html', {
        'users': users,
        'cafe_name': cafe.name if cafe else None,
    })


@login_required(login_url='core:login')
def stock(request):
    cafe = get_cafe_for_user(request.user)
    if not cafe:
        messages.error(request, "لا يوجد مقهى مرتبط لهذا الحساب.")
        return redirect('core:dashboard')

    items = InventoryItem.objects.filter(cafe=cafe).order_by('name')
    form = InventoryItemForm()
    system_settings = get_system_settings()

    return render(request, 'core/stock.html', {
        'items': items,
        'form': form,
        'cafe_name': cafe.name,
        'system_settings': system_settings,
    })


@login_required(login_url='core:login')
def add_inventory_item(request):
    cafe = get_cafe_for_user(request.user)
    if not cafe:
        messages.error(request, "لا يوجد مقهى مرتبط لهذا الحساب.")
        return redirect('core:stock')

    if request.method == 'POST':
        form = InventoryItemForm(request.POST)
        if form.is_valid():
            item = form.save(commit=False)
            item.cafe = cafe
            item.save()
            messages.success(request, "تم إضافة الصنف للمخزون بنجاح.")
        else:
            messages.error(request, "تعذر إضافة الصنف. تأكد من البيانات.")
    return redirect('core:stock')


@login_required(login_url='core:login')
def edit_inventory_item(request, item_id):
    cafe = get_cafe_for_user(request.user)
    if not cafe:
        return redirect('core:stock')

    item = get_object_or_404(InventoryItem, id=item_id, cafe=cafe)
    if request.method == 'POST':
        form = InventoryItemForm(request.POST, instance=item)
        if form.is_valid():
            form.save()
            messages.success(request, "تم تحديث بيانات المخزون بنجاح.")
            return redirect('core:stock')
        messages.error(request, "تعذر تحديث البيانات. تأكد من الحقول.")

    return render(request, 'core/stock_edit.html', {
        'item': item,
        'form': InventoryItemForm(instance=item),
        'cafe_name': cafe.name,
    })


@login_required(login_url='core:login')
def delete_inventory_item(request, item_id):
    cafe = get_cafe_for_user(request.user)
    if cafe:
        InventoryItem.objects.filter(id=item_id, cafe=cafe).delete()
        messages.success(request, "تم حذف الصنف من المخزون.")
    return redirect('core:stock')


@login_required(login_url='core:login')
def reports(request):
    today = timezone.localdate()

    product_count = Product.objects.count()
    wallet_count = Wallet.objects.count()
    total_system_balance = Wallet.objects.aggregate(total=Sum('balance'))['total'] or 0

    deposits_today_qs = Transaction.objects.filter(transaction_type='DEPOSIT', created_at__date=today)
    total_deposits_today = deposits_today_qs.aggregate(total=Sum('amount'))['total'] or 0
    deposits_count_today = deposits_today_qs.count()

    refunds_today_qs = Transaction.objects.filter(transaction_type='WITHDRAWAL', created_at__date=today)
    total_refunds_today = refunds_today_qs.aggregate(total=Sum('amount'))['total'] or 0

    latest_qs = Transaction.objects.select_related('wallet', 'wallet__user').order_by('-created_at')[:10]
    balances = {}
    latest_transactions = []

    for trans in latest_qs:
        wallet_id = trans.wallet_id
        if wallet_id not in balances:
            balances[wallet_id] = trans.wallet.balance

        current_balance = balances[wallet_id]
        latest_transactions.append({
            'type': 'deposit' if trans.transaction_type == 'DEPOSIT' else 'refund',
            'amount': trans.amount,
            'wallet_owner': getattr(trans.wallet.user, 'full_name', str(trans.wallet.user)),
            'new_balance': current_balance,
            'timestamp': trans.created_at,
        })

        if trans.transaction_type == 'DEPOSIT':
            balances[wallet_id] = current_balance - trans.amount
        elif trans.transaction_type == 'WITHDRAWAL':
            balances[wallet_id] = current_balance + trans.amount

    context = {
        'product_count': product_count,
        'wallet_count': wallet_count,
        'total_system_balance': total_system_balance,
        'total_deposits_today': total_deposits_today,
        'deposits_count_today': deposits_count_today,
        'total_refunds_today': total_refunds_today,
        'latest_transactions': latest_transactions,
    }

    return render(request, 'core/reports.html', context)


@login_required(login_url='core:login')
def settings_page(request):
    system_settings = get_system_settings()

    if request.method == 'POST':
        system_name = (request.POST.get('system_name') or '').strip()
        welcome_message = (request.POST.get('welcome_message') or '').strip()
        currency_symbol = (request.POST.get('currency_symbol') or '').strip()
        allow_registration = bool(request.POST.get('allow_registration'))
        min_charge_raw = request.POST.get('min_charge_amount') or system_settings.min_charge_amount

        try:
            min_charge_amount = Decimal(str(min_charge_raw))
        except Exception:
            messages.error(request, "قيمة الحد الأدنى للشحن غير صحيحة.")
            return redirect('core:settings')

        if system_name:
            system_settings.system_name = system_name
        if welcome_message:
            system_settings.welcome_message = welcome_message
        if currency_symbol:
            system_settings.currency_symbol = currency_symbol

        system_settings.min_charge_amount = min_charge_amount
        system_settings.allow_registration = allow_registration
        system_settings.save()

        messages.success(request, "تم حفظ إعدادات النظام بنجاح.")
        return redirect('core:settings')

    return render(request, 'core/settings.html', {'settings': system_settings})


@login_required(login_url='core:login')
def wallet_list(request):
    wallets = Wallet.objects.all().select_related('user').order_by('-updated_at')
    return render(request, 'core/wallet.html', {'wallets': wallets})


@login_required(login_url='core:login')
def wallet_recharge(request):
    search_query = request.GET.get('q', '').strip()
    wallets = Wallet.objects.select_related('user').all().order_by('-updated_at')
    system_settings = get_system_settings()

    if search_query:
        wallets = wallets.filter(
            Q(user__full_name__icontains=search_query)
            | Q(user__email__icontains=search_query)
            | Q(user__phone_number__icontains=search_query)
            | Q(link_code__icontains=search_query)
        )

    return render(request, 'core/wallet_recharge.html', {
        'wallets': wallets,
        'min_charge_amount': system_settings.min_charge_amount,
        'system_settings': system_settings,
    })


@login_required(login_url='core:login')
def wallet_history(request):
    return render(request, 'core/wallet_history.html')


@login_required(login_url='core:login')
def add_product(request):
    my_cafe = get_cafe_for_user(request.user)
    if not my_cafe:
        messages.error(request, "لا يوجد مقهى مرتبط لهذا الحساب.")
        return redirect('core:products')

    categories_qs = ensure_categories_for_cafe(my_cafe)

    if request.method == 'POST':
        form = ProductForm(request.POST, request.FILES)
        form.fields['category'].queryset = categories_qs

        if form.is_valid():
            try:
                product = form.save(commit=False)
                product.cafe = my_cafe
                if not product.category:
                    product.category = categories_qs.first()
                product.save()
                invalidate_products_cache()
                messages.success(request, f"تم إضافة المنتج {product.name} بنجاح.")
                return redirect('core:products')
            except Exception as exc:
                messages.error(request, f"حدث خطأ أثناء الحفظ: {exc}")
        else:
            messages.error(request, "تعذر إضافة المنتج. تأكد من البيانات.")

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
                updated_product.cafe = my_cafe
                updated_product.save()
                invalidate_products_cache()
                messages.success(request, "تم تحديث بيانات المنتج بنجاح.")
                return redirect('core:products')
            except Exception as exc:
                messages.error(request, f"حدث خطأ أثناء التحديث: {exc}")
        else:
            messages.error(request, "تعذر تحديث المنتج. تأكد من البيانات.")

    form = ProductForm(instance=product)
    form.fields['category'].queryset = categories_qs
    return render(request, 'core/edit_product.html', {
        'form': form,
        'product': product,
        'categories': categories_qs,
        'cafe_name': my_cafe.name,
        'system_settings': get_system_settings(),
    })


@login_required(login_url='core:login')
def delete_product(request, product_id):
    cafe = get_cafe_for_user(request.user)
    if cafe:
        Product.objects.filter(id=product_id, cafe=cafe).delete()
        invalidate_products_cache()
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
        messages.error(request, "قيمة الشحن غير صحيحة.")
        return redirect('core:wallet_recharge')

    min_amount = Decimal(str(get_system_settings().min_charge_amount))
    wallet = get_object_or_404(Wallet.objects.select_related('user'), id=wallet_id)

    if amount < min_amount:
        messages.error(request, f"الحد الأدنى للشحن هو {min_amount}.")
        return redirect('core:wallet_recharge')

    try:
        with transaction.atomic():
            Transaction.objects.create(
                wallet=wallet,
                amount=amount,
                transaction_type='DEPOSIT',
                source='SYSTEM',
                description=f"شحن من لوحة التحكم بواسطة {request.user}",
            )
        messages.success(request, f"تم شحن محفظة {wallet.user.full_name} بمبلغ {amount}.")
    except Exception as exc:
        messages.error(request, f"تعذر الشحن: {exc}")

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
        messages.error(request, "قيمة الخصم غير صحيحة.")
        return redirect('core:wallet_recharge')

    wallet = get_object_or_404(Wallet.objects.select_related('user'), id=wallet_id)

    if amount <= 0:
        messages.error(request, "قيمة الخصم يجب أن تكون أكبر من صفر.")
        return redirect('core:wallet_recharge')

    try:
        with transaction.atomic():
            Transaction.objects.create(
                wallet=wallet,
                amount=amount,
                transaction_type='WITHDRAWAL',
                source='SYSTEM',
                description=f"خصم من لوحة التحكم بواسطة {request.user}",
            )
        messages.success(request, f"تم خصم {amount} من محفظة {wallet.user.full_name}.")
    except Exception as exc:
        messages.error(request, f"تعذر الخصم: {exc}")

    return redirect('core:wallet_recharge')


@login_required(login_url='core:login')
def accept_order(request, order_id):
    cafe = get_cafe_for_user(request.user)
    if not cafe:
        return redirect('core:orders')

    order = get_object_or_404(Order, id=order_id, cafe=cafe)
    if order.status == 'PENDING':
        order.status = 'ACCEPTED'
        order.save(update_fields=['status'])
    return redirect('core:orders')


@login_required(login_url='core:login')
def preparing_order(request, order_id):
    cafe = get_cafe_for_user(request.user)
    if not cafe:
        return redirect('core:orders')

    order = get_object_or_404(Order, id=order_id, cafe=cafe)
    if order.status == 'ACCEPTED':
        order.status = 'PREPARING'
        order.save(update_fields=['status'])
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
