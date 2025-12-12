from rest_framework import serializers
from .models import Cafe, Product, Order, OrderItem
# from users.serializers import UserSerializer 

class CafeSerializer(serializers.ModelSerializer):
    class Meta:
        model = Cafe
        fields = ['id', 'name', 'image']

class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = ['id', 'name', 'price', 'image', 'description', 'category']

class OrderItemSerializer(serializers.ModelSerializer):
    product_id = serializers.PrimaryKeyRelatedField(queryset=Product.objects.all(), source='product')
    product_name = serializers.ReadOnlyField(source='product.name') # Add product name
    
    class Meta:
        model = OrderItem
        fields = ['product_id', 'product_name', 'quantity']

class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True)

    class Meta:
        model = Order
        fields = ['id', 'order_number', 'total_price', 'status', 'created_at', 'items']

    def create(self, validated_data):
        items_data = validated_data.pop('items')
        user = self.context['request'].user
        
        # NOTE: This create method is mostly bypassed by the manual create_order view now, 
        # but kept for completeness or DRF browsable API.
        from .models import Cafe
        cafe = Cafe.objects.first() 
        
        order = Order.objects.create(user=user, cafe=cafe, **validated_data)
        
        for item_data in items_data:
            OrderItem.objects.create(order=order, **item_data)
            
        return order
