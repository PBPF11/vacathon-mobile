from django.core.paginator import Paginator
from django.db.models import Count, Q
from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.decorators import api_view
from rest_framework.response import Response

from core.api_helpers import serialize_post, serialize_thread
from events.models import Event
from .models import ForumPost, ForumThread


@api_view(["GET", "POST"])
def threads_api(request):
    """
    List or create forum threads.
    Supports filtering by event, searching, and sorting (recent|popular|latest).
    """
    if request.method == "GET":
        queryset = (
            ForumThread.objects.select_related("event", "author")
            .annotate(post_count=Count("posts", distinct=True))
        )

        event_filter = request.GET.get("event")
        search_term = request.GET.get("q", "")
        sort = request.GET.get("sort", "recent")

        if event_filter:
            queryset = queryset.filter(event_id=event_filter)
        if search_term:
            queryset = queryset.filter(
                Q(title__icontains=search_term) | Q(body__icontains=search_term)
            )

        if sort == "popular":
            queryset = queryset.order_by("-is_pinned", "-post_count")
        elif sort == "latest":
            queryset = queryset.order_by("-is_pinned", "-created_at")
        else:
            queryset = queryset.order_by("-is_pinned", "-last_activity_at")

        paginator = Paginator(queryset, 20)
        page_number = request.GET.get("page") or 1
        page_obj = paginator.get_page(page_number)

        return Response(
            {
                "results": [serialize_thread(thread) for thread in page_obj.object_list],
                "total": paginator.count,
                "has_next": page_obj.has_next(),
            }
        )

    # POST create thread
    payload = request.data
    event_id = payload.get("event")
    title = (payload.get("title") or "").strip()
    body = (payload.get("body") or "").strip()

    if not event_id or not title:
        return Response(
            {"detail": "event and title are required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    event = get_object_or_404(Event, pk=event_id)
    thread = ForumThread.objects.create(
        event=event,
        author=request.user,
        title=title,
        body=body,
    )
    return Response(serialize_thread(thread), status=status.HTTP_201_CREATED)


@api_view(["GET"])
def posts_api(request, thread_id: int):
    """List posts for a thread."""
    thread = get_object_or_404(ForumThread, pk=thread_id)
    queryset = thread.posts.select_related("author", "thread", "parent").prefetch_related("likes")

    paginator = Paginator(queryset, 30)
    page_number = request.GET.get("page") or 1
    page_obj = paginator.get_page(page_number)

    return Response(
        {
            "results": [
                serialize_post(post, user=request.user) for post in page_obj.object_list
            ],
            "total": paginator.count,
            "has_next": page_obj.has_next(),
        }
    )


@api_view(["POST"])
def create_post_api(request):
    """Create a post or reply inside a thread."""
    payload = request.data
    thread_id = payload.get("thread")
    content = (payload.get("content") or "").strip()
    parent_id = payload.get("parent")

    if not thread_id or not content:
        return Response(
            {"detail": "thread and content are required."},
            status=status.HTTP_400_BAD_REQUEST,
        )

    thread = get_object_or_404(ForumThread, pk=thread_id)
    parent = None
    if parent_id:
        parent = get_object_or_404(ForumPost, pk=parent_id, thread=thread)

    post = ForumPost.objects.create(
        thread=thread,
        author=request.user,
        parent=parent,
        content=content,
    )
    thread.touch()
    return Response(serialize_post(post, user=request.user), status=status.HTTP_201_CREATED)


@api_view(["POST"])
def like_post_api(request, post_id: int):
    """Toggle like for a post, returns the updated like state."""
    post = get_object_or_404(ForumPost.objects.select_related("thread"), pk=post_id)
    if post.likes.filter(pk=request.user.pk).exists():
        post.likes.remove(request.user)
        liked = False
    else:
        post.likes.add(request.user)
        liked = True
    post.thread.touch()
    return Response({"success": True, "liked": liked, "like_count": post.like_count})
