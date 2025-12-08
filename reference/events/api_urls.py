from django.urls import path

from . import api_views

app_name = "events_api"

urlpatterns = [
    path("", api_views.events_list_api, name="list"),
    path("<int:event_id>/", api_views.event_summary_api, name="detail"),
    path("<int:event_id>/detail/", api_views.event_detail_api, name="detail-extended"),
]
