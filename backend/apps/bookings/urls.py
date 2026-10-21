from django.urls import path

from apps.bookings.views import (
    BookingCancellationView,
    BookingDetailView,
    BookingListView,
    BookingOptionsView,
    StaffBookingDetailView,
    StaffBookingListView,
)

urlpatterns = [
    path("booking-options/", BookingOptionsView.as_view(), name="booking-options"),
    path("bookings/", BookingListView.as_view(), name="bookings"),
    path("bookings/<uuid:booking_id>/", BookingDetailView.as_view(), name="booking-detail"),
    path(
        "bookings/<uuid:booking_id>/cancellation-requests/",
        BookingCancellationView.as_view(),
        name="booking-cancellation",
    ),
    path("admin/bookings/", StaffBookingListView.as_view(), name="staff-bookings"),
    path("admin/bookings/<uuid:booking_id>/", StaffBookingDetailView.as_view(), name="staff-booking-detail"),
]
