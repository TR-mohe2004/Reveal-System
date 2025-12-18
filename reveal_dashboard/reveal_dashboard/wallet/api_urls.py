from django.urls import path
from . import api_views

urlpatterns = [
    path('', api_views.get_wallet, name='get_wallet'),
    path('link/', api_views.link_wallet, name='link_wallet'),
    path('topup/', api_views.topup_wallet, name='topup_wallet'),
]
