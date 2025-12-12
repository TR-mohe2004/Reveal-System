from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import Product, Order, OrderItem, Cafe
from wallet.models import Wallet, Transaction
from .serializers import ProductSerializer, OrderSerializer, CafeSerializer

@api_view(['GET'])
def get_cafes(request):
    cafes = Cafe.objects.all()
    serializer = CafeSerializer(cafes, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def get_products(request):
    college_id = request.GET.get('college_id')
    products = Product.objects.all().order_by('-created_at')
    
    if college_id:
        # Filter products by cafe owner's college 
        products = products.filter(cafe__owner__wallet__college__icontains=college_id)
        
    serializer = ProductSerializer(products, many=True, context={'request': request})
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_order(request):
    user = request.user
    total_price = request.data.get('total_price')
    items_data = request.data.get('items')

    # 1. Validation
    if not total_price or not items_data:
        return Response({'error': 'بيانات غير مكتملة'}, status=400)

    if len(items_data) == 0:
         return Response({'error': 'السلة فارغة'}, status=400)

    try:
        # 2. Check Wallet
        wallet = Wallet.objects.get(user=user)
        if wallet.balance < float(total_price):
            return Response({'error': 'رصيد غير كاف!'}, status=400)

        # 3. Determine Cafe from the first product
        # NOTE: Assumes all items in cart belong to the same cafe (or at least assigns order to the first item's cafe)
        first_item_id = items_data[0].get('product_id')
        first_product = Product.objects.get(id=first_item_id)
        target_cafe = first_product.cafe

        if not target_cafe:
             return Response({'error': 'Product is not associated with a Cafe'}, status=500)
        
        # 4. Create Order
        new_order = Order.objects.create(
            user=user,
            cafe=target_cafe, # Correctly assigned Cafe
            total_price=total_price,
            status='PENDING'
        )

        # 5. Create Order Items
        for item in items_data:
            product_id = item.get('product_id') 
            qty = item.get('qty', 1)
            
            # Optimization: could fetch all products at once, but loop is fine for small carts
            product = Product.objects.get(id=product_id)
            
            # Optional: Warning if product belongs to a different cafe?
            # For now, we allow it but the order goes to the "target_cafe".
            
            OrderItem.objects.create(order=new_order, product=product, quantity=qty)

        # 6. Deduct Balance
        Transaction.objects.create(
            wallet=wallet,
            amount=total_price,
            transaction_type='WITHDRAWAL',
            source='APP',
            description=f'طلب #{new_order.order_number}'
        )

        return Response({'message': 'تم إنشاء الطلب بنجاح', 'order_id': new_order.id}, status=201)

    except Wallet.DoesNotExist:
         return Response({'error': 'المحفظة غير موجودة'}, status=404)
    except Product.DoesNotExist:
        return Response({'error': 'أحد المنتجات غير موجود'}, status=400)
    except Exception as e:
        print(f"Order Error: {e}")
        return Response({'error': str(e)}, status=500)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_orders(request):
    orders = Order.objects.filter(user=request.user).order_by('-created_at')
    serializer = OrderSerializer(orders, many=True)
    return Response(serializer.data)
