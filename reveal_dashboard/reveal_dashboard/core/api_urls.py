from django.urls import path, include
from . import api_views

urlpatterns = [
    path('cafes/', api_views.get_cafes, name='api_get_cafes'),
    path('products/', api_views.get_products, name='api_products'),
    path('orders', api_views.orders_endpoint, name='api_orders'),
    path('orders/', api_views.orders_endpoint, name='api_orders_slash'),
    path('orders/create', api_views.create_order, name='api_create_order_raw'),
    path('orders/create/', api_views.create_order, name='api_create_order'),
    path('orders/list/', api_views.get_user_orders, name='api_user_orders'),
    path('user', api_views.get_user_profile, name='api_user_profile_raw'),
    path('user/', api_views.get_user_profile, name='api_user_profile'),
    path('wallet/', include('wallet.api_urls')),
]
