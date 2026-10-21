from django.urls import path

from apps.content.views import BannerListView

urlpatterns = [
    path("banners/", BannerListView.as_view(), name="banners"),
]
