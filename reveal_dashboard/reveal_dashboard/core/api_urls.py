from django.urls import path, include
from . import api_views, views

# لا حاجة لتعريف app_name هنا لأننا سنضمنه ببادئة api/

urlpatterns = [
    # --- المصادقة (Auth) ---
    path('login/', views.api_login, name='api_login'),
    path('signup/', views.api_signup, name='api_signup'),

    # --- المستخدم (User) ---
    path('user/', api_views.get_user_profile, name='api_user_profile'),

    # --- البيانات الأساسية (Cafes & Products) ---
    path('cafes/', api_views.get_cafes_list, name='api_cafes'),
    path('products/', api_views.get_products, name='api_products'),

    # --- الطلبات (Orders) ---
    path('orders/', api_views.orders_endpoint, name='api_orders'),
    path('orders/create/', api_views.create_order, name='api_create_order'),

    # --- المحفظة (Wallet) ---
    path('wallet/', include('wallet.api_urls')),
]