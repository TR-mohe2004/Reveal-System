from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from rest_framework.authtoken.models import Token
from django.contrib.auth import authenticate
from django.db.models import Q
from core.utils import normalize_libyan_phone
from .serializers import UserSerializer
from .models import User
from wallet.models import Wallet

@api_view(['POST'])
@permission_classes([AllowAny])
def api_signup(request):
    serializer = UserSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        token, created = Token.objects.get_or_create(user=user)
        return Response({
            'message': 'تم إنشاء الحساب بنجاح',
            'user': serializer.data,
            'token': token.key
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([AllowAny])
def api_login(request):
    phone_number = request.data.get('phone_number')
    password = request.data.get('password')
    
    # Use Django's built-in authenticate
    user = authenticate(phone_number=phone_number, password=password)
    
    if user is not None:
        token, created = Token.objects.get_or_create(user=user)
        serializer = UserSerializer(user)
        
        try:
            balance = user.wallet.balance
        except Wallet.DoesNotExist:
            balance = 0.0
                
        return Response({
            'message': 'تم تسجيل الدخول',
            'user': serializer.data,
            'wallet_balance': balance,
            'token': token.key
        })
    else:
        return Response({'error': 'البيانات غير صحيحة'}, status=status.HTTP_401_UNAUTHORIZED)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def api_profile(request):
    # More explicit check
    if request.user.is_authenticated:
        serializer = UserSerializer(request.user)
        return Response(serializer.data)
    return Response({"error": "غير مصرح لك"}, status=status.HTTP_401_UNAUTHORIZED)
