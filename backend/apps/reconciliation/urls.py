from django.urls import path

from apps.reconciliation.views import HimsReconciliationView

urlpatterns = [
    path(
        "admin/bookings/<uuid:booking_id>/hims-reconciliation/",
        HimsReconciliationView.as_view(),
        name="hims-reconciliation",
    ),
]
