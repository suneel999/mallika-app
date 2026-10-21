from django.urls import path

from apps.bookings.views import BookingDetailView, BookingListView, BookingOptionsView

urlpatterns = [
    path("booking-options/", BookingOptionsView.as_view(), name="booking-options"),
    path("bookings/", BookingListView.as_view(), name="bookings"),
    path("bookings/<uuid:booking_id>/", BookingDetailView.as_view(), name="booking-detail"),
]
