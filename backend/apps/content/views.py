from django.db.models import Q
from django.utils import timezone
from rest_framework.response import Response
from rest_framework.views import APIView

from apps.content.models import Banner
from config.pagination import DefaultPagination


class BannerListView(APIView):
    def get(self, request):
        now = timezone.now()
        queryset = (
            Banner.objects.filter(is_active=True)
            .filter(Q(starts_at__isnull=True) | Q(starts_at__lte=now))
            .filter(Q(ends_at__isnull=True) | Q(ends_at__gt=now))
            .order_by("display_order", "title")
        )
        paginator = DefaultPagination()
        page = paginator.paginate_queryset(queryset, request, view=self)
        return paginator.get_paginated_response(
            [
                {
                    "id": str(banner.id),
                    "title": banner.title,
                    "image_url": banner.image_url,
                    "alt_text": banner.alt_text,
                    "destination_type": banner.destination_type,
                    "destination_id": None if banner.destination_id is None else str(banner.destination_id),
                }
                for banner in page
            ]
        )
