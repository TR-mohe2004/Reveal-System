from django.urls import path
from . import api_views

urlpatterns = [
    # الرابط سيكون: /api/wallet/
    path('', api_views.get_wallet, name='get_wallet'),
    
    # الرابط سيكون: /api/wallet/link/
    path('link/', api_views.link_wallet, name='link_wallet'),
    
    # الرابط سيكون: /api/wallet/topup/
    path('topup/', api_views.topup_wallet, name='topup_wallet'),
]