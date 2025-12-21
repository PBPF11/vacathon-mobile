from django.urls import path

from . import api_views

app_name = "forum_api"

urlpatterns = [
    path("threads/", api_views.threads_api, name="threads"),
    path("threads/<int:thread_id>/posts/", api_views.posts_api, name="posts"),
    path("posts/", api_views.create_post_api, name="post-create"),
    path("posts/<int:post_id>/like/", api_views.like_post_api, name="post-like"),
]
