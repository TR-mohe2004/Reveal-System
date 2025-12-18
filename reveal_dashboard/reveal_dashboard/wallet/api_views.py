from decimal import Decimal

from django.db import transaction
from firebase_admin import auth as fb_auth
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from users.models import User
from .models import Wallet, Transaction
from .serializers import WalletSerializer


def verify_token_get_user(request):
    auth_header = request.META.get('HTTP_AUTHORIZATION', '')
    if not auth_header.startswith('Bearer '):
        raise ValueError("Missing Authorization Header")
    token = auth_header.split(' ', 1)[1]
    decoded = fb_auth.verify_id_token(token)
    phone = decoded.get('phone_number')
    if not phone:
        raise ValueError("Missing phone in token")
    user = User.objects.filter(phone_number=phone).select_related('wallet').first()
    if not user:
        raise ValueError("CODE_4004: wallet not found")
    return user


@api_view(['GET'])
@permission_classes([AllowAny])
def get_wallet(request):
    """
    يعيد بيانات المحفظة للعميل مع قائمة المعاملات، مع تضمين college_name في كل معاملة.
    يعتمد على Firebase ID Token في Authorization Header.
    """
    try:
        user = verify_token_get_user(request)
    except Exception as e:
        return Response({'error': str(e)}, status=401)

    wallet, _ = Wallet.objects.select_related('user').get_or_create(user=user)
    wallet.prefetched_transactions = wallet.transactions.order_by('-created_at').select_related('wallet')
    serializer = WalletSerializer(wallet)
    return Response(serializer.data)


@api_view(['POST'])
@permission_classes([AllowAny])
def link_wallet(request):
    try:
        user = verify_token_get_user(request)
    except Exception as e:
        return Response({'error': str(e)}, status=401)

    link_code = request.data.get('link_code')
    if not link_code:
        return Response({'error': 'Code is required'}, status=400)
    
    try:
        wallet, _ = Wallet.objects.get_or_create(user=user)
        
        if Wallet.objects.filter(link_code=link_code).exclude(user=user).exists():
             return Response({'error': 'Code already in use by another user'}, status=400)
        
        wallet.link_code = link_code
        wallet.save()
        return Response({'success': True, 'message': 'Wallet linked successfully'})
    except Exception as e:
         return Response({'error': str(e)}, status=500)


@api_view(['POST'])
@permission_classes([AllowAny])
def topup_wallet(request):
    """
    شحن المحفظة عبر التطبيق (بعد تحقق التوكن).
    """
    try:
        user = verify_token_get_user(request)
    except Exception as e:
        return Response({'error': str(e)}, status=401)

    amount_raw = request.data.get('amount')
    try:
        amount = Decimal(str(amount_raw))
    except Exception:
        return Response({'error': 'Invalid amount'}, status=400)

    if amount <= 0:
        return Response({'error': 'Amount must be greater than zero'}, status=400)

    try:
        with transaction.atomic():
            wallet, _ = Wallet.objects.get_or_create(user=user)
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
