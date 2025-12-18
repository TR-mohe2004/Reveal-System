from django.urls import path
from . import views, api_views
from wallet import api_views as wallet_api_views

app_name = 'core'

urlpatterns = [
    # --- API للتطبيق ---
    path('api/login', views.api_login, name='api_login_raw'),
    path('api/login/', views.api_login, name='api_login'),
    path('api/signup', views.api_signup, name='api_signup_raw'),
    path('api/signup/', views.api_signup, name='api_signup'),

    path('api/user', api_views.get_user_profile, name='api_user_profile_raw'),
    path('api/user/', api_views.get_user_profile, name='api_user_profile'),

    path('api/cafes/list', api_views.get_cafes_list, name='api_cafes_list_raw'),
    path('api/cafes/list/', api_views.get_cafes_list, name='api_cafes_list'),
    path('api/cafes', api_views.get_cafes_list, name='api_cafes_raw'),
    path('api/cafes/', api_views.get_cafes_list, name='api_cafes'),

    path('api/products', api_views.get_products, name='api_products_raw'),
    path('api/products/', api_views.get_products, name='api_products'),
    path('api/purchase', api_views.api_purchase, name='api_purchase_raw'),
    path('api/purchase/', api_views.api_purchase, name='api_purchase'),

    path('api/wallet', wallet_api_views.get_wallet, name='api_wallet_raw'),
    path('api/wallet/', wallet_api_views.get_wallet, name='api_wallet'),
    path('api/wallet/link', wallet_api_views.link_wallet, name='api_wallet_link_raw'),
    path('api/wallet/link/', wallet_api_views.link_wallet, name='api_wallet_link'),
    path('api/wallet/topup', wallet_api_views.topup_wallet, name='api_wallet_topup_raw'),
    path('api/wallet/topup/', wallet_api_views.topup_wallet, name='api_wallet_topup'),

    path('api/orders', api_views.orders_endpoint, name='api_orders_raw'),
    path('api/orders/', api_views.orders_endpoint, name='api_orders'),
    path('api/orders/create/', api_views.create_order, name='api_create_order_old'),

    # --- لوحة التحكم ---
    path('', views.custom_login, name='login'),
    path('logout/', views.custom_logout, name='logout'),
    path('dashboard/', views.dashboard, name='dashboard'),

    path('products/', views.products, name='products'),
    path('orders/', views.orders, name='orders'),
    path('customers/', views.customers, name='customers'),
    path('stock/', views.stock, name='stock'),
    path('reports/', views.reports, name='reports'),
    path('settings/', views.settings_page, name='settings'),

    path('wallet/', views.wallet_list, name='wallets'),
    path('wallet/list/', views.wallet_list, name='wallet_list'),
    path('wallet/recharge/', views.wallet_recharge, name='wallet_recharge'),
    path('wallet/history/', views.wallet_history, name='wallet_history'),
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

    path('manifest.json', views.manifest, name='manifest'),
]
