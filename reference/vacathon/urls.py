"""
URL configuration for vacathon project.

The `urlpatterns` list routes URLs to views. For more information please see:
    https://docs.djangoproject.com/en/5.2/topics/http/urls/
Examples:
Function views
    1. Add an import:  from my_app import views
    2. Add a URL to urlpatterns:  path('', views.home, name='home')
Class-based views
    1. Add an import:  from other_app.views import Home
    2. Add a URL to urlpatterns:  path('', Home.as_view(), name='home')
Including another URLconf
    1. Import the include() function: from django.urls import include, path
    2. Add a URL to urlpatterns:  path('blog/', include('blog.urls'))
"""
from django.contrib import admin
from django.urls import path, include

# Impor ini untuk menyajikan file media (upload) saat development
from django.conf import settings
from django.conf.urls.static import static


urlpatterns = [
    path('accounts/', include('django.contrib.auth.urls')),
    path('', include('core.urls')),
    path('events/', include('events.urls')),
    path('event-detail/', include('event_detail.urls')),
    path('forum/', include('forum.urls')),
    path('profile/', include('profiles.urls')),
    path('register/', include('registrations.urls')),
    path('notifications/', include('notifications.urls')),
    path('admin/events/api/', include('events.admin_api_urls')),
    path('admin/participants/api/', include('registrations.admin_api_urls')),
    path('admin/', admin.site.urls),
    # API endpoints
    path('api/', include('core.api_urls')),
    path('api/events/', include('events.api_urls')),
    path('api/forum/', include('forum.api_urls')),
    path('api/profile/', include('profiles.api_urls')),
    path('api/register/', include('registrations.api_urls')),  # legacy prefix
    path('api/registrations/', include('registrations.api_urls')),  # mobile-friendly prefix
    path('api/notifications/', include('notifications.api_urls')),
    # ======================================================
]

# Tambahkan ini di bagian bawah HANYA untuk development (DEBUG=True)
# Ini agar server Django mau menyajikan file yang di-upload ke MEDIA_ROOT
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
