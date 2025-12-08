from rest_framework import serializers
from .models import Product, Order, OrderItem
#  استيراد UserSerializer من مكانه الصحيح 
from users.serializers import UserSerializer 

class ProductSerializer(serializers.ModelSerializer):
    class Meta:
        model = Product
        fields = ['id', 'name', 'price', 'image', 'description', 'category']

class OrderItemSerializer(serializers.ModelSerializer):
    product_id = serializers.PrimaryKeyRelatedField(queryset=Product.objects.all(), source='product')
    
    class Meta:
        model = OrderItem
        fields = ['product_id', 'quantity']

class OrderSerializer(serializers.ModelSerializer):
    items = OrderItemSerializer(many=True)

    class Meta:
        model = Order
        fields = ['total_price', 'items']

    def create(self, validated_data):
        items_data = validated_data.pop('items')
        user = self.context['request'].user
        # نفترض وجود مقهى افتراضي أو نحدده لاحقاً
        from .models import Cafe
        cafe = Cafe.objects.first() 
        
        order = Order.objects.create(user=user, cafe=cafe, **validated_data)
        
        for item_data in items_data:
            OrderItem.objects.create(order=order, **item_data)
            
        return order
