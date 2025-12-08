from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.contrib.auth import authenticate
from .serializers import UserSerializer
from wallet.models import Wallet

@api_view(['POST'])
@permission_classes([AllowAny])
def api_signup(request):
    serializer = UserSerializer(data=request.data)
    if serializer.is_valid():
        user = serializer.save()
        return Response({
            'message': 'تم إنشاء الحساب بنجاح',
            'user': serializer.data,
            'token': 'demo-token-123' # في الإنتاج نستخدم توكن حقيقي
        }, status=status.HTTP_201_CREATED)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['POST'])
@permission_classes([AllowAny])
def api_login(request):
    email = request.data.get('email')
    password = request.data.get('password')
    
    user = authenticate(email=email, password=password)
    
    if user is not None:
        serializer = UserSerializer(user)
        # جلب الرصيد
        try:
            balance = user.wallet.balance
        except:
            balance = 0.0
            
        return Response({
            'message': 'تم تسجيل الدخول',
            'user': serializer.data,
            'wallet_balance': balance,
            'token': 'demo-token-123'
        })
    else:
        return Response({'error': 'البيانات غير صحيحة'}, status=status.HTTP_401_UNAUTHORIZED)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def api_profile(request):
    serializer = UserSerializer(request.user)
    return Response(serializer.data)
