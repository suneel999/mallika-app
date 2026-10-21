from django.urls import path

from apps.notifications.views import DeviceDetailView, DeviceListView, NotificationListView

urlpatterns = [
    path("notifications/", NotificationListView.as_view(), name="notifications"),
    path("devices/", DeviceListView.as_view(), name="devices"),
    path("devices/<uuid:device_id>/", DeviceDetailView.as_view(), name="device-detail"),
]
