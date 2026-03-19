# FixIt — Mobile & Laptop Repair Service Platform

A full-featured Flutter application connecting customers with certified mobile phone and laptop repair technicians — with a complete admin panel, real-time push notifications, verified technician marketplace, and analytics.

**Version:** 1.0.0 | **Platform:** Android, Web

---

## Tech Stack

| Layer | Technology |
|---|---|
| **Framework** | Flutter 3.x (Dart SDK ^3.10.1) |
| **Backend** | Supabase (PostgreSQL, Auth, Storage, Edge Functions, Realtime) |
| **State Management** | Flutter Riverpod ^2.6.1 |
| **Navigation** | GoRouter ^14.6.2 |
| **Push Notifications** | Firebase Cloud Messaging (FCM) + Supabase Edge Functions |
| **Local Notifications** | flutter_local_notifications ^18.0.1 |
| **Authentication** | Supabase Auth + Google Sign-In |
| **Maps** | OpenStreetMap via flutter_map (no API key required) |
| **Payments** | Stripe (flutter_stripe ^11.2.0) |
| **Email** | Gmail SMTP via Nodemailer (Supabase Edge Function) |
| **Local Storage** | Hive + shared_preferences |
| **PDF Generation** | pdf + printing packages |
| **CSV Export** | Platform-aware (dart:html on web, share_plus on Android) |

---

## Quick Start

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Configure Supabase
1. Create a project at [supabase.com](https://supabase.com)
2. Run `supabase_schema.sql` in the SQL Editor
3. Create storage buckets: `profiles`, `documents`, `services`, `chats`, `invoices`
4. Update credentials in `lib/core/config/supabase_config.dart`

### 3. Configure Firebase (for Push Notifications)
1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add an Android app with package name `com.example.fixit`
3. Get your debug SHA-1 fingerprint:
   ```powershell
   # Windows (using Android Studio JDK)
   & "C:\Program Files\Android\Android Studio\jbr\bin\keytool.exe" -list -v -keystore "$env:USERPROFILE\.android\debug.keystore" -alias androiddebugkey -storepass android -keypass android
   ```
4. Add the SHA-1 fingerprint in Firebase → Project Settings → Your apps → Add fingerprint
5. Download `google-services.json` and place it at `android/app/google-services.json`
6. In Supabase Dashboard → Edge Functions → Secrets, add:
   - `FIREBASE_PROJECT_ID`
   - `FIREBASE_PRIVATE_KEY`
   - `FIREBASE_CLIENT_EMAIL`

### 4. Deploy Edge Functions
```bash
supabase functions deploy send-push-notification
supabase functions deploy send-verification-email
```

### 5. Run
```bash
# Android
flutter run

# Web (Chrome)
flutter run -d chrome
```

---

## Features

### Customer
- **Onboarding** — First-time walkthrough introducing the app
- **Authentication** — Email/password login and signup, Google Sign-In, role selection (customer or technician)
- **Forgot Password with OTP** — 8-digit OTP sent to email for secure password reset
- **Home Dashboard** — Browse services, featured technicians, emergency repair booking, and quick actions
- **Service Booking** — Book home-visit or shop-visit repairs, select technician with real ratings, choose device, schedule appointment
- **Technician Selection** — View technician cards with accurate live ratings and reviews pulled from `app_ratings` table; tap to read full review history before booking
- **Emergency Booking** — Priority repair request flow
- **Booking Management** — View active, pending, completed, and cancelled bookings; pull-to-refresh and manual refresh button
- **Device Details** — Attach device information (brand, model, issue description) to bookings
- **Real-time Chat** — Message technicians directly within a booking
- **Payments** — In-app Stripe payment processing per booking
- **Ratings & Reviews** — Rate and review technicians after service completion; rating saved with `technician_id` UUID for accurate attribution
- **Vouchers & Rewards** — Redeem vouchers and earn loyalty rewards
- **Profile Management** — Edit name, photo, contact number, address with map location picker
- **Address Book** — Save and manage multiple service addresses
- **Push Notifications** — Background and foreground push notifications via FCM for booking updates
- **Notification Settings** — Granular control over notification preferences
- **Support Tickets** — Submit and track help/support tickets linked to bookings
- **Live Chat Support** — Real-time support chat with the FixIt team
- **Settings** — App preferences, privacy & security, terms and conditions

### Technician
- **Technician Dashboard** — Overview of active jobs, real-time earnings summary, and accurate ratings (UUID-based + legacy name-matched)
- **Verification Submission** — Upload government ID and supporting documents for account verification; bio and specialties submitted here auto-populate the technician profile upon approval
- **Read-only Mode** — Unverified technicians can browse but not accept jobs; status banner shown
- **Verification Status Banner** — Shows pending/rejected/resubmit status with direct action links
- **Jobs Management** — View and manage assigned jobs (pending, in-progress, completed)
- **Earnings Tracker** — View total earnings calculated from completed bookings, per-job breakdown
- **Ratings & Reviews** — View all customer ratings and feedback; correct count and average combining UUID-keyed and legacy name-matched rows; no duplicates
- **Service Management** — Add, edit, and manage offered repair services and specialties
- **Profile & Bio** — Manage profile photo, bio (auto-filled from verified submission), specialties, and contact information
- **Notification Settings** — Control job and update notifications
- **Account Settings** — Manage password, linked accounts, and preferences
- **Help & Support** — Access support resources and contact admin
- **Terms & Policies** — In-app terms of service and privacy policy

### Admin
- **Admin Dashboard** — Real-time stats: total bookings, active technicians, customers, revenue, bookings today
- **Appointments Management** — View, filter, and manage all bookings across the platform by date range and status
- **Technician Verification Review** — Multi-tab review screen (Pending / Resubmit / Rejected / Approved) with:
  - View submitted ID and documents
  - Approve, reject, or request resubmission with notes
  - Real-time polling for new pending verifications (updates every 5 seconds)
  - Count badges per tab
  - Email notifications to technician on every action
  - Auto-populates bio and specialties to technician profile on approval
- **User Management** — View all users (customers and technicians) with role-based filters
- **Technician Management** — Filter technicians by verification status (all / verified / unverified / suspended), view details, suspend or unsuspend accounts
- **Customer Management** — View all customers, detailed customer profile sheets, booking history
- **Earnings Management** — Platform-wide earnings overview, per-technician earnings breakdown
- **Reports & Analytics** — Business performance dashboard with:
  - Period filter (Today / Week / Month / All Time)
  - Overview metrics, device breakdown, popular areas, team performance
  - CSV export (downloads file directly on web; share sheet on Android)
- **Reviews Management** — Modern review moderation screen with:
  - Gradient stats header (average rating, total reviews, technician count)
  - Search by customer name, technician, or review text
  - Technician dropdown filter with per-technician avg rating
  - Star rating chips (All / 5★ / 4★ / 3★ / 2★ / 1★) with count badges
  - Sort by Newest / Oldest / Top Rated / Low Rated
  - Active filter banner with "Clear all"
- **Feedback & Bug Reports** — View user-submitted feedback
- **Support Ticket Management** — View, respond to, and resolve customer support tickets
- **Payment Settings** — Configure platform payment rates and commission
- **Admin Notifications** — In-app notification center for admin alerts

### Security & Account Safety
- **Suspended Account Blocking** — Suspended accounts are blocked at login and at the router level; shown a clear message
- **OTP Password Reset** — Forgot password uses a Supabase-generated OTP (not a magic link) for secure recovery
- **RLS Policies** — Row-Level Security enforced on all Supabase tables
- **Verification Gating** — Unverified technicians cannot perform write actions; enforced at the service layer
- **Rejection Lock** — Rejected technicians cannot resubmit unless admin explicitly allows it
- **UUID-based Rating Attribution** — Ratings are linked to technicians via UUID (`technician_id`), with name-matching fallback for legacy rows

---

## Project Structure

```
lib/
├── core/
│   ├── config/          # Supabase configuration
│   ├── constants/       # App-wide constants and DB column names
│   ├── routes/          # GoRouter setup with redirect guards
│   ├── theme/           # App colors, typography, theme
│   └── utils/           # Logger and utilities
├── models/              # Data models (User, Booking, Technician, etc.)
├── providers/           # Riverpod providers
├── services/            # Business logic and Supabase API calls
├── utils/               # Platform helpers (export_helper for CSV)
└── screens/
    ├── admin/           # Admin panel screens + widgets
    ├── auth/            # Login, signup, forgot password, onboarding, terms, privacy
    ├── booking/         # Booking creation, list, detail, payment, device details
    ├── chat/            # Real-time messaging
    ├── home/            # Customer home, navigation, profile setup dialog
    ├── onboarding/      # First-time user intro
    ├── profile/         # Profile, settings, support tickets, live chat, rewards
    ├── services/        # Service browsing
    └── technician/      # Technician dashboard, jobs, earnings, ratings, profile
```

---

## Supabase Edge Functions

| Function | Purpose |
|---|---|
| `send-verification-email` | Sends email to technician when admin approves, rejects, or requests resubmission — via Gmail SMTP (Nodemailer) |
| `send-push-notification` | Sends FCM push notification to device token — triggered on booking status changes |

---

## Key Database Tables

| Table | Purpose |
|---|---|
| `users` | All users (customers, technicians, admin) with role, bio, FCM token |
| `bookings` | All service bookings with status, costs, assigned technician |
| `app_ratings` | Customer reviews — linked via `technician_id` UUID + legacy `technician` name field |
| `app_technician_stats` | Cached technician stats (rating avg, job count, earnings) — auto-updated |
| `verification_requests` | Technician verification submissions with document URLs |
| `technician_profiles` | Technician-specific profile data (bio, specialties array) |
| `technician_specialties` | Per-technician specialty records (normalized) |
| `support_tickets` | Customer help/support requests |
| `feedback` | User-submitted feedback and bug reports |

---

## Platforms

| Platform | Status |
|---|---|
| Android | Fully supported (min SDK 21) |
| Web (Chrome) | Supported |
| iOS | Not configured (requires macOS + Xcode + Apple Developer account) |
| Windows / Linux / macOS desktop | Not targeted |

---

## Roles

| Role | Access |
|---|---|
| `customer` | Home, booking, chat, profile, support |
| `technician` | Jobs, earnings, profile, verification |
| `admin` | Full platform management panel |
