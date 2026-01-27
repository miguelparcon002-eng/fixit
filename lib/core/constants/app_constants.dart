class AppConstants {
  // App Info
  static const String appName = 'FIXIT';
  static const String appVersion = '1.0.0';
  static const String appDescription = 'Mobile Phone & Laptop Repair Services';

  // Supabase Configuration
  static const String supabaseUrl = 'https://fpbkogotxqtioqlscipa.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImZwYmtvZ290eHF0aW9xbHNjaXBhIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjQ1MDk5MDAsImV4cCI6MjA4MDA4NTkwMH0.xlvuX5cXCwOjbSjf_A5BLn27Rs-s8FCBscGA9nvFjIs';

  // Firebase Configuration
 // static const String firebaseServerKey = 'YOUR_FIREBASE_SERVER_KEY';//

  // Google Maps API
  static const String googleMapsApiKey = 'AIzaSyDhKG2CuiuoW777t137IX6ZaSjyzKiAKAc';

  // Stripe Configuration
  static const String stripePublishableKey = 'pk_test_51SXLEm7dfa69KGgPlUgjwTrzgLxKIz5hlyhMqBMJfO2GGsLnumRJgCzyZCi6qww61ZKa9Z0ro6X2zuxcef5FvvoV00lnIXDsJ9';

  // Default Values
  static const double defaultSearchRadius = 10.0; // miles
  static const int maxServiceImages = 5;
  static const int maxDocuments = 5;
  static const int chatPageSize = 50;
  static const int bookingAutoTimeoutMinutes = 30;

  // Service Categories
  static const List<String> serviceCategories = [
    'Screen Repair',
    'Battery Replacement',
    'Water Damage',
    'Software Issues',
    'Data Recovery',
    'Hardware Upgrades',
    'Diagnostics',
    'Accessories',
  ];

  // User Roles
  static const String roleCustomer = 'customer';
  static const String roleTechnician = 'technician';
  static const String roleAdmin = 'admin';

  // Booking Statuses
  static const String bookingRequested = 'requested';
  static const String bookingAccepted = 'accepted';
  static const String bookingScheduled = 'scheduled';
  static const String bookingEnRoute = 'en_route';
  static const String bookingInProgress = 'in_progress';
  static const String bookingCompleted = 'completed';
  static const String bookingCancelled = 'cancelled';
  static const String bookingRefunded = 'refunded';

  // Verification Statuses
  static const String verificationPending = 'pending';
  static const String verificationApproved = 'approved';
  static const String verificationRejected = 'rejected';
  static const String verificationResubmit = 'resubmit';

  // Payment Methods
  static const String paymentCard = 'card';
  static const String paymentApplePay = 'apple_pay';
  static const String paymentGooglePay = 'google_pay';
  static const String paymentCOD = 'cod';

  // Storage Buckets
  static const String bucketProfiles = 'profiles';
  static const String bucketDocuments = 'documents';
  static const String bucketServices = 'services';
  static const String bucketChats = 'chats';
  static const String bucketInvoices = 'invoices';

  // Notification Types
  static const String notificationBookingRequest = 'booking_request';
  static const String notificationBookingUpdate = 'booking_update';
  static const String notificationVerification = 'verification_result';
  static const String notificationMessage = 'new_message';
  static const String notificationPartsAvailable = 'parts_available';
}
