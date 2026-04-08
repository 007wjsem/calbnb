# CalBNB – Short-Term Rental Property Management & Cleaning Analytics

CalBNB is a comprehensive, multi-tenant Flutter application designed to automate property management operations. It bridges the gap between Airbnb reservations, cleaning schedules, team communication, and financial tracking into one localized platform.

---

## 🚀 Key Benefits & Features

*   **Zero-Input Calendar Sync**: Directly plugs into Airbnb via iCal. Uses Google Apps Script and Cloudflare Workers to structure and patch bookings into Firebase Realtime Database without duplicating entries.
*   **Automated Scheduling**: Automatically turns Check-Out events into actionable cleaning assignments for your staff.
*   **Custom Financial Tracking**: Generates live statements calculating cleaner earnings and aggregate property cleaning fees, all utilizing dynamic local currencies ($, S/, etc.).
*   **Real-time Team Inbox**: Integrated channel-based chat to separate Cleaner, Inspector, and general company communications, as well as Direct Messaging.
*   **Photo Evidence Workflows**: Forces accountability by letting Cleaners upload photos of completed rooms directly to Firebase Storage for Inspectors to review.
*   **Multi-Company Architecture**: Users can jump between different properties and distinct local companies without logging out.

---

## 👤 User Roles & Capabilities

The application employs a strict Role-Based Access Control (RBAC) system. What you see on your dashboard depends entirely on your assigned role:

### 1. Cleaner (Deep Dive)
The **Cleaner** is the backbone of the application. The Cleaner UI is specifically designed to be distraction-free and highly action-oriented.
*   **What they see**: A customized `Cleaner Dashboard` showing only *their* explicitly assigned cleaning jobs, split into "In Progress" and "Upcoming/Remaining Jobs". 
*   **Capabilities & Options**:
    *   **Start/Stop Tasks**: Tap a button to mark a cleaning job as "In Progress".
    *   **Property Information Access**: View the specific address, lockbox PINs, and customized cleaning instructions for the property they are cleaning.
    *   **Checklist Execution**: Check off specific required tasks (e.g., "Empty all trash", "Restock toilet paper") defined by the Admin.
    *   **Upload Photo Evidence**: Use their phone's camera to take mandatory photos of the cleaned property and upload them directly to the task.
    *   **Report Incidents**: Log maintenance issues (e.g., "Broken Lamp", "Pets present") directly into the shift report.
    *   **Track Earnings**: Access the "My Earnings" screen to view tracked payroll based on the jobs they have completed this month.

### 2. Inspector
*   **What they see**: An overseeing dashboard of all active and recently completed cleanings.
*   **Capabilities**: Review the photo evidence uploaded by cleaners. They can either mark the cleaning as **Approved** or bounce it back as **Fix Needed**, instantly notifying the cleaner that something was missed. 

### 3. Manager
*   **Capabilities**: Operates the day-to-day. Can view the full company calendar, assign specific cleaners to upcoming checkouts, read/write in all team inbox channels, and manage general property settings (excluding financial/payroll data).

### 4. Admin (Company Owner)
*   **Capabilities**: Has absolute authority over a specific company. Can invite new users, set cleaning fees, view all financial/payroll reports, and manage the company's subscription plan. 

### 5. Host / Linked Owner
*   **Capabilities**: A specialized read-only role. Property owners can be linked to their specific building. When they log in, they bypass the team messaging and tasks, landing instead on a customized dashboard showing *only* their property's booking calendar and financial statements.

### 6. Super Admin
*   **Capabilities**: Global application control. Can manage the subscription statuses of *all* companies in the database, bypass tier restrictions, and alter global app configurations.

---

## 💳 Subscription Tiers & Pricing

The application operates on a robust SaaS model using `SubscriptionGuard` to restrict access to features based on the active company's paid tier.

> 📄 For a complete feature-by-feature breakdown of each tier, see **[TIERS.md](TIERS.md)**.

| Tier | Base Price (USD/mo) | Included Properties | Overage Rate (per extra prop) | Max User Seats | Benefits & Differences |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Free** | $0.00 | 2 | Not Allowed (Null) | 1 | Best for single hosts starting out. Gives you the calendar sync and basic property features. You cannot invite external cleaners or managers. |
| **Bronze** | $9.99 | 5 | $2.00 | 4 | Best for small operators. Unlocks the ability to invite up to 3 external cleaners to start automating daily schedules. Allows cheap overage properties. |
| **Silver** | $29.99 | 15 | $1.50 | 10 | Unlocks **Advanced Scheduling Settings** (Recurring clean cadences) and allows mid-sized teams to collaborate with Inspectors. |
| **Gold** | $69.99 | 30 | $1.25 | 18 | Scaled for regional management companies. Drastically lowers the overage rate for properties and offers substantial user seats. |
| **Platinum**| $199.99 | 60 | $1.00 | 39 | Enterprise tier for massive property portfolios. |
| **Diamond** | $299.99 | 100 | $0.75 | 106 | The ultimate tier for large-scale operations. Lowest overage rate for aggressively growing businesses. |

---

## 💻 Getting Started: Deployment & Execution

Because CalBNB is built on Flutter, it can be compiled natively for almost any screen.

### Prerequisites
1.  Install the [Flutter SDK](https://docs.flutter.dev/get-started/install).
2.  Install Android Studio (for Android emulation) and Xcode (for macOS/iOS compilation).
3.  Ensure your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) from Firebase are placed in their respective `android/app` and `ios/Runner` directories.

### Project Setup
Open your terminal at the project root and run:
```bash
flutter clean
flutter pub get
flutter gen-l10n   # Compiles your English/Spanish translation files
```

### Running the App Locally

**For Mobile Emulators (iOS / Android):**
```bash
flutter run
# If multiple devices are connected, it will prompt you to select one.
```

**For Google Chrome (Web App):**
```bash
flutter run -d chrome
```

**For macOS (Desktop App):**
Ensure you have enabled macOS desktop support in your Flutter config:
```bash
flutter config --enable-macos-desktop
flutter run -d macos
```

### Deployment

**Deploying to Web:**
Build the optimized web bundle:
```bash
flutter build web --release
# The resulting files will be inside build/web/. You can deploy this folder directly to Firebase Hosting using the Firebase CLI.
firebase deploy --only hosting
```

**Deploying to Android (Google Play):**
Build an App Bundle:
```bash
flutter build appbundle --release
# Locate the generated .aab file in build/app/outputs/bundle/release/ and upload it to the Google Play Console.
```

**Deploying to iOS (App Store):**
Build the iOS archive:
```bash
flutter build ipa --release
# This will generate an .xcarchive and an .ipa file. Use Apple's Transporter app to upload the .ipa directly to App Store Connect.
```
