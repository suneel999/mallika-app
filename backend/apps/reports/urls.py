from django.urls import path

from apps.reports.views import DashboardView

urlpatterns = [
    path("admin/dashboard/", DashboardView.as_view(), name="admin-dashboard"),
]
