from rest_framework import serializers
from .models import Cafe, Product, Order, OrderItem, Category
from users.models import User

# --- دالة مساعدة لبناء روابط الصور ---
def _build_image_url(image_value, request=None):
    """
    تقوم بتحويل مسار الصورة المخزن إلى رابط كامل (Absolute URL).
    """
    if not image_value:
        return None

    image_str = str(image_value)
    if image_str.startswith('http'):
        return image_str

    if request:
        return request.build_absolute_uri(image_value.url if hasattr(image_value, 'url') else image_str)

    return f"/media/{image_str}" if not image_str.startswith('/media/') else image_str


# --- 1. تسلسل المستخدم (User Serializer) ---
# نبقيه هنا لأننا نحتاجه لعرض البروفايل في تطبيق Core
class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'email', 'full_name', 'phone_number']


# ❌ تم حذف WalletSerializer و TransactionSerializer من هنا
# ✅ مكانهما الصحيح الآن هو: wallet/serializers.py


# --- 2. تسلسل البيانات الأساسية (Cafe, Category, Product) ---
class CafeSerializer(serializers.ModelSerializer):
    image = serializers.SerializerMethodField()
    
    class Meta:
        model = Cafe
        fields = ['id', 'name', 'image', 'location', 'is_active']
        
    def get_image(self, obj):
        request = self.context.get('request')
        return _build_image_url(obj.image, request)


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'name']


class ProductSerializer(serializers.ModelSerializer):
    cafe_name = serializers.CharField(source='cafe.name', read_only=True)
    category_name = serializers.CharField(source='category.name', read_only=True)
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = [
            'id', 'name', 'price', 'image_url', 'description',
            'rating', 'rating_count',
            'category', 'category_name',
            'cafe', 'cafe_name',
            'is_available'
        ]

    def get_image_url(self, obj):
        request = self.context.get('request')
        return _build_image_url(obj.image, request)


# --- 3. تسلسل الطلبات (Order Serializers) ---
class OrderItemSerializer(serializers.ModelSerializer):
    product_id = serializers.PrimaryKeyRelatedField(queryset=Product.objects.all(), source='product')
    product_name = serializers.ReadOnlyField(source='product.name')
    product_price = serializers.ReadOnlyField(source='product.price')
    product_image = serializers.SerializerMethodField()

    class Meta:
        model = OrderItem
        fields = ['product_id', 'product_name', 'product_price', 'product_image', 'quantity']

    def get_product_image(self, obj):
        request = self.context.get('request')
        return _build_image_url(obj.product.image, request)


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    cafe_name = serializers.ReadOnlyField(source='cafe.name')
    status_display = serializers.CharField(source='get_status_display', read_only=True)

    class Meta:
        model = Order
        fields = ['id', 'order_number', 'total_price', 'status', 'status_display', 'created_at', 'cafe_name', 'items']