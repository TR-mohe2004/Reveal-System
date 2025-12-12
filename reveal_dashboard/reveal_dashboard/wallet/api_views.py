from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from .models import Wallet
from .serializers import WalletSerializer

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def get_wallet(request):
    wallet, created = Wallet.objects.get_or_create(user=request.user)
    serializer = WalletSerializer(wallet)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def link_wallet(request):
    link_code = request.data.get('link_code')
    if not link_code:
        return Response({'error': 'Code is required'}, status=400)
    
    try:
        wallet, created = Wallet.objects.get_or_create(user=request.user)
        
        if Wallet.objects.filter(link_code=link_code).exclude(user=request.user).exists():
             return Response({'error': 'Code already in use by another user'}, status=400)
        
        wallet.link_code = link_code
        wallet.save()
        return Response({'success': True, 'message': 'Wallet linked successfully'})
    except Exception as e:
         return Response({'error': str(e)}, status=500)
