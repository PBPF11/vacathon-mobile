from django.urls import path

from . import admin_api_views

app_name = "events_admin_api"

urlpatterns = [
    path("events/", admin_api_views.admin_events_api, name="events"),
    path("events/<int:event_id>/", admin_api_views.admin_event_detail_api, name="event-detail"),
    path("events/<int:event_id>/delete/", admin_api_views.admin_event_delete_api, name="event-delete"),
    path("event-categories/", admin_api_views.admin_event_categories_api, name="event-categories"),
]
