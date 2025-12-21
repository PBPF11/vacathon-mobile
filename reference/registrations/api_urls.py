from django.urls import path

from . import api_views

app_name = "registrations_api"

urlpatterns = [
    path("", api_views.registrations_api, name="registrations"),
    path("<str:reference_code>/", api_views.registration_detail_api, name="registration-detail"),
]
