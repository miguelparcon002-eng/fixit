# FIXIT - Mobile Repair Service App

## What Has Been Built

I've created the complete foundation for the FIXIT app with the following components:

### ✅ Completed Components

#### 1. **Project Structure & Dependencies**
- Flutter project with all necessary packages configured
- Supabase for backend (auth, database, storage, realtime)
- Riverpod for state management
- GoRouter for navigation
- Google Maps integration (ready for API key)
- Stripe for payments (ready for API key)
- Firebase for push notifications (ready for configuration)

#### 2. **Database Schema** (`supabase_schema.sql`)
Complete PostgreSQL database with:
- **Users table** - Customer, Technician, and Admin profiles
- **Technician Profiles** - Skills, ratings, availability
- **Services** - Service catalog with pricing and details
- **Bookings** - Complete order/job management
- **Chats & Messages** - Real-time messaging
- **Verification Requests** - Technician verification workflow
- **Reviews** - Rating and review system
- **Categories** - Service categories
- **Notifications** - Push notification storage
- **Activity Logs** - Audit trail
- **Reports/Disputes** - Issue management
- **Row-Level Security (RLS)** - Complete security policies
- **Indexes** - Performance optimization
- **Triggers** - Auto-update timestamps and ratings

#### 3. **Data Models** (`lib/models/`)
- `UserModel` - User profile data
- `TechnicianProfileModel` - Technician-specific data
- `ServiceModel` - Repair service listings
- `BookingModel` - Job/order data
- `ChatModel` & `MessageModel` - Messaging
- `VerificationRequestModel` - Verification workflow
- `ReviewModel` - Ratings and reviews

#### 4. **Core Services** (`lib/services/`)
- **AuthService** - Sign up, sign in, profile management
- **BookingService** - Create, update, track bookings with real-time streams
- **ServiceService** - Manage service listings and search
- **ChatService** - Real-time messaging with read receipts
- **VerificationService** - Document upload and verification workflow
- **TechnicianService** - Technician profile and search

#### 5. **State Management** (`lib/providers/`)
- Riverpod providers for all services
- Real-time data streams for bookings and chats
- User authentication state
- Service and technician search

#### 6. **Routing** (`lib/core/routes/`)
- Complete app navigation structure
- Auth routes (login, signup, role selection)
- Main bottom navigation shell
- Booking management routes
- Chat routes
- Profile routes
- Technician-specific routes
- Admin routes

#### 7. **Theme** (`lib/core/theme/`)
- Professional blue and green color scheme
- Material Design 3
- Consistent button, card, and input styles
- Custom typography

#### 8. **Configuration** (`lib/core/`)
- Supabase configuration with realtime support
- App constants (roles, statuses, categories)
- Database table constants

### 📋 What Needs to Be Done Next

To complete the app, you need to create the UI screens. I've set up the routing structure, but the actual screen files need to be built. Here are the screens that need implementation:

#### Authentication Screens (`lib/screens/auth/`)
1. `login_screen.dart` - Email/password login
2. `signup_screen.dart` - Registration with role selection
3. `role_selection_screen.dart` - Choose Customer or Technician

#### Home & Navigation (`lib/screens/home/`)
4. `main_navigation.dart` - Bottom navigation bar wrapper
5. `home_screen.dart` - Service catalog, search, categories

#### Booking Screens (`lib/screens/booking/`)
6. `booking_list_screen.dart` - My bookings with status tabs
7. `booking_detail_screen.dart` - Booking details, tracking, payment
8. `create_booking_screen.dart` - Schedule service booking

#### Chat Screens (`lib/screens/chat/`)
9. `chat_list_screen.dart` - All conversations
10. `chat_detail_screen.dart` - Message thread with images

#### Profile Screens (`lib/screens/profile/`)
11. `profile_screen.dart` - User profile view
12. `edit_profile_screen.dart` - Edit profile information

#### Technician Screens (`lib/screens/technician/`)
13. `technician_profile_screen.dart` - Public technician profile
14. `technician_dashboard_screen.dart` - Job management dashboard
15. `service_management_screen.dart` - Add/edit services
16. `verification_submission_screen.dart` - Upload verification documents

#### Admin Screens (`lib/screens/admin/`)
17. `admin_dashboard_screen.dart` - Platform overview
18. `verification_review_screen.dart` - Approve/reject technicians

## Setup Instructions

### 1. Configure Supabase

1. Create a Supabase project at [supabase.com](https://supabase.com)
2. Run the `supabase_schema.sql` file in the SQL Editor
3. Create storage buckets:
   - `profiles` (public)
   - `documents` (private)
   - `services` (public)
   - `chats` (private)
   - `invoices` (private)

4. Get your Supabase credentials and update:
   ```dart
   // lib/core/constants/app_constants.dart
   static const String supabaseUrl = 'YOUR_PROJECT_URL';
   static const String supabaseAnonKey = 'YOUR_ANON_KEY';
   ```

### 2. Configure Google Maps

1. Get API keys from [Google Cloud Console](https://console.cloud.google.com)
2. Enable Maps SDK for Android and iOS
3. Update:
   ```dart
   // lib/core/constants/app_constants.dart
   static const String googleMapsApiKey = 'YOUR_API_KEY';
   ```

4. Add to Android manifest (`android/app/src/main/AndroidManifest.xml`):
   ```xml
   <meta-data
       android:name="com.google.android.geo.API_KEY"
       android:value="YOUR_API_KEY"/>
   ```

5. Add to iOS (`ios/Runner/AppDelegate.swift`):
   ```swift
   GMSServices.provideAPIKey("YOUR_API_KEY")
   ```

### 3. Configure Stripe

1. Get keys from [Stripe Dashboard](https://dashboard.stripe.com)
2. Update:
   ```dart
   // lib/core/constants/app_constants.dart
   static const String stripePublishableKey = 'YOUR_PUBLISHABLE_KEY';
   ```

### 4. Configure Firebase (for notifications)

1. Create Firebase project
2. Add Android and iOS apps
3. Download `google-services.json` (Android) and `GoogleService-Info.plist` (iOS)
4. Place them in the appropriate directories
5. Update:
   ```dart
   // lib/core/constants/app_constants.dart
   static const String firebaseServerKey = 'YOUR_SERVER_KEY';
   ```

### 5. Create Admin Account

1. Sign up a user in Supabase Auth with email `admin@fixit.com`
2. Get the UUID from the auth.users table
3. Run:
   ```sql
   INSERT INTO users (id, email, full_name, role, verified, created_at)
   VALUES (
       '<UUID_FROM_AUTH>',
       'admin@fixit.com',
       'Admin',
       'admin',
       TRUE,
       NOW()
   );
   ```

### 6. Run the App

```bash
flutter pub get
flutter run
```

## Architecture Overview

### State Management Pattern
- **Riverpod** providers for reactive state
- **FutureProviders** for one-time data fetching
- **StreamProviders** for real-time data (bookings, chats)
- **Services** handle all business logic and API calls

### Authentication Flow
1. User signs up and selects role (Customer/Technician)
2. Customers are auto-verified
3. Technicians must submit verification documents
4. Admin approves technicians in the admin panel
5. Verified badge appears on technician profiles

### Booking Flow
1. Customer searches/browses services
2. Customer books a service with schedule/location
3. Technician receives real-time notification
4. Technician accepts/declines
5. Real-time tracking with Google Maps
6. Payment on completion (Stripe/Cash)
7. Customer reviews the service
8. Rating updates technician profile

### Real-time Features
- New booking notifications
- Booking status updates
- Chat messages
- Technician availability changes
- All powered by Supabase Realtime

## Key Features

### For Customers
- Browse services by category
- Search by location, price, rating
- Filter by verified technicians
- Real-time booking tracking
- In-app chat with technicians
- Secure payments
- Rate and review

### For Technicians
- Create and manage service listings
- Accept/decline job requests
- Set availability and service areas
- Manage pricing and estimates
- Track earnings
- Verification process
- Professional profile with ratings

### For Admins
- Review and approve technicians
- Monitor platform activity
- Handle disputes
- View analytics
- Manage categories
- User management

## Next Steps

1. **Implement the UI screens** listed above
2. **Add Google Maps integration** for location selection and tracking
3. **Implement Stripe checkout** for payments
4. **Set up Firebase Cloud Messaging** for push notifications
5. **Add image upload** functionality for profiles and chats
6. **Build search and filter UI** for services
7. **Create real-time tracking** for in-progress bookings
8. **Add notification handlers** for booking updates
9. **Implement PDF invoice generation** using the pdf package
10. **Test all user flows** (customer, technician, admin)

## File Structure

```
lib/
├── core/
│   ├── config/
│   │   └── supabase_config.dart
│   ├── constants/
│   │   ├── app_constants.dart
│   │   └── db_constants.dart
│   ├── routes/
│   │   └── app_router.dart
│   └── theme/
│       └── app_theme.dart
├── models/
│   ├── user_model.dart
│   ├── technician_profile_model.dart
│   ├── service_model.dart
│   ├── booking_model.dart
│   ├── chat_model.dart
│   ├── verification_request_model.dart
│   └── review_model.dart
├── providers/
│   ├── auth_provider.dart
│   ├── booking_provider.dart
│   ├── service_provider.dart
│   ├── chat_provider.dart
│   ├── technician_provider.dart
│   └── verification_provider.dart
├── services/
│   ├── auth_service.dart
│   ├── booking_service.dart
│   ├── service_service.dart
│   ├── chat_service.dart
│   ├── verification_service.dart
│   └── technician_service.dart
├── screens/
│   ├── auth/
│   ├── home/
│   ├── booking/
│   ├── chat/
│   ├── profile/
│   ├── technician/
│   └── admin/
├── widgets/
│   ├── common/
│   ├── auth/
│   ├── booking/
│   └── chat/
└── main.dart
```

## Technology Stack

- **Frontend**: Flutter (Dart)
- **State Management**: Riverpod
- **Backend**: Supabase (PostgreSQL, Auth, Storage, Realtime, Edge Functions)
- **Maps**: Google Maps
- **Payments**: Stripe
- **Notifications**: Firebase Cloud Messaging
- **Navigation**: GoRouter

## Support

For issues or questions:
- Check Supabase docs: [supabase.io/docs](https://supabase.io/docs)
- Flutter docs: [flutter.dev](https://flutter.dev)
- Stripe docs: [stripe.com/docs](https://stripe.com/docs)

---

**Built with ❤️ for FIXIT**
