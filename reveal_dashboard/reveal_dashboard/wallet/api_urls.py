from django.urls import path
from . import api_views

urlpatterns = [
    path('', api_views.get_wallet, name='get_wallet'),
]
