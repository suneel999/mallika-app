from rest_framework.views import APIView

from apps.audit.search import audit_body, search_audit_logs
from config.pagination import DefaultPagination


class StaffAuditLogListView(APIView):
    def get(self, request):
        queryset = search_audit_logs(request.user, request.query_params)
        paginator = DefaultPagination()
        page = paginator.paginate_queryset(queryset, request, view=self)
        return paginator.get_paginated_response([audit_body(entry) for entry in page])
