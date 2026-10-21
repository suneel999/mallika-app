from django.urls import include, path

from config.health import health

urlpatterns = [
    path("health/", health, name="health"),
    path("", include("apps.accounts.urls")),
    path("", include("apps.patients.urls")),
    path("", include("apps.catalogue.urls")),
    path("", include("apps.bookings.urls")),
]
