from rest_framework import serializers

from apps.bookings.models import Booking


class BookingSerializer(serializers.ModelSerializer):
    patient_profile_id = serializers.UUIDField(read_only=True)
    patient_name = serializers.CharField(source="patient_profile.full_name", read_only=True)
    doctor_id = serializers.UUIDField(read_only=True, allow_null=True)
    doctor_name = serializers.SerializerMethodField()
    service_id = serializers.UUIDField(read_only=True, allow_null=True)
    service_name = serializers.SerializerMethodField()

    class Meta:
        model = Booking
        fields = [
            "id",
            "reference",
            "patient_profile_id",
            "patient_name",
            "booking_type",
            "doctor_id",
            "doctor_name",
            "service_id",
            "service_name",
            "requested_date",
            "preferred_time_slot",
            "patient_note",
            "status",
            "confirmed_for",
            "created_at",
        ]

    def get_doctor_name(self, booking):
        return booking.doctor.full_name if booking.doctor_id else None

    def get_service_name(self, booking):
        return booking.service.name if booking.service_id else None


class StaffBookingSerializer(BookingSerializer):
    class Meta(BookingSerializer.Meta):
        fields = BookingSerializer.Meta.fields + ["staff_note"]
