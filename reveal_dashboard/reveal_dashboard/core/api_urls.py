from django.urls import path
from . import api_views

urlpatterns = [
    # 1. رابط جلب المنتجات (للتطبيق)
    path('products/', api_views.get_products, name='api_products'),
    
    # 2. رابط إرسال طلب جديد (من التطبيق)
    path('orders/create/', api_views.create_order, name='api_create_order'),
]
