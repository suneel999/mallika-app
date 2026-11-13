from rest_framework.response import Response
from rest_framework.views import APIView

from apps.patients.staff import detail_body, get_patient, search_body, search_patients, update_patient
from config.pagination import DefaultPagination


class StaffPatientListView(APIView):
    def get(self, request):
        queryset = search_patients(request.user, request.query_params.get("q", ""), request)
        paginator = DefaultPagination()
        page = paginator.paginate_queryset(queryset, request, view=self)
        return paginator.get_paginated_response([search_body(profile) for profile in page])


class StaffPatientDetailView(APIView):
    def get(self, request, profile_id):
        profile = get_patient(request.user, profile_id, request)
        return Response(detail_body(profile))

    def patch(self, request, profile_id):
        profile = update_patient(request.user, profile_id, request.data, request)
        return Response(detail_body(profile))
