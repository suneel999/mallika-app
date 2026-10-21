from rest_framework.response import Response
from rest_framework.views import APIView

from apps.reconciliation.services import update_hims_reconciliation


class HimsReconciliationView(APIView):
    def patch(self, request, booking_id):
        reconciliation = update_hims_reconciliation(request.user, booking_id, request.data)
        return Response(
            {
                "booking_id": str(reconciliation.booking_id),
                "booking_status": reconciliation.booking_status,
                "status": reconciliation.status,
                "hims_appointment_id": reconciliation.hims_appointment_id,
                "hims_patient_id": reconciliation.hims_patient_id,
                "note": reconciliation.note,
                "checked_at": reconciliation.checked_at,
            }
        )
