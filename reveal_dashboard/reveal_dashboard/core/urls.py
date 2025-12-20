from django.urls import path
from . import views

app_name = 'core'

urlpatterns = [
    # --- الصفحات الرئيسية (Authentication & Dashboard) ---
    path('', views.custom_login, name='login'),
    path('logout/', views.custom_logout, name='logout'),
    path('dashboard/', views.dashboard, name='dashboard'),

    # --- إدارة المنتجات والمخزون ---
    path('products/', views.products, name='products'),
    path('products/add/', views.add_product, name='add_product'),
    path('products/edit/<int:product_id>/', views.edit_product, name='edit_product'),
    path('products/delete/<int:product_id>/', views.delete_product, name='delete_product'),
    path('stock/', views.stock, name='stock'),

    # --- إدارة الطلبات ---
    path('orders/', views.orders, name='orders'),
    path('orders/accept/<int:order_id>/', views.accept_order, name='accept_order'),
    path('orders/ready/<int:order_id>/', views.ready_order, name='ready_order'),
    path('orders/complete/<int:order_id>/', views.complete_order, name='complete_order'),

    # --- إدارة العملاء ---
    path('customers/', views.customers, name='customers'),
    path('customers/add/', views.add_user, name='add_user'),
    path('customers/delete/<int:user_id>/', views.delete_user, name='delete_user'),

    # --- إدارة المحفظة (من لوحة التحكم) ---
    path('wallet/', views.wallet_list, name='wallets'),
    path('wallet/list/', views.wallet_list, name='wallet_list'),
    path('wallet/recharge/', views.wallet_recharge, name='wallet_recharge'),
    path('wallet/history/', views.wallet_history, name='wallet_history'),
    path('wallet/create/', views.create_wallet, name='create_wallet'),
    path('wallet/charge/', views.charge_wallet, name='charge_wallet'),
    path('wallet/refund/', views.refund_wallet, name='refund_wallet'),

    # --- تقارير وإعدادات ---
    path('reports/', views.reports, name='reports'),
    path('settings/', views.settings_page, name='settings'),
    
    # --- ملفات النظام ---
    path('manifest.json', views.manifest, name='manifest'),
]