# FixIT - Mobile & Laptop Repair Service Platform

A full-featured Flutter application connecting customers with certified mobile phone and laptop repair technicians — with a complete admin panel, real-time features, and a verified technician marketplace.

---

## Tech Stack

- **Frontend:** Flutter (Dart)
- **Backend:** Supabase (PostgreSQL, Auth, Storage, Edge Functions, Realtime)
- **State Management:** Flutter Riverpod
- **Navigation:** GoRouter
- **Notifications:** Push notifications via Supabase + Edge Functions
- **Email:** Gmail SMTP via Nodemailer (Supabase Edge Functions)

---

## Quick Start

### 1. Install Dependencies
```bash
flutter pub get
```

### 2. Configure Supabase
1. Create a project at supabase.com
2. Run `supabase_schema.sql` in the SQL Editor
3. Create storage buckets: `profiles`, `documents`, `services`, `chats`, `invoices`
4. Update credentials in `lib/core/config/supabase_config.dart`

### 3. Run
```bash
flutter run
```

---

## Features

### Customer
- **Onboarding** — First-time walkthrough introducing the app
- **Authentication** — Email/password login and signup, Google Sign-In, role selection (customer or technician)
- **Forgot Password with OTP** — 8-digit OTP sent to email for secure password reset
- **Home Dashboard** — Browse services, featured technicians, emergency repair booking, and quick actions
- **Service Booking** — Book home-visit or shop-visit repairs, select technician, choose device, schedule appointment
- **Emergency Booking** — Priority repair request flow
- **Booking Management** — View active, pending, completed, and cancelled bookings with full details
- **Device Details** — Attach device information (brand, model, issue description) to bookings
- **Real-time Chat** — Message technicians directly within a booking
- **Payments** — In-app payment processing per booking
- **Ratings & Reviews** — Rate and review technicians after service completion
- **Vouchers & Rewards** — Redeem vouchers and earn loyalty rewards
- **Profile Management** — Edit name, photo, contact number, address with map location picker
- **Address Book** — Save and manage multiple service addresses
- **Notifications** — In-app and push notifications for booking updates
- **Notification Settings** — Granular control over notification preferences
- **Support Tickets** — Submit and track help/support tickets linked to bookings
- **Live Chat Support** — Real-time support chat with the FixIT team
- **Settings** — App preferences, privacy & security, terms and conditions

### Technician
- **Technician Dashboard** — Overview of active jobs, earnings summary, and ratings
- **Verification Submission** — Upload government ID and supporting documents for account verification
- **Read-only Mode** — Unverified technicians can browse but not accept jobs; banner with verification status shown
- **Verification Status Banner** — Shows pending/rejected/resubmit status with direct action links
- **Jobs Management** — View and manage assigned jobs (pending, in-progress, completed)
- **Earnings Tracker** — View total earnings, per-job breakdown, and payment history
- **Ratings & Reviews** — View customer ratings and feedback received
- **Service Management** — Add, edit, and manage offered repair services and specialties
- **Profile & Bio** — Manage profile photo, bio, specialties, and contact information
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
  - Allow resubmission for rejected technicians
  - Count badges per tab
  - Email notifications to technician on every action
- **User Management** — View all users (customers and technicians) with role-based filters
- **Technician Management** — Filter technicians by verification status (all / verified / unverified / suspended), view details, suspend or unsuspend accounts
- **Customer Management** — View all customers, detailed customer profile sheets, booking history
- **Earnings Management** — Platform-wide earnings overview, per-technician earnings breakdown
- **Reports & Analytics** — Business performance reports
- **Reviews Management** — Moderate customer reviews
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
└── screens/
    ├── admin/           # Admin panel screens
    ├── auth/            # Login, signup, forgot password, onboarding
    ├── booking/         # Booking creation, details, payment
    ├── chat/            # Real-time messaging
    ├── home/            # Customer home and navigation
    ├── onboarding/      # First-time user intro
    ├── profile/         # Profile, settings, support tickets
    ├── services/        # Service browsing
    └── technician/      # Technician dashboard and tools
```

---

## Supabase Edge Functions

| Function | Purpose |
|---|---|
| `send-verification-email` | Sends email to technician when admin approves, rejects, or requests resubmission — via Gmail SMTP (Nodemailer) |

---

## Roles

| Role | Access |
|---|---|
| `customer` | Home, booking, chat, profile, support |
| `technician` | Jobs, earnings, profile, verification |
| `admin` | Full platform management panel |
