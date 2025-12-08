from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework import status
from .models import Product, Order
from .serializers import ProductSerializer, OrderSerializer
from wallet.models import Wallet, Transaction

@api_view(['GET'])
@permission_classes([AllowAny])
def get_products(request):
    products = Product.objects.filter(is_available=True).order_by('-created_at')
    # تمرير الـ context هو السر للحصول على رابط الصورة كاملاً
    serializer = ProductSerializer(products, many=True, context={'request': request})
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_order(request):
    user = request.user
    total_price = request.data.get('total_price')

    try:
        wallet = Wallet.objects.get(user=user)
        if wallet.balance < float(total_price):
            return Response({'error': 'رصيد المحفظة غير كافي'}, status=400)
    except Wallet.DoesNotExist:
        return Response({'error': 'لا توجد محفظة'}, status=400)

    serializer = OrderSerializer(data=request.data, context={'request': request})
    if serializer.is_valid():
        order = serializer.save()
        Transaction.objects.create(
            wallet=wallet,
            amount=total_price,
            transaction_type='WITHDRAWAL',
            source='APP',
            description=f'دفع قيمة الطلب #{order.id}'
        )
        return Response({'message': 'تم الطلب بنجاح', 'order_id': order.id}, status=201)
    
    return Response(serializer.errors, status=400)
