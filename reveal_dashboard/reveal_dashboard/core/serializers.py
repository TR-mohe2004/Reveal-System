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
class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'email', 'full_name', 'phone_number']


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
        # أضفت icon هنا احتياطاً لو كان موجوداً في المودل، لو غير موجود احذفه من هنا
        fields = ['id', 'name', 'icon'] 


class ProductSerializer(serializers.ModelSerializer):
    # ✅ التعديل الحاسم: نستخدم السيريالايزر بدلاً من مجرد الاسم أو الرقم
    # هذا يجعل الناتج: category: {id: 1, name: "...", icon: "..."}
    category = CategorySerializer(read_only=True)
    
    # لاستقبال رقم الفئة عند الإضافة (Write only) - مهم لوحة التحكم
    category_id = serializers.PrimaryKeyRelatedField(
        queryset=Category.objects.all(), source='category', write_only=True
    )

    cafe_name = serializers.CharField(source='cafe.name', read_only=True)
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = [
            'id', 'name', 'price', 'image_url', 'description',
            'rating', 'rating_count',
            'category', 'category_id', # نرسل الكائن والرقم (للكتابة)
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