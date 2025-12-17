from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from decimal import Decimal
from .models import Product, Order, OrderItem, Cafe
from wallet.models import Wallet, Transaction
from .serializers import ProductSerializer, OrderSerializer, CafeSerializer, UserSerializer


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


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_profile(request):
    serializer = UserSerializer(request.user)
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_order(request):
    user = request.user
    total_price_raw = request.data.get('total_price')
    items_data = request.data.get('items')

    # 1. Validation
    if total_price_raw is None or not items_data:
        return Response({'error': 'O"USOU+OO¦ O§USOñ U.UŸO¦U.U,Oc'}, status=400)

    if len(items_data) == 0:
        return Response({'error': 'OU,O3U,Oc U?OOñO§Oc'}, status=400)

    try:
        total_price = Decimal(str(total_price_raw))
    except Exception:
        return Response({'error': 'Invalid total_price'}, status=400)

    try:
        # 2. Check Wallet
        wallet = Wallet.objects.get(user=user)
        if wallet.balance < total_price:
            return Response({'error': 'OñOæUSO_ O§USOñ UŸOU?!'}, status=400)

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
            cafe=target_cafe,  # Correctly assigned Cafe
            total_price=total_price,
            status='PENDING'
        )

        # 5. Create Order Items
        for item in items_data:
            product_id = item.get('product_id') 
            qty = item.get('quantity', item.get('qty', 1))
            
            # Optimization: could fetch all products at once, but loop is fine for small carts
            product = Product.objects.get(id=product_id)
            
            # Optional: Warning if product belongs to a different cafe?
            # For now, we allow it but the order goes to the "target_cafe".
            
            OrderItem.objects.create(
                order=new_order,
                product=product,
                quantity=qty,
                price=product.price
            )

        # 6. Deduct Balance
        Transaction.objects.create(
            wallet=wallet,
            amount=total_price,
            transaction_type='WITHDRAWAL',
            source='APP',
            description=f'OúU,O" #{new_order.order_number}'
        )

        return Response({'message': 'O¦U. OU+O\'OO­ OU,OúU,O" O"U+OªOO-', 'order_id': new_order.id}, status=201)

    except Wallet.DoesNotExist:
        return Response({'error': 'OU,U.O-U?O,Oc O§USOñ U.U^OªU^O_Oc'}, status=404)
    except Product.DoesNotExist:
        return Response({'error': 'OœO-O_ OU,U.U+O¦OªOO¦ O§USOñ U.U^OªU^O_'}, status=400)
    except Exception as e:
        print(f"Order Error: {e}")
        return Response({'error': str(e)}, status=500)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_user_orders(request):
    orders = Order.objects.filter(user=request.user).order_by('-created_at')
    serializer = OrderSerializer(orders, many=True)
    return Response(serializer.data)


@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def orders_endpoint(request):
    """
    Combined endpoint to list user orders (GET) or create a new order (POST).
    """
    if request.method == 'GET':
        return get_user_orders(request)
    return create_order(request)
