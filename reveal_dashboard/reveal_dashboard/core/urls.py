from django.urls import path
from . import views, api_views
from wallet import api_views as wallet_api_views

app_name = 'core'

urlpatterns = [
    # ==========================================
    # 1. مسارات API (للتطبيق)
    # ==========================================
    
    # تسجيل الدخول
    path('api/login', views.api_login, name='api_login_raw'),
    path('api/login/', views.api_login, name='api_login'),

    # إنشاء حساب
    path('api/signup', views.api_signup, name='api_signup_raw'),
    path('api/signup/', views.api_signup, name='api_signup'),

    # الملف الشخصي
    path('api/user', api_views.get_user_profile, name='api_user_profile_raw'),
    path('api/user/', api_views.get_user_profile, name='api_user_profile'),

    # المقاهي / الجامعات
    path('api/cafes', api_views.get_cafes, name='api_cafes_raw'),
    path('api/cafes/', api_views.get_cafes, name='api_cafes'),

    # المنتجات
    path('api/products', api_views.get_products, name='api_products_raw'),
    path('api/products/', api_views.get_products, name='api_products'),

    # المحافظ
    path('api/wallet', wallet_api_views.get_wallet, name='api_wallet_raw'),
    path('api/wallet/', wallet_api_views.get_wallet, name='api_wallet'),
    path('api/wallet/link', wallet_api_views.link_wallet, name='api_wallet_link_raw'),
    path('api/wallet/link/', wallet_api_views.link_wallet, name='api_wallet_link'),

    # الطلبات
    path('api/orders', api_views.orders_endpoint, name='api_orders_raw'),
    path('api/orders/', api_views.orders_endpoint, name='api_orders'),
    path('api/orders/create', api_views.create_order, name='api_create_order'),
    path('api/orders/create/', api_views.create_order, name='api_create_order_old'),

    # ==========================================
    # 2. مسارات لوحة التحكم
    # ==========================================

    # الدخول/الخروج والصفحة الرئيسية
    path('', views.custom_login, name='login'),
    path('logout/', views.custom_logout, name='logout'),
    path('dashboard/', views.dashboard, name='dashboard'),
    
    # إدارة المحتوى
    path('products/', views.products, name='products'),
    path('orders/', views.orders, name='orders'),
    path('customers/', views.customers, name='customers'),
    path('stock/', views.stock, name='stock'),
    path('reports/', views.reports, name='reports'),
    path('settings/', views.settings_page, name='settings'),
    
    # المحافظ (لوحة التحكم)
    path('wallet/', views.wallet_list, name='wallets'),
    path('wallet/list/', views.wallet_list, name='wallet_list'),
    path('wallet/recharge/', views.wallet_recharge, name='wallet_recharge'),
    path('wallet/history/', views.wallet_history, name='wallet_history'),
    
    # إجراءات سريعة
    path('wallet/create/', views.create_wallet, name='create_wallet'),
    path('wallet/charge/', views.charge_wallet, name='charge_wallet'),
    path('wallet/refund/', views.refund_wallet, name='refund_wallet'),
    
    path('products/add/', views.add_product, name='add_product'),
    path('products/edit/<int:product_id>/', views.edit_product, name='edit_product'),
    path('products/delete/<int:product_id>/', views.delete_product, name='delete_product'),
    
    path('customers/add/', views.add_user, name='add_user'),
    path('customers/delete/<int:user_id>/', views.delete_user, name='delete_user'),
    
    path('orders/accept/<int:order_id>/', views.accept_order, name='accept_order'),
    path('orders/ready/<int:order_id>/', views.ready_order, name='ready_order'),
    path('orders/complete/<int:order_id>/', views.complete_order, name='complete_order'),
    
    # ملف Manifest (خاص بـ PWA إن وجد)
    path('manifest.json', views.manifest, name='manifest'),
]
