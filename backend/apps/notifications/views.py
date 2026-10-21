from rest_framework.response import Response
from rest_framework.views import APIView

from apps.notifications.models import Notification
from apps.notifications.services import register_device, unregister_device
from config.pagination import DefaultPagination


class NotificationListView(APIView):
    def get(self, request):
        queryset = Notification.objects.filter(user=request.user).order_by("-created_at")
        paginator = DefaultPagination()
        page = paginator.paginate_queryset(queryset, request, view=self)
        return paginator.get_paginated_response([_notification_body(item) for item in page])


class DeviceListView(APIView):
    def post(self, request):
        device = register_device(request.user, request.data.get("platform"), request.data.get("token"))
        return Response({"id": str(device.id), "platform": device.platform, "is_active": device.is_active}, status=201)


class DeviceDetailView(APIView):
    def delete(self, request, device_id):
        unregister_device(request.user, device_id)
        return Response(status=204)


def _notification_body(notification: Notification) -> dict:
    payload = notification.payload if isinstance(notification.payload, dict) else {}
    return {
        "id": str(notification.id),
        "title": str(payload.get("title") or "Mallika Hospitals"),
        "body": str(payload.get("body") or ""),
        "template_key": notification.template_key,
        "channel": notification.channel,
        "status": notification.status,
        "booking_id": None if notification.booking_id is None else str(notification.booking_id),
        "created_at": notification.created_at,
    }
