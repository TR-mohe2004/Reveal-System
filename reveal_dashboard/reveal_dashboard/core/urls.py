from django.urls import path
from . import views

app_name = 'core'

urlpatterns = [
    # ==========================================
    # 1. روابط API للموبايل (تم التصحيح هنا) 📱
    # ==========================================
    
    # تسجيل الدخول (تم إزالة /auth/ لتطابق طلب التطبيق)
    path('api/login', views.api_login, name='api_login_raw'),
    path('api/login/', views.api_login, name='api_login'),

    # إنشاء حساب
    path('api/signup', views.api_signup, name='api_signup_raw'),
    path('api/signup/', views.api_signup, name='api_signup'),

    # جلب المنتجات
    path('api/products', views.get_products, name='api_products_raw'),
    path('api/products/', views.get_products, name='api_products'),

    # جلب المحفظة
    path('api/wallet', views.get_wallet, name='api_wallet_raw'),
    path('api/wallet/', views.get_wallet, name='api_wallet'),

    # إنشاء طلب
    path('api/orders', views.create_order, name='api_create_order_raw'),
    path('api/orders/', views.create_order, name='api_create_order'),
    # إبقاء المسار القديم احتياطاً
    path('api/orders/create/', views.create_order, name='api_create_order_old'),

    # ==========================================
    # 2. روابط لوحة التحكم (Dashboard) 💻
    # ==========================================

    # المصادقة (للويب)
    path('', views.custom_login, name='login'),
    path('logout/', views.custom_logout, name='logout'),
    path('dashboard/', views.dashboard, name='dashboard'),
    
    # الصفحات الرئيسية
    path('products/', views.products, name='products'),
    path('orders/', views.orders, name='orders'),
    path('customers/', views.customers, name='customers'),
    path('stock/', views.stock, name='stock'),
    path('reports/', views.reports, name='reports'),
    path('settings/', views.settings_page, name='settings'),
    
    # المحفظة (إدارة الويب)
    path('wallet/', views.wallet_list, name='wallets'), # لعرض القائمة
    path('wallet/list/', views.wallet_list, name='wallet_list'), # اسم بديل
    path('wallet/recharge/', views.wallet_recharge, name='wallet_recharge'),
    path('wallet/history/', views.wallet_history, name='wallet_history'),
    
    # روابط الأزرار (Actions)
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
    
    # ملف Manifest (للتطبيقات التقدمية PWA إن وجدت)
    path('manifest.json', views.manifest, name='manifest'),
]