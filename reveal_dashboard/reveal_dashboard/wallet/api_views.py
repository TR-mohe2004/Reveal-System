from decimal import Decimal
from django.db import transaction
from firebase_admin import auth as fb_auth
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from django.conf import settings
from django.contrib.auth import get_user_model

from .models import Wallet, Transaction
from .serializers import WalletSerializer

User = get_user_model()

def verify_token_get_user(request):
    """
    دالة مساعدة للتحقق من التوكن واسترجاع المستخدم.
    """
    auth_header = request.META.get('HTTP_AUTHORIZATION', '')
    if not auth_header.startswith('Bearer '):
        raise ValueError("Missing Authorization Header")
    
    token = auth_header.split(' ', 1)[1]
    try:
        decoded = fb_auth.verify_id_token(token)
        phone = decoded.get('phone_number')
        if not phone:
             # Fallback: try retrieving user by uid if phone is missing in token
             uid = decoded.get('uid')
             # You might need logic here to find user by UID if phone is key
             raise ValueError("Missing phone in token")
             
        # Normalize phone if needed (e.g. remove +218 and add 0)
        # For now, we assume stored phone matches token phone format
        
        user = User.objects.filter(phone_number=phone).select_related('wallet').first()
        if not user:
            raise ValueError("User not found for this token")
        return user
    except Exception as e:
        raise ValueError(f"Token validation error: {str(e)}")

def get_request_user(request):
    """
    Prefer DRF Token auth (request.user). Fall back to Firebase Bearer token if present.
    """
    if hasattr(request, 'user') and request.user and request.user.is_authenticated:
        return request.user
    auth_header = request.META.get('HTTP_AUTHORIZATION', '')
    if auth_header.startswith('Bearer '):
        return verify_token_get_user(request)
    raise ValueError("Missing Authorization Header")



@api_view(['GET'])
@permission_classes([AllowAny]) # We handle auth manually via Firebase Token
def get_wallet(request):
    try:
        user = get_request_user(request)
    except Exception as e:
        return Response({'error': str(e)}, status=401)

    wallet, _ = Wallet.objects.get_or_create(user=user)
    
    # جلب آخر 20 معاملة فقط لتقليل الضغط على السيرفر
    recent_transactions = wallet.transactions.order_by('-created_at')[:20]
    
    # نمرر المعاملات يدوياً للسيريالايزر
    serializer = WalletSerializer(wallet)
    data = serializer.data
    # نستبدل المعاملات بالقائمة المحدثة (لضمان الترتيب والعدد)
    from .serializers import TransactionSerializer
    data['transactions'] = TransactionSerializer(recent_transactions, many=True).data
    
    return Response(data)


@api_view(['POST'])
@permission_classes([AllowAny])
def link_wallet(request):
    try:
        user = get_request_user(request)
    except Exception as e:
        return Response({'error': str(e)}, status=401)

    link_code = request.data.get('link_code')
    if not link_code:
        return Response({'error': 'Code is required'}, status=400)
    
    try:
        # التأكد من أن الكود فريد وغير مستخدم من شخص آخر
        if Wallet.objects.filter(link_code=link_code).exclude(user=user).exists():
             return Response({'error': 'هذا الكود مستخدم بالفعل من قبل طالب آخر'}, status=400)
        
        wallet, _ = Wallet.objects.get_or_create(user=user)
        wallet.link_code = link_code
        wallet.save()
        return Response({'success': True, 'message': 'تم ربط المحفظة بنجاح'})
    except Exception as e:
         return Response({'error': str(e)}, status=500)


@api_view(['POST'])
@permission_classes([AllowAny])
def topup_wallet(request):
    """
    شحن المحفظة (لأغراض الاختبار أو إذا كان هناك بوابة دفع).
    """
    try:
        user = get_request_user(request)
    except Exception as e:
        return Response({'error': str(e)}, status=401)

    amount_raw = request.data.get('amount')
    try:
        amount = Decimal(str(amount_raw))
    except:
        return Response({'error': 'Invalid amount'}, status=400)

    if amount <= 0:
        return Response({'error': 'Amount must be positive'}, status=400)

    try:
        wallet, _ = Wallet.objects.get_or_create(user=user)
        # إنشاء معاملة من نوع إيداع (سيقوم المودل بزيادة الرصيد تلقائياً)
        Transaction.objects.create(
            wallet=wallet,
            amount=amount,
            transaction_type='DEPOSIT',
            source='APP',
            description='App top-up'
        )
        return Response({'success': True, 'balance': wallet.balance})
    except Exception as e:
        return Response({'error': str(e)}, status=500)