# Google Play listing for Mallika Hospitals

Text and answers to copy into Play Console. Items in [brackets] are the hospital's to supply.

## Files

| What Play asks for | File |
| --- | --- |
| App bundle | `mobile/build/app/outputs/bundle/release/app-release.aab` |
| App icon, 512 x 512 | `store/android/icon-512.png` |
| Feature graphic, 1024 x 500 | `store/android/feature-graphic-1024x500.png` |
| Phone screenshots, 1080 x 1920 | `store/android/screenshots/` (six files, in order) |

The screenshots use a made-up patient name. The doctor's name and photo are real.

## Store listing

**App name** (30 characters at most)

Mallika Hospitals

**Short description** (80 characters at most)

Book a consultation, 4D Echo or CT scan at Mallika Hospitals from your phone.

**Full description**

Mallika Hospitals brings your hospital visit to your phone.

Request a consultation with our senior cardiologist, or a 4D Echo, CT Calcium or CT Angio scan. Choose the date and time that suit you. Our reception team reviews each request and confirms your appointment.

What you can do
• Sign in with your WhatsApp number. No password to remember.
• Request a consultation with Dr. J Mahesh Babu, Senior Cardiologist.
• Request a 4D Echo, CT Calcium or CT Angio scan.
• Pick your preferred date and time.
• See whether your request is pending, confirmed or completed.
• Get updates in the app when the hospital confirms or changes your booking.
• Ask to cancel a booking.
• Add family members to your account.
• Call the hospital ambulance in one tap.
• Open directions to the hospital in Google Maps.

Good to know
• A booking is a request. It is confirmed when the hospital confirms it.
• You pay at the hospital. The app takes no payment.
• You can delete your account from the Profile screen at any time.

Mallika Hospitals. ఆపదలో మీ నేస్తం.

**Category:** Medical
**Tags:** Hospital, appointments
**Contact email:** [email]
**Contact phone:** [phone]
**Website:** https://mallikahospitals.in
**Privacy policy:** [the address of the page you published]

## App content answers

**App access:** All or some functionality is restricted. Give the review mobile number and 6-digit code set with `infra/set-review-login.ps1`, and this instruction: "Enter the mobile number, tap Login, then enter the code. No WhatsApp message is needed for this number."

**Ads:** No, the app does not contain ads.

**Content rating:** Category "Reference, News, or Educational" or "Utility". No violence, sexual content, gambling, user-generated content or sharing of location. Users cannot talk to each other.

**Target audience:** 18 and over.

**News app:** No.

**Health apps declaration:** Tick "Medical" features that apply: clinical or hospital appointment booking. The app is not a medical device and gives no diagnosis.

**Government app, financial features:** No.

**Data safety**

- Does the app collect or share user data? Yes.
- Is all data encrypted in transit? Yes.
- Can users request deletion? Yes. In-app (Profile, Delete Account) and by the web address of the privacy policy's deletion section.

| Data type | Collected | Shared | Required | Purpose |
| --- | --- | --- | --- | --- |
| Name | Yes | No | Required | App functionality, account management |
| Phone number | Yes | No | Required | App functionality, account management |
| Email address | Only if the hospital records it | No | Optional | Account management |
| Health info (appointment requests and the note to the hospital) | Yes | No | Required | App functionality |
| User IDs (patient number) | Yes | No | Required | Account management |

Not collected: location, financial info, messages, photos, files, contacts, calendar, app activity for analytics, web browsing, device identifiers for advertising.

The phone number is sent to WhatsApp only to deliver the sign-in code. Play treats a transfer to a service provider acting for you as not "shared".

## Release

- First upload to **Internal testing**, add your own Google account as a tester, and install from the test link.
- New personal developer accounts must run a **closed test with at least 12 testers for 14 days** before Google allows a production release. Organisation accounts do not have this rule.
- Version 1.0.0 (1). Raise the number in `mobile/pubspec.yaml` for every later upload.
- Play App Signing: accept it. Keep the upload key in `mobile/android/` and its passwords backed up.
