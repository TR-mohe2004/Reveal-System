from django.urls import path
from . import api_views

urlpatterns = [
    path('signup/', api_views.api_signup, name='api_signup'),
    path('login/', api_views.api_login, name='api_login'),
    path('profile/', api_views.api_profile, name='api_profile'),
]
