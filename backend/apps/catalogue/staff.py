from django.db import IntegrityError, transaction
from django.utils.text import slugify
from rest_framework.exceptions import NotFound, PermissionDenied, ValidationError

from apps.accounts.models import UserKind
from apps.catalogue.models import Department, Doctor, DoctorDepartment, Service, ServiceType

_MISSING = object()


def create_department(actor, data):
    _require_staff(actor)
    name = _required_text(data, "name", 120)
    slug = _slug(data.get("slug"), name)
    try:
        with transaction.atomic():
            return Department.objects.create(
                name=name,
                slug=slug,
                description=_optional_text(data, "description"),
                display_order=_order(data, default=0),
                is_active=_flag(data, default=True),
            )
    except IntegrityError as exc:
        raise ValidationError({"slug": "That address is already used."}) from exc


def update_department(actor, department_id, data):
    _require_staff(actor)
    department = Department.objects.filter(pk=department_id).first()
    if department is None:
        raise NotFound()
    if "name" in data:
        department.name = _required_text(data, "name", 120)
    if "slug" in data:
        department.slug = _slug(data.get("slug"), department.name)
    if "description" in data:
        department.description = _optional_text(data, "description")
    order = _order(data)
    if order is not _MISSING:
        department.display_order = order
    active = _flag(data)
    if active is not _MISSING:
        department.is_active = active
    try:
        with transaction.atomic():
            department.save()
    except IntegrityError as exc:
        raise ValidationError({"slug": "That address is already used."}) from exc
    return department


def create_service(actor, data):
    _require_staff(actor)
    return Service.objects.create(
        name=_required_text(data, "name", 160),
        service_type=_service_type(data, required=True),
        description=_optional_text(data, "description"),
        preparation_instructions=_optional_text(data, "preparation_instructions"),
        display_order=_order(data, default=0),
        is_active=_flag(data, default=True),
    )


def update_service(actor, service_id, data):
    _require_staff(actor)
    service = Service.objects.filter(pk=service_id).first()
    if service is None:
        raise NotFound()
    if "name" in data:
        service.name = _required_text(data, "name", 160)
    if "service_type" in data:
        service.service_type = _service_type(data, required=True)
    if "description" in data:
        service.description = _optional_text(data, "description")
    if "preparation_instructions" in data:
        service.preparation_instructions = _optional_text(data, "preparation_instructions")
    order = _order(data)
    if order is not _MISSING:
        service.display_order = order
    active = _flag(data)
    if active is not _MISSING:
        service.is_active = active
    service.save()
    return service


def create_doctor(actor, data):
    _require_staff(actor)
    with transaction.atomic():
        doctor = Doctor.objects.create(
            full_name=_required_text(data, "full_name", 160),
            qualification=_optional_text(data, "qualification", 200),
            specialty_summary=_optional_text(data, "specialty_summary", 250),
            bio=_optional_text(data, "bio"),
            photo_url=_optional_text(data, "photo_url", 2000),
            display_order=_order(data, default=0),
            is_active=_flag(data, default=True),
        )
        if "departments" in data:
            _replace_departments(doctor, data.get("departments"))
    return doctor


def update_doctor(actor, doctor_id, data):
    _require_staff(actor)
    with transaction.atomic():
        doctor = Doctor.objects.select_for_update().filter(pk=doctor_id).first()
        if doctor is None:
            raise NotFound()
        if "full_name" in data:
            doctor.full_name = _required_text(data, "full_name", 160)
        if "qualification" in data:
            doctor.qualification = _optional_text(data, "qualification", 200)
        if "specialty_summary" in data:
            doctor.specialty_summary = _optional_text(data, "specialty_summary", 250)
        if "bio" in data:
            doctor.bio = _optional_text(data, "bio")
        if "photo_url" in data:
            doctor.photo_url = _optional_text(data, "photo_url", 2000)
        order = _order(data)
        if order is not _MISSING:
            doctor.display_order = order
        active = _flag(data)
        if active is not _MISSING:
            doctor.is_active = active
        doctor.save()
        if "departments" in data:
            _replace_departments(doctor, data.get("departments"))
    return doctor


def department_body(department: Department) -> dict:
    return {
        "id": str(department.id),
        "name": department.name,
        "slug": department.slug,
        "description": department.description,
        "display_order": department.display_order,
        "is_active": department.is_active,
    }


def service_body(service: Service) -> dict:
    return {
        "id": str(service.id),
        "name": service.name,
        "service_type": service.service_type,
        "description": service.description,
        "preparation_instructions": service.preparation_instructions,
        "display_order": service.display_order,
        "is_active": service.is_active,
    }


def doctor_body(doctor: Doctor) -> dict:
    links = doctor.department_links.select_related("department").order_by(
        "-is_primary",
        "department__display_order",
        "department__name",
    )
    return {
        "id": str(doctor.id),
        "full_name": doctor.full_name,
        "qualification": doctor.qualification,
        "specialty_summary": doctor.specialty_summary,
        "bio": doctor.bio,
        "photo_url": doctor.photo_url,
        "display_order": doctor.display_order,
        "is_active": doctor.is_active,
        "departments": [
            {
                "id": str(link.department_id),
                "name": link.department.name,
                "slug": link.department.slug,
                "is_primary": link.is_primary,
            }
            for link in links
        ],
    }


def _replace_departments(doctor, raw) -> None:
    if not isinstance(raw, list):
        raise ValidationError({"departments": "Send a list of departments."})
    chosen = []
    seen = set()
    primary_count = 0
    for item in raw:
        if not isinstance(item, dict) or not item.get("id"):
            raise ValidationError({"departments": "Each department needs an id."})
        department_id = str(item["id"])
        if department_id in seen:
            raise ValidationError({"departments": "A department can be linked only once."})
        seen.add(department_id)
        is_primary = bool(item.get("is_primary"))
        if is_primary:
            primary_count += 1
        chosen.append((department_id, is_primary))
    if primary_count > 1:
        raise ValidationError({"departments": "Choose one primary department."})
    found = {str(row.id): row for row in Department.objects.filter(pk__in=seen)}
    if len(found) != len(seen):
        raise ValidationError({"departments": "Choose a department that exists."})
    doctor.department_links.all().delete()
    DoctorDepartment.objects.bulk_create(
        [
            DoctorDepartment(doctor=doctor, department=found[department_id], is_primary=is_primary)
            for department_id, is_primary in chosen
        ]
    )


def _require_staff(user) -> None:
    if user.user_kind not in (UserKind.STAFF, UserKind.ADMIN) or not user.is_active:
        raise PermissionDenied()


def _required_text(data, field, max_length) -> str:
    text = str(data.get(field) or "").strip()
    if not text:
        raise ValidationError({field: "This field is required."})
    if len(text) > max_length:
        raise ValidationError({field: f"Use {max_length} characters or fewer."})
    return text


def _optional_text(data, field, max_length=8000):
    if field not in data or data.get(field) is None:
        return None
    text = str(data.get(field)).strip()
    if not text:
        return None
    if max_length is not None and len(text) > max_length:
        raise ValidationError({field: f"Use {max_length} characters or fewer."})
    return text


def _order(data, default=_MISSING):
    if "display_order" not in data:
        return default
    try:
        value = int(data.get("display_order"))
    except (TypeError, ValueError):
        raise ValidationError({"display_order": "Enter a whole number."}) from None
    if value < 0:
        raise ValidationError({"display_order": "Enter zero or a positive number."})
    return value


def _flag(data, default=_MISSING):
    if "is_active" not in data:
        return default
    value = data.get("is_active")
    if not isinstance(value, bool):
        raise ValidationError({"is_active": "Choose whether this is published."})
    return value


def _service_type(data, required) -> str:
    if "service_type" not in data and not required:
        raise ValidationError({"service_type": "Choose a service type."})
    value = str(data.get("service_type") or "").strip()
    if value not in ServiceType.values:
        raise ValidationError({"service_type": "Choose a service type."})
    return value


def _slug(raw, name) -> str:
    source = str(raw).strip() if raw else name
    slug = slugify(source)[:140]
    if not slug:
        raise ValidationError({"slug": "Enter a short name the address can use."})
    return slug
