from django.urls import path

from . import api_views

app_name = "notifications_api"

urlpatterns = [
    path("", api_views.notifications_api, name="notifications"),
    path("<int:pk>/read/", api_views.mark_notification_read_api, name="mark-read"),
    path("mark-all-read/", api_views.mark_all_read_api, name="mark-all-read"),
]
