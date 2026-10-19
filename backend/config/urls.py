from django.urls import include, path

urlpatterns = [
    path("api/v1/", include("config.api_urls")),
]

handler404 = "config.exceptions.not_found"
handler500 = "config.exceptions.server_error"
