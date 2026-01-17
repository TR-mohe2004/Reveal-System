from rest_framework import serializers
from .models import Cafe, Product, Order, OrderItem, Category
from users.models import User


def _build_image_url(image_value, request=None):
    if not image_value:
        return None

    image_str = str(image_value)
    if image_str.startswith('http'):
        return image_str

    if request:
        return request.build_absolute_uri(image_value.url if hasattr(image_value, 'url') else image_str)

    return f"/media/{image_str}" if not image_str.startswith('/media/') else image_str


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            'id',
            'email',
            'full_name',
            'phone_number',
            'secondary_phone_number',
            'profile_image_url',
            'date_joined',
        ]


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
    category = CategorySerializer(read_only=True)
    cafe = CafeSerializer(read_only=True)
    category_name = serializers.CharField(source='category.name', read_only=True)
    cafe_name = serializers.CharField(source='cafe.name', read_only=True)
    category_id = serializers.IntegerField(read_only=True)
    cafe_id = serializers.IntegerField(read_only=True)
    image = serializers.SerializerMethodField()
    image_url = serializers.SerializerMethodField()
    image_variant = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = [
            'id', 'name', 'price', 'image', 'image_url', 'image_variant', 'description',
            'rating', 'rating_count',
            'category', 'category_name', 'category_id',
            'cafe', 'cafe_name', 'cafe_id',
            'is_available',
        ]

    def get_image(self, obj):
        request = self.context.get('request')
        return _build_image_url(obj.image, request)

    def get_image_url(self, obj):
        request = self.context.get('request')
        return _build_image_url(obj.image, request)

    def get_image_variant(self, obj):
        category_name = ''
        if getattr(obj, 'category', None) and obj.category:
            category_name = (obj.category.name or '')

        text = f"{category_name} {obj.name or ''}".lower()

        def has_any(values):
            return any(value in text for value in values)

        if has_any(['pizza', 'بيتزا']):
            count = 5
        elif has_any(['burger', 'برغر', 'برجر']):
            count = 5
        elif has_any(['dessert', 'sweet', 'حلويات', 'حلوى']):
            count = 5
        elif has_any(['coffee', 'قهوة']):
            count = 2
        elif has_any(['drink', 'drinks', 'juice', 'water', 'مشروب', 'مشروبات', 'عصير', 'ماء']):
            count = 5
        else:
            count = 5

        if not obj.id:
            return 0
        return int(obj.id) % count


class OrderItemSerializer(serializers.ModelSerializer):
    product_id = serializers.PrimaryKeyRelatedField(queryset=Product.objects.all(), source='product')
    product_name = serializers.ReadOnlyField(source='product.name')
    product_price = serializers.ReadOnlyField(source='product.price')
    price = serializers.ReadOnlyField()
    product_image = serializers.SerializerMethodField()

    class Meta:
        model = OrderItem
        fields = ['product_id', 'product_name', 'product_price', 'price', 'product_image', 'quantity', 'options']

    def get_product_image(self, obj):
        request = self.context.get('request')
        return _build_image_url(obj.product.image, request)


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True, read_only=True)
    cafe_name = serializers.ReadOnlyField(source='cafe.name')
    cafe_id = serializers.ReadOnlyField(source='cafe.id')
    status_display = serializers.CharField(source='get_status_display', read_only=True)
    payment_method_display = serializers.CharField(source='get_payment_method_display', read_only=True)

    class Meta:
        model = Order
        fields = [
            'id', 'order_number', 'total_price', 'status', 'status_display',
            'payment_method', 'payment_method_display', 'created_at',
            'cafe_name', 'cafe_id', 'items',
        ]
