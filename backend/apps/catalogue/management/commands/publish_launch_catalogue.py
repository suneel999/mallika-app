"""Publish the consultation doctor and the bookable services for launch.

The hospital gave these on 14 November 2026. The command is safe to run again:
it corrects the rows and does not create a second copy. Lab Tests is shown as
coming soon in the app and is not published here.
"""

from django.core.management.base import BaseCommand
from django.db import transaction

from apps.catalogue.models import Doctor, Service, ServiceType

DOCTOR_NAME = "Dr. J Mahesh Babu"
DOCTOR_SPECIALTY = "Senior Cardiologist"
# Name, short description, and position in the list.
SERVICES = (
    ("4D Echo", "Heart ultrasound", 1),
    ("CT Calcium", "Calcium score scan", 2),
    ("CT Angio", "Coronary CT scan", 3),
)


class Command(BaseCommand):
    help = "Publish the consultation doctor and the bookable services."

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

        for name, description, order in SERVICES:
            service = Service.objects.filter(name__iexact=name).first()
            if service is None:
                service = Service(name=name)
            service.service_type = ServiceType.DIAGNOSTICS
            service.description = description
            service.display_order = order
            service.is_active = True
            service.save()

        self.stdout.write(
            f"Consultation doctor: {doctor.full_name}, {doctor.specialty_summary}. "
            f"Services: {', '.join(name for name, _, _ in SERVICES)}. Other doctors moved down: {moved}."
        )
