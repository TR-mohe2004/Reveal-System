from django.urls import path
from . import views

app_name = 'core'

urlpatterns = [
    # API
    path('api/login/', views.api_login, name='api_login'),
    path('api/signup/', views.api_signup, name='api_signup'),
    path('api/cafes/', views.get_cafes_list, name='api_cafes'),
    path('api/products/', views.get_products, name='api_products'),
    path('api/profile/', views.get_user_profile, name='api_profile'),
    path('api/orders/', views.orders_endpoint, name='api_orders'),

    # Dashboard
    path('', views.custom_login, name='login'),
    path('logout/', views.custom_logout, name='logout'),
    path('switch-cafe/<int:cafe_id>/', views.switch_cafe, name='switch_cafe'),
    path('dashboard/', views.dashboard, name='dashboard'),

    # Products
    path('products/', views.products, name='products'),
    path('products/add/', views.add_product, name='add_product'),
    path('products/edit/<int:product_id>/', views.edit_product, name='edit_product'),
    path('products/delete/<int:product_id>/', views.delete_product, name='delete_product'),

    # Stock
    path('stock/', views.stock, name='stock'),
    path('stock/add/', views.add_inventory_item, name='add_inventory_item'),
    path('stock/edit/<int:item_id>/', views.edit_inventory_item, name='edit_inventory_item'),
    path('stock/delete/<int:item_id>/', views.delete_inventory_item, name='delete_inventory_item'),

    # Orders
    path('orders/', views.orders, name='orders'),
    path('orders/accept/<int:order_id>/', views.accept_order, name='accept_order'),
    path('orders/preparing/<int:order_id>/', views.preparing_order, name='preparing_order'),
    path('orders/ready/<int:order_id>/', views.ready_order, name='ready_order'),
    path('orders/complete/<int:order_id>/', views.complete_order, name='complete_order'),

    # Customers
    path('customers/', views.customers, name='customers'),
    path('customers/add/', views.add_user, name='add_user'),
    path('customers/delete/<int:user_id>/', views.delete_user, name='delete_user'),

    # Wallet
    path('wallet/', views.wallet_list, name='wallets'),
    path('wallet/list/', views.wallet_list, name='wallet_list'),
    path('wallet/recharge/', views.wallet_recharge, name='wallet_recharge'),
    path('wallet/history/', views.wallet_history, name='wallet_history'),
    path('wallet/create/', views.create_wallet, name='create_wallet'),
    path('wallet/charge/', views.charge_wallet, name='charge_wallet'),
    path('wallet/refund/', views.refund_wallet, name='refund_wallet'),

    # Reports + Settings
    path('reports/', views.reports, name='reports'),
    path('settings/', views.settings_page, name='settings'),

    # Manifest
    path('manifest.json', views.manifest, name='manifest'),
]
