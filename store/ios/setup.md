# Publishing the iPhone app without a Mac

The app is built on Codemagic, which rents a Mac only for the build. The steps below are in the order they must happen. Steps 1 to 3 are the hospital's; nobody else can do them.

## 1. D-U-N-S number (free, several working days)

Apple expects a healthcare app to be published by the hospital as an organisation, not by a person. Organisations need a D-U-N-S number.

1. Check whether the hospital already has one, and request one if not, through Apple's D-U-N-S lookup on developer.apple.com.
2. Use the hospital's legal name and registered address exactly as on its registration documents.

## 2. Apple Developer Program (99 US dollars a year)

1. Create an Apple Account with a hospital email address, for example application@mallikahospitals.in, and turn on two-factor authentication.
2. Enrol at developer.apple.com/programs/enroll as an **Organization** with the D-U-N-S number.
3. Apple may phone to confirm the person enrolling can bind the hospital legally. Approval usually takes a few days.

## 3. Create the app in App Store Connect

1. Certificates, Identifiers and Profiles, Identifiers: register the App ID `com.mallikahospitals.mallikaHospitals`. No extra capabilities are needed.
2. App Store Connect, Apps, New App: platform iOS, name Mallika Hospitals, primary language English (U.S.), bundle ID as above, SKU `mallika-hospitals-ios`.
3. Users and Access, Integrations, App Store Connect API: create a key with the **App Manager** role. Download the `.p8` file once (Apple allows only one download) and note the Issuer ID and Key ID. Keep the file private; it is not stored in the repository.

## 4. Codemagic

1. Sign up at codemagic.io with the GitHub account that owns `suneel999/mallika-app`, and add the repository.
2. Team settings, Integrations, Developer Portal: add the API key from step 3 and name it exactly `codemagic`.
3. Team settings, Code signing identities: generate an Apple Distribution certificate, then fetch the App Store provisioning profile for `com.mallikahospitals.mallikaHospitals`.
4. Start the **iOS App Store** workflow. It checks the app, builds it, signs it, and uploads it to TestFlight. A tag such as `ios-v1.0.0` pushed to GitHub starts it too.

The build file is `codemagic.yaml` at the top of the repository. It has not been run yet.

## 5. Test and submit

1. TestFlight: add yourself as an internal tester and install the build on an iPhone.
2. App Store Connect, the 1.0 version: paste the text and answers from `store/ios/listing.md`, upload the six screenshots from `store/ios/screenshots/`, choose the build, and set availability to India.
3. Make sure the review login is switched on (`infra/set-review-login.ps1`), then Submit for Review.

## What is already done in the app

- iPhone only, portrait only.
- The app icon and launch screen use the hospital emblem and logo.
- `ITSAppUsesNonExemptEncryption` is false, so builds are not held for export questions.
- The app may open phone and web links (ambulance call, Maps, privacy policy).
- Account deletion is in Profile, as Apple requires.
- Sign-in is by phone and code only, so Sign in with Apple is not required.
