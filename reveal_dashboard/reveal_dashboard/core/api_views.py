from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated, AllowAny
from rest_framework.response import Response
from rest_framework import status
from django.shortcuts import get_object_or_404
from .models import Product, Order, OrderItem
from .serializers import ProductSerializer, OrderSerializer
from wallet.models import Wallet, Transaction

# --- المنتجات ---
@api_view(['GET'])
@permission_classes([AllowAny])
def get_products(request):
    products = Product.objects.all().order_by('-created_at')
    serializer = ProductSerializer(products, many=True, context={'request': request})
    return Response(serializer.data)

# --- المحفظة (تمت الإضافة) ---
@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_wallet(request):
    user = request.user
    try:
        # جلب محفظة المستخدم الحالي
        wallet = Wallet.objects.get(user=user)
        return Response({
            'id': wallet.id,
            'balance': wallet.balance,
            'link_code': wallet.link_code, # ✅ هذا ما يحتاجه التطبيق
            'college': wallet.college,     # ✅ وهذا أيضاً
            'currency': 'د.ل'
        })
    except Wallet.DoesNotExist:
        # إذا لم يكن لديه محفظة (حالة نادرة)، نرسل أصفاراً
        return Response({
            'id': 0,
            'balance': 0.00,
            'link_code': '---',
            'college': 'غير محدد',
            'currency': 'د.ل'
        })

# --- الطلبات ---
@api_view(['POST'])
@permission_classes([IsAuthenticated])
def create_order(request):
    user = request.user
    # نستقبل البيانات من التطبيق
    total_price = request.data.get('total_price')
    items_data = request.data.get('items', []) # قائمة المنتجات

    # 1. التحقق من المحفظة والرصيد
    try:
        wallet = Wallet.objects.get(user=user)
        if wallet.balance < float(total_price):
            return Response({'error': 'عذراً، رصيد المحفظة غير كافي!'}, status=400)
    except Wallet.DoesNotExist:
        return Response({'error': 'لا توجد محفظة لهذا المستخدم'}, status=400)

    # 2. إنشاء الطلب
    # (نقوم بإنشاء الطلب يدوياً هنا لضمان حفظ التفاصيل بشكل صحيح)
    from .models import Cafe # استيراد داخلي لتجنب مشاكل دائرية
    
    # نفترض أن الطلب يذهب لأول مقهى (أو يمكن تحديده من المنتج)
    default_cafe = Cafe.objects.first() 
    
    try:
        new_order = Order.objects.create(
            user=user,
            cafe=default_cafe,
            total_price=total_price,
            status='PENDING'
        )

        # إضافة المنتجات للطلب
        for item in items_data:
            product_id = item.get('product_id')
            qty = item.get('qty', 1) # الكمية
            product = Product.objects.get(id=product_id)
            OrderItem.objects.create(order=new_order, product=product, quantity=qty)

        # 3. خصم المبلغ من المحفظة
        Transaction.objects.create(
            wallet=wallet,
            amount=total_price,
            transaction_type='WITHDRAWAL', # خصم
            source='APP',
            description=f'طلب رقم #{new_order.id}'
        )

        return Response({'message': 'تم استلام طلبك بنجاح!', 'order_id': new_order.id}, status=201)

    except Exception as e:
        print(f"❌ Order Error: {e}")
        return Response({'error': 'حدث خطأ أثناء معالجة الطلب'}, status=500)