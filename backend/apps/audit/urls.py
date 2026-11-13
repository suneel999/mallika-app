from django.urls import path

from apps.audit.views import StaffAuditLogListView

urlpatterns = [
    path("admin/audit-logs/", StaffAuditLogListView.as_view(), name="admin-audit-logs"),
]
