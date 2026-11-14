"""Publish the consultation doctor and the one bookable service for launch.

The hospital gave these on 14 November 2026. The command is safe to run again:
it corrects the two rows and does not create a second copy. CT Calcium, CT Angio,
and Lab Tests are shown as coming soon in the app and are not published here.
"""

from django.core.management.base import BaseCommand
from django.db import transaction

from apps.catalogue.models import Doctor, Service, ServiceType

DOCTOR_NAME = "Dr. J Mahesh Babu"
DOCTOR_SPECIALTY = "Senior Cardiologist"
ECHO_NAME = "4D Echo"


class Command(BaseCommand):
    help = "Publish the consultation doctor and the 4D Echo service."

    def add_arguments(self, parser):
        parser.add_argument(
            "--photo-url",
            default="",
            help="Web address of the doctor's photo. Left unchanged when empty.",
        )

    @transaction.atomic
    def handle(self, *args, **options):
        doctor = Doctor.objects.filter(full_name__iexact=DOCTOR_NAME).first()
        if doctor is None:
            doctor = Doctor(full_name=DOCTOR_NAME)
        doctor.specialty_summary = DOCTOR_SPECIALTY
        doctor.display_order = 0
        doctor.is_active = True
        if options["photo_url"]:
            doctor.photo_url = options["photo_url"]
        doctor.save()
        # Consultation uses the first published doctor, so no other doctor may come first.
        others = Doctor.objects.filter(is_active=True, display_order=0).exclude(pk=doctor.pk)
        moved = others.update(display_order=10)

        echo = Service.objects.filter(name__iexact=ECHO_NAME).first()
        if echo is None:
            echo = Service(name=ECHO_NAME)
        echo.service_type = ServiceType.DIAGNOSTICS
        echo.description = "Heart ultrasound"
        echo.is_active = True
        echo.save()

        self.stdout.write(
            f"Consultation doctor: {doctor.full_name}, {doctor.specialty_summary}. "
            f"Service: {echo.name}. Other doctors moved down: {moved}."
        )
