from rest_framework import serializers  
from .models import Cafe, Product, Order, OrderItem, Category
from wallet.models import Wallet, Transaction
from users.models import User


def _build_image_url(image_value, request=None):
    """
    Normalize stored image paths into absolute URLs when a request is available.
    """
    if not image_value:
        return None

    image_str = str(image_value)
    if image_str.startswith('http'):
        return image_str

    if request:
        if not image_str.startswith('/'):
            image_str = f'/{image_str}'
        return request.build_absolute_uri(image_str)

    return image_str


# --- 1. U.O¦OñOªU. OU,U.O3O¦OrO_U. (User) ---
class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'email', 'full_name', 'phone_number']


# --- 2. U.O¦OñOªU. OU,U.O-U?O,Oc (Wallet) - UØOU. OªO_OU< ---
class WalletSerializer(serializers.ModelSerializer):
    currency = serializers.SerializerMethodField()

    class Meta:
        model = Wallet
        # U+OñO3U, OU,O-U,U^U, OU,U.UØU.Oc U,U,O¦OúO"USU, O"U.O U?USUØO UŸU^O_ OU,OñO"Oú U^OU,OñOæUSO_
        fields = ['id', 'balance', 'currency', 'link_code', 'college', 'updated_at']

    def get_currency(self, obj):
        # ?? OU,O?O1U^O_ O1U.U,USOc O"OU, OU,OªO_USO_ U?US Wallet
        return 'LYD'


# --- 3. U.O¦OñOªU. O3OªU, OU,O1U.U,USOO¦ (Transactions) ---
class TransactionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Transaction
        fields = ['id', 'amount', 'transaction_type', 'source', 'description', 'created_at']


# --- 4. U.O¦OñOªU.OO¦ OU,U.U+O,U^U.Oc (Cafe, Category, Product) ---
class CafeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Cafe
        fields = ['id', 'name', 'image', 'is_active']


class CategorySerializer(serializers.ModelSerializer):
    class Meta:
        model = Category
        fields = ['id', 'name', 'image']


class ProductSerializer(serializers.ModelSerializer):
    # O-U,U^U, OOOU?USOc U,U,U,OñOO­Oc U?U,Oú (U,U,O¦U^OUSO- U?US OU,O¦OúO"USU,)
    cafe_name = serializers.CharField(source='cafe.name', read_only=True)
    category_name = serializers.CharField(source='category.name', read_only=True)
    college = serializers.IntegerField(source='cafe.id', read_only=True)
    college_name = serializers.CharField(source='cafe.name', read_only=True)
    image_url = serializers.SerializerMethodField()

    class Meta:
        model = Product
        fields = [
            'id', 'name', 'price', 'image', 'image_url', 'description',
            'category', 'category_name',
            'cafe', 'cafe_name', 'college', 'college_name',
            'is_available'
        ]

    def get_image_url(self, obj):
        # O¦O1O_USU, U.U+ O"U,OO" O¦OñO1OñU?Oñ OU,O'O"O1 OªO_USO_ OU,OæU^OñOc
        request = self.context.get('request')
        return _build_image_url(getattr(obj, 'image', None), request)


# --- 5. U.O¦OñOªU.OO¦ OU,OúU,O"OO¦ (Orders) ---
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
        return _build_image_url(getattr(obj.product, 'image', None), request)


class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True)
    cafe_name = serializers.ReadOnlyField(source='cafe.name')

    class Meta:
        model = Order
        fields = ['id', 'order_number', 'total_price', 'status', 'created_at', 'cafe_name', 'items']

    def create(self, validated_data):
        items_data = validated_data.pop('items')
        user = self.context['request'].user

        # OOrO¦USOOñ UŸOU?USO¦USOñUSO OU?O¦OñOOUSOc OOøO U,U. O¦O-O_O_ (OœU^ USU.UŸU+ O¦U.OñUSOñUØO U.U+ OU,O¦OúO"USU,)
        # UØU+O U+OœOrOø OœU^U, UŸOU?USO¦USOñUSO UŸOOªOñOO­ OO-O¦OñOOýUS U?U,Oú
        from .models import Cafe
        cafe = Cafe.objects.first()

        order = Order.objects.create(user=user, cafe=cafe, **validated_data)

        for item_data in items_data:
            OrderItem.objects.create(order=order, **item_data)

        return order
