from rest_framework.response import Response
from rest_framework.views import APIView

from apps.reports.services import booking_counts


class DashboardView(APIView):
    def get(self, request):
        return Response(
            booking_counts(
                request.user,
                request.query_params.get("from", ""),
                request.query_params.get("to", ""),
            )
        )
