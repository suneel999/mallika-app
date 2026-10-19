from django.db import IntegrityError
from django.test import TestCase

from apps.accounts.models import User


class UserModelTests(TestCase):
    def test_patient_user_stores_normalized_mobile_and_unusable_password(self):
        user = User.objects.create_user("  +919999999999  ")
        self.assertEqual(user.mobile_number, "+919999999999")
        self.assertEqual(user.user_kind, "patient")
        self.assertEqual(user.preferred_language, "en")
        self.assertFalse(user.has_usable_password())
        self.assertFalse(user.is_staff)

    def test_mobile_number_is_unique(self):
        User.objects.create_user("+919999999999")
        with self.assertRaises(IntegrityError):
            User.objects.create_user("+919999999999")

    def test_invalid_user_kind_is_rejected_by_the_database(self):
        user = User(mobile_number="+919999999997", user_kind="patient", preferred_language="en")
        user.user_kind = "owner"
        user.set_unusable_password()
        with self.assertRaises(IntegrityError):
            user.save()

    def test_staff_user_can_store_a_password(self):
        user = User.objects.create_user(
            "+919999999998",
            password="not-a-real-password",
            user_kind="staff",
            is_staff=True,
        )
        self.assertTrue(user.check_password("not-a-real-password"))
        self.assertEqual(user.user_kind, "staff")
