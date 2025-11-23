from django.urls import path
from rest_framework.authtoken.views import obtain_auth_token
from . import api_views

app_name = 'core_api'

urlpatterns = [
    path('auth/login/', obtain_auth_token, name='api_login'),
    path('auth/logout/', api_views.logout_view, name='api_logout'),
]