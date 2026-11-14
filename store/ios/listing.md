# App Store listing for Mallika Hospitals

Text and answers to copy into App Store Connect. Items in [brackets] are the hospital's to supply.

## Files

| What App Store Connect asks for | File |
| --- | --- |
| iPhone 6.7-inch screenshots, 1290 x 2796 | `store/ios/screenshots/` (six files, in order) |
| App icon | Comes from the build. No upload needed. |

The screenshots use a made-up patient name. The doctor's name and photo are real. Apple scales these screenshots down for smaller iPhones, so no other size is needed. The app is iPhone only, so no iPad screenshots are needed.

## App information

| Field | Value |
| --- | --- |
| Name (30 characters at most) | Mallika Hospitals |
| Subtitle (30 characters at most) | Book consultations and scans |
| Bundle ID | com.mallikahospitals.mallikaHospitals |
| SKU | mallika-hospitals-ios |
| Primary language | English (U.S.) |
| Primary category | Medical |
| Secondary category | Health & Fitness |
| Content rights | No third-party content |
| Price | Free |
| Availability | India only |

## Version 1.0

**Promotional text** (170 characters at most)

Request a consultation with our senior cardiologist, or a 4D Echo, CT Calcium or CT Angio scan, from your phone.

**Description**

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
• Open directions to the hospital in Maps.

Good to know
• A booking is a request. It is confirmed when the hospital confirms it.
• You pay at the hospital. The app takes no payment.
• You can delete your account from the Profile screen at any time.

**Keywords** (100 characters at most, comma separated)

hospital,cardiologist,heart,echo,CT scan,appointment,doctor,consultation,Mallika,booking

**Support URL:** https://mallikahospitals.in
**Marketing URL:** leave empty
**Privacy policy URL:** https://mallikahospitals.in/privacy-policy/
**Copyright:** 2026 [legal name of the hospital]
**Version:** 1.0.0

## App Review information

**Sign-in required:** Yes.

- User name: the review mobile number set with `infra/set-review-login.ps1`
- Password: the 6-digit review code set with the same script

**Notes**

The app signs in with a mobile number and a one-time code sent on WhatsApp. For review, use the number and code above: enter the number, tap Login, then enter the code. No WhatsApp message is sent for this number.

A booking is a request to the hospital. Reception staff review it and confirm a time; the app takes no payment. Account deletion is in Profile, Delete Account.

**Contact:** [first and last name], application@mallikahospitals.in, +91 96741 08108

## Age rating

Answer None or No to every question, including Medical or Treatment Information: the app books appointments and gives no medical advice. There is no user-generated content, no web browsing, no gambling, and no messaging between users. Expected rating: 4+.

## App Privacy

**Does this app collect data?** Yes.

**Tracking:** No. The app does not track users across other companies' apps or websites, and has no advertising.

| Data type | Linked to the user | Used for tracking | Purpose |
| --- | --- | --- | --- |
| Contact Info: Name | Yes | No | App Functionality |
| Contact Info: Phone Number | Yes | No | App Functionality |
| Health and Fitness: Health (appointment requests and the note to the hospital) | Yes | No | App Functionality |
| Identifiers: User ID | Yes | No | App Functionality |

Not collected: location, financial info, contacts, user content such as photos, browsing history, search history, usage data, diagnostics, purchases, sensitive info.

## Export compliance

The app uses only standard HTTPS encryption. `ITSAppUsesNonExemptEncryption` is set to false in the app, so App Store Connect does not ask on each build.
