import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../screens/onboarding/onboarding_screen.dart';
import '../../screens/auth/welcome_screen.dart';
import '../../screens/auth/login_screen.dart';
import '../../screens/auth/signup_screen.dart';
import '../../screens/auth/role_selection_screen.dart';
import '../../screens/home/home_screen.dart';
import '../../screens/home/main_navigation.dart';
import '../../screens/booking/booking_list_screen.dart';
import '../../screens/booking/booking_detail_screen.dart';
import '../../screens/booking/booking_device_details_screen.dart';
import '../../screens/booking/create_booking_screen.dart';
import '../../screens/chat/chat_list_screen.dart';
import '../../screens/chat/chat_detail_screen.dart';
import '../../screens/profile/profile_screen.dart';
import '../../screens/profile/edit_profile_screen.dart';
import '../../screens/profile/addresses_screen.dart';
import '../../screens/profile/payment_method_screen.dart';
import '../../screens/profile/notification_settings_screen.dart';
import '../../screens/profile/notifications_screen.dart';
import '../../screens/profile/privacy_security_screen.dart';
import '../../screens/profile/help_support_screen.dart';
import '../../screens/profile/live_chat_screen.dart';
import '../../screens/profile/settings_screen.dart';
import '../../screens/technician/technician_profile_screen.dart';
import '../../screens/technician/technician_dashboard_screen.dart';
import '../../screens/technician/service_management_screen.dart';
import '../../screens/technician/verification_submission_screen.dart';
import '../../screens/technician/tech_navigation.dart';
import '../../screens/technician/tech_home_screen.dart';
import '../../screens/technician/tech_jobs_screen_new.dart';
import '../../screens/technician/tech_earnings_screen.dart';
import '../../screens/technician/tech_ratings_screen.dart';
import '../../screens/technician/tech_profile_screen.dart';
import '../../screens/technician/tech_edit_profile_screen.dart';
import '../../screens/technician/tech_account_settings_screen.dart';
import '../../screens/technician/tech_notifications_screen.dart';
import '../../screens/technician/tech_notification_settings_screen.dart';
import '../../screens/technician/tech_help_support_screen.dart';
import '../../screens/technician/tech_terms_policies_screen.dart';
import '../../screens/admin/admin_dashboard_screen.dart';
import '../../screens/admin/verification_review_screen.dart';
import '../../screens/admin/admin_navigation.dart';
import '../../screens/admin/admin_home_screen.dart';
import '../../screens/admin/admin_appointments_screen.dart';
import '../../screens/admin/admin_technicians_screen.dart';
import '../../screens/admin/admin_reviews_screen.dart';
import '../../screens/admin/admin_reports_screen.dart';
import '../../screens/admin/admin_support_screen.dart';
import '../../screens/admin/admin_ticket_detail_screen.dart';
import '../../screens/profile/submit_support_ticket_screen.dart';
import '../../screens/profile/my_tickets_screen.dart';
import '../../screens/profile/customer_ticket_detail_screen.dart';
import '../../screens/admin/admin_customers_screen.dart';
import '../../screens/admin/admin_customer_detail_screen.dart';
import '../../screens/admin/admin_payment_settings_screen.dart';
import '../../screens/admin/admin_feedback_screen.dart';
import '../../screens/admin/admin_earnings_screen.dart';
import '../../screens/admin/admin_technician_earnings_detail_screen.dart';
import '../../screens/booking/payment_screen.dart';

class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/onboarding',
    redirect: (context, state) async {
      if (state.matchedLocation == '/onboarding') {
        final prefs = await SharedPreferences.getInstance();
        final completed = prefs.getBool('onboarding_completed') ?? false;
        if (completed) {
          return '/welcome';
        }
      }
      return null;
    },
    routes: [
      // Root fallback
      GoRoute(
        path: '/',
        redirect: (context, state) => '/home',
      ),

      // Onboarding route
      GoRoute(
        path: '/onboarding',
        name: 'onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Auth routes
      GoRoute(
        path: '/welcome',
        name: 'welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/role-selection',
        name: 'roleSelection',
        builder: (context, state) => const RoleSelectionScreen(),
      ),
      GoRoute(
        path: '/login',
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/signup',
        name: 'signup',
        builder: (context, state) => const SignupScreen(),
      ),

      // Main navigation with bottom nav
      ShellRoute(
        builder: (context, state, child) => MainNavigation(child: child),
        routes: [
          GoRoute(
            path: '/home',
            name: 'home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/bookings',
            name: 'bookings',
            builder: (context, state) => const BookingListScreen(),
          ),
          GoRoute(
            path: '/help-support',
            name: 'support',
            builder: (context, state) => const HelpSupportScreen(),
          ),
          // Keep chats accessible, but not as a bottom-nav tab
          GoRoute(
            path: '/chats',
            name: 'chats',
            builder: (context, state) => const ChatListScreen(),
          ),
          GoRoute(
            path: '/profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),

      // Booking routes
      GoRoute(
        path: '/booking/:id',
        name: 'bookingDetail',
        builder: (context, state) {
          final bookingId = state.pathParameters['id']!;
          return BookingDetailScreen(bookingId: bookingId);
        },
        routes: [
          GoRoute(
            path: 'device',
            name: 'bookingDeviceDetails',
            builder: (context, state) {
              final bookingId = state.pathParameters['id']!;
              return BookingDeviceDetailsScreen(bookingId: bookingId);
            },
          ),
        ],
      ),
      // Full-screen customer booking flow
      GoRoute(
        path: '/create-booking',
        name: 'createBooking',
        builder: (context, state) {
          final type = state.uri.queryParameters['type'];
          return CreateBookingScreen(
            serviceId: 'any',
            isEmergency: type == 'emergency',
          );
        },
      ),
      // Backwards-compatible route (if something still navigates with a serviceId)
      GoRoute(
        path: '/create-booking/:serviceId',
        name: 'createBookingWithService',
        builder: (context, state) {
          final serviceId = state.pathParameters['serviceId']!;
          return CreateBookingScreen(serviceId: serviceId);
        },
      ),

      // Chat routes
      GoRoute(
        path: '/chat/:id',
        name: 'chatDetail',
        builder: (context, state) {
          final chatId = state.pathParameters['id']!;
          return ChatDetailScreen(chatId: chatId);
        },
      ),

      // Profile routes
      GoRoute(
        path: '/edit-profile',
        name: 'editProfile',
        builder: (context, state) => const EditProfileScreen(),
      ),
      GoRoute(
        path: '/addresses',
        name: 'addresses',
        builder: (context, state) => const AddressesScreen(),
      ),
      GoRoute(
        path: '/payment-method',
        name: 'paymentMethod',
        builder: (context, state) => const PaymentMethodScreen(),
      ),
      GoRoute(
        path: '/notifications',
        name: 'notifications',
        builder: (context, state) => const NotificationsScreen(),
      ),
      GoRoute(
        path: '/notification-settings',
        name: 'notificationSettings',
        builder: (context, state) => const NotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/privacy-security',
        name: 'privacySecurity',
        builder: (context, state) => const PrivacySecurityScreen(),
      ),
      // NOTE: Help/Support is now under the MainNavigation ShellRoute at /help-support

      GoRoute(
        path: '/live-chat',
        name: 'liveChat',
        builder: (context, state) => const LiveChatScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),

      // Technician navigation with bottom nav
      ShellRoute(
        builder: (context, state, child) => TechNavigation(child: child),
        routes: [
          GoRoute(
            path: '/tech-home',
            name: 'techHome',
            builder: (context, state) => const TechHomeScreen(),
          ),
          GoRoute(
            path: '/tech-jobs',
            name: 'techJobs',
            builder: (context, state) => const TechJobsScreenNew(),
          ),
          GoRoute(
            path: '/tech-earnings',
            name: 'techEarnings',
            builder: (context, state) => const TechEarningsScreen(),
          ),
          GoRoute(
            path: '/tech-profile',
            name: 'techProfile',
            builder: (context, state) => const TechProfileScreen(),
          ),
          // Full page ratings inside technician navigation
          GoRoute(
            path: '/tech-ratings',
            name: 'techRatings',
            builder: (context, state) => const TechRatingsScreen(),
          ),
        ],
      ),

      // Admin navigation with bottom nav
      ShellRoute(
        builder: (context, state, child) => AdminNavigation(child: child),
        routes: [
          GoRoute(
            path: '/admin-home',
            name: 'adminHome',
            builder: (context, state) => const AdminHomeScreen(),
          ),
          GoRoute(
            path: '/admin-appointments',
            name: 'adminAppointments',
            builder: (context, state) {
              final range = state.uri.queryParameters['range'];
              final status = state.uri.queryParameters['status'];
              return AdminAppointmentsScreen(
                initialRange: range,
                initialStatus: status,
              );
            },
          ),
          GoRoute(
            path: '/admin-technicians',
            name: 'adminTechnicians',
            builder: (context, state) => const AdminTechniciansScreen(),
          ),
          GoRoute(
            path: '/admin-reviews',
            name: 'adminReviews',
            builder: (context, state) => const AdminReviewsScreen(),
          ),
          GoRoute(
            path: '/admin-earnings',
            name: 'adminEarnings',
            builder: (context, state) => const AdminEarningsScreen(),
          ),
          GoRoute(
            path: '/admin-reports',
            name: 'adminReports',
            builder: (context, state) => const AdminReportsScreen(),
          ),
        ],
      ),

      // Technician routes
      GoRoute(
        path: '/tech-edit-profile',
        name: 'techEditProfile',
        builder: (context, state) => const TechEditProfileScreen(),
      ),
      GoRoute(
        path: '/tech-account-settings',
        name: 'techAccountSettings',
        builder: (context, state) => const TechAccountSettingsScreen(),
      ),
      GoRoute(
        path: '/tech-notifications',
        name: 'techNotifications',
        builder: (context, state) => const TechNotificationsScreen(),
      ),
      GoRoute(
        path: '/tech-notification-settings',
        name: 'techNotificationSettings',
        builder: (context, state) => const TechNotificationSettingsScreen(),
      ),
      GoRoute(
        path: '/tech-help-support',
        name: 'techHelpSupport',
        builder: (context, state) => const TechHelpSupportScreen(),
      ),
      GoRoute(
        path: '/tech-terms-policies',
        name: 'techTermsPolicies',
        builder: (context, state) => const TechTermsPoliciesScreen(),
      ),
      GoRoute(
        path: '/technician-profile/:id',
        name: 'technicianProfile',
        builder: (context, state) {
          final technicianId = state.pathParameters['id']!;
          return TechnicianProfileScreen(technicianId: technicianId);
        },
      ),
      GoRoute(
        path: '/technician-dashboard',
        name: 'technicianDashboard',
        builder: (context, state) => const TechnicianDashboardScreen(),
      ),
      GoRoute(
        path: '/service-management',
        name: 'serviceManagement',
        builder: (context, state) => const ServiceManagementScreen(),
      ),
      GoRoute(
        path: '/verification-submission',
        name: 'verificationSubmission',
        builder: (context, state) => const VerificationSubmissionScreen(),
      ),

      // Admin routes
      GoRoute(
        path: '/admin',
        name: 'adminDashboard',
        builder: (context, state) => const AdminDashboardScreen(),
      ),
      GoRoute(
        path: '/verification-review',
        name: 'verificationReview',
        builder: (context, state) => const VerificationReviewScreen(),
      ),
      GoRoute(
        path: '/admin-support',
        name: 'adminSupport',
        builder: (context, state) => const AdminSupportScreen(),
      ),
      GoRoute(
        path: '/admin-support/:ticketId',
        name: 'adminTicketDetail',
        builder: (context, state) {
          final ticketId = state.pathParameters['ticketId']!;
          return AdminTicketDetailScreen(ticketId: ticketId);
        },
      ),

      // Customer Support routes
      GoRoute(
        path: '/submit-ticket',
        name: 'submitTicket',
        builder: (context, state) => const SubmitSupportTicketScreen(),
      ),
      GoRoute(
        path: '/submit-ticket/:bookingId',
        name: 'submitTicketWithBooking',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId'];
          return SubmitSupportTicketScreen(bookingId: bookingId);
        },
      ),

      // Customer Ticket routes
      GoRoute(
        path: '/my-tickets',
        name: 'myTickets',
        builder: (context, state) => const MyTicketsScreen(),
      ),
      GoRoute(
        path: '/my-tickets/:ticketId',
        name: 'customerTicketDetail',
        builder: (context, state) {
          final ticketId = state.pathParameters['ticketId']!;
          return CustomerTicketDetailScreen(ticketId: ticketId);
        },
      ),

      // Payment route
      GoRoute(
        path: '/payment/:bookingId',
        name: 'payment',
        builder: (context, state) {
          final bookingId = state.pathParameters['bookingId']!;
          final amount = double.tryParse(
                  state.uri.queryParameters['amount'] ?? '') ??
              0.0;
          return PaymentScreen(bookingId: bookingId, amount: amount);
        },
      ),

      // Admin Payment Settings
      GoRoute(
        path: '/admin-payment-settings',
        name: 'adminPaymentSettings',
        builder: (context, state) => const AdminPaymentSettingsScreen(),
      ),

      // Admin Feedback & Bug Reports
      GoRoute(
        path: '/admin-feedback',
        name: 'adminFeedback',
        builder: (context, state) => const AdminFeedbackScreen(),
      ),

      // Admin Earnings Management routes
      GoRoute(
        path: '/admin-technician-earnings/:technicianId',
        name: 'adminTechnicianEarnings',
        builder: (context, state) {
          final technicianId = state.pathParameters['technicianId']!;
          return AdminTechnicianEarningsDetailScreen(technicianId: technicianId);
        },
      ),

      // Admin Customer Management routes
      GoRoute(
        path: '/admin-customers',
        name: 'adminCustomers',
        builder: (context, state) => const AdminCustomersScreen(),
      ),
      GoRoute(
        path: '/admin-customer/:customerId',
        name: 'adminCustomerDetail',
        builder: (context, state) {
          final customerId = state.pathParameters['customerId']!;
          return AdminCustomerDetailScreen(customerId: customerId);
        },
      ),
    ],
  );
}
