import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../models/booking_model.dart';
import '../models/customer_model.dart';
import '../services/booking_service.dart';
import '../services/storage_service.dart';
import 'auth_provider.dart';
import 'earnings_provider.dart';
import 'customer_provider.dart';
import 'rewards_provider.dart';

final bookingServiceProvider = Provider((ref) => BookingService());

final customerBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final bookingService = ref.watch(bookingServiceProvider);
  final user = ref.watch(currentUserProvider).value;

  if (user == null) return Stream.value([]);

  return bookingService.watchCustomerBookings(user.id);
});

final technicianBookingsProvider = StreamProvider<List<BookingModel>>((ref) {
  final bookingService = ref.watch(bookingServiceProvider);
  final user = ref.watch(currentUserProvider).value;

  if (user == null) return Stream.value([]);

  return bookingService.watchTechnicianBookings(user.id);
});

class BookingsByStatusParams {
  final String status;
  final bool isTechnician;

  BookingsByStatusParams({required this.status, required this.isTechnician});
}

final bookingsByStatusProvider = FutureProvider.family<List<BookingModel>, BookingsByStatusParams>((ref, params) async {
  final bookingService = ref.watch(bookingServiceProvider);
  final user = await ref.watch(currentUserProvider.future);

  if (user == null) return [];

  return await bookingService.getBookingsByStatus(
    userId: user.id,
    status: params.status,
    isTechnician: params.isTechnician,
  );
});

// Simple local booking for demo purposes
class LocalBooking {
  final String id;
  final String icon;
  final String status;
  final String deviceName;
  final String serviceName;
  final String date;
  final String time;
  final String location;
  final String technician;
  final String total;
  final String customerName;
  final String customerPhone;
  final String priority;
  final String? moreDetails;
  final String? technicianNotes;
  final String? promoCode;
  final String? discountAmount;
  final String? originalPrice;

  LocalBooking({
    required this.id,
    required this.icon,
    required this.status,
    required this.deviceName,
    required this.serviceName,
    required this.date,
    required this.time,
    required this.location,
    required this.technician,
    required this.total,
    required this.customerName,
    required this.customerPhone,
    required this.priority,
    this.moreDetails,
    this.technicianNotes,
    this.promoCode,
    this.discountAmount,
    this.originalPrice,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'icon': icon,
    'status': status,
    'deviceName': deviceName,
    'serviceName': serviceName,
    'date': date,
    'time': time,
    'location': location,
    'technician': technician,
    'total': total,
    'customerName': customerName,
    'customerPhone': customerPhone,
    'priority': priority,
    'moreDetails': moreDetails,
    'technicianNotes': technicianNotes,
    'promoCode': promoCode,
    'discountAmount': discountAmount,
    'originalPrice': originalPrice,
  };

  factory LocalBooking.fromJson(Map<String, dynamic> json) => LocalBooking(
    id: json['id'] as String,
    icon: json['icon'] as String,
    status: json['status'] as String,
    deviceName: json['deviceName'] as String,
    serviceName: json['serviceName'] as String,
    date: json['date'] as String,
    time: json['time'] as String,
    location: json['location'] as String,
    technician: json['technician'] as String,
    total: json['total'] as String,
    customerName: json['customerName'] as String,
    customerPhone: json['customerPhone'] as String,
    priority: json['priority'] as String,
    moreDetails: json['moreDetails'] as String?,
    technicianNotes: json['technicianNotes'] as String?,
    promoCode: json['promoCode'] as String?,
    discountAmount: json['discountAmount'] as String?,
    originalPrice: json['originalPrice'] as String?,
  );
}

class LocalBookingNotifier extends StateNotifier<List<LocalBooking>> {
  final Ref _ref;
  bool _isInitialized = false;

  LocalBookingNotifier(this._ref) : super([]) {
    _loadBookings();
  }

  Future<void> _loadBookings() async {
    // Already initialized - no need to reload unless explicitly called
    if (_isInitialized) return;

    try {
      print('LocalBookingNotifier: Loading GLOBAL bookings...');
      // Use global bookings storage so all users (customers and technicians) can see all bookings
      final bookingsData = await StorageService.loadGlobalBookings();

      if (bookingsData != null && bookingsData.isNotEmpty) {
        final List<dynamic> decoded = json.decode(bookingsData);
        state = decoded.map((item) => LocalBooking.fromJson(item)).toList();
        print('LocalBookingNotifier: Loaded ${state.length} bookings successfully');

        // Sync existing bookings to customers
        await _syncExistingBookingsToCustomers();
      } else {
        print('LocalBookingNotifier: No bookings found in global storage');
        state = [];
      }
      _isInitialized = true;
    } catch (e, stackTrace) {
      print('LocalBookingNotifier: Error loading bookings - $e');
      print('Stack trace: $stackTrace');
      _isInitialized = true;
    }
  }

  Future<void> _syncExistingBookingsToCustomers() async {
    try {
      final customersNotifier = _ref.read(customersProvider.notifier);
      final currentCustomers = _ref.read(customersProvider).value ?? [];

      // Group bookings by customer
      final Map<String, List<LocalBooking>> bookingsByCustomer = {};
      for (final booking in state) {
        final customerId = 'cust_${booking.customerName.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '')}';
        bookingsByCustomer.putIfAbsent(customerId, () => []);
        bookingsByCustomer[customerId]!.add(booking);
      }

      // Create/update customers for each group
      for (final entry in bookingsByCustomer.entries) {
        final customerId = entry.key;
        final bookings = entry.value;
        final firstBooking = bookings.first;

        // Check if customer exists
        final existingCustomer = currentCustomers.where((c) => c.id == customerId).firstOrNull;

        // Calculate stats from bookings
        int completedCount = 0;
        int cancelledCount = 0;
        double totalSpent = 0.0;

        for (final b in bookings) {
          final status = b.status.toLowerCase();
          if (status == 'completed') {
            completedCount++;
            final amountStr = b.total.replaceAll('₱', '').replaceAll(',', '').trim();
            totalSpent += double.tryParse(amountStr) ?? 0.0;
          } else if (status == 'cancelled') {
            cancelledCount++;
          }
        }

        if (existingCustomer == null) {
          // Create new customer
          final newCustomer = CustomerModel(
            id: customerId,
            name: firstBooking.customerName,
            email: '${firstBooking.customerName.toLowerCase().replaceAll(' ', '.')}@email.com',
            phone: firstBooking.customerPhone != 'No phone' ? firstBooking.customerPhone : null,
            status: CustomerStatus.active,
            createdAt: DateTime.now().subtract(Duration(days: bookings.length * 7)),
            lastActiveAt: DateTime.now(),
            totalBookings: bookings.length,
            completedBookings: completedCount,
            cancelledBookings: cancelledCount,
            totalSpent: totalSpent,
            addresses: firstBooking.location.isNotEmpty ? [firstBooking.location] : [],
          );
          await customersNotifier.addCustomer(newCustomer);
          print('Created new customer: $customerId');
        }

        // Always sync booking history (check if already exists)
        final existingHistory = await customersNotifier.getCustomerBookingHistory(customerId);
        final existingBookingIds = existingHistory.map((h) => h.bookingId).toSet();

        // Force sync if history is empty but there are bookings
        final shouldForceSync = existingHistory.isEmpty && bookings.isNotEmpty;

        for (final booking in bookings) {
          // Add if not already in history or force sync
          if (shouldForceSync || !existingBookingIds.contains(booking.id)) {
            final amountStr = booking.total.replaceAll('₱', '').replaceAll(',', '').trim();
            final amount = double.tryParse(amountStr) ?? 0.0;

            final bookingHistory = CustomerBookingHistory(
              bookingId: booking.id,
              serviceName: '${booking.deviceName} - ${booking.serviceName}',
              technicianName: booking.technician,
              bookingDate: _parseBookingDate(booking.date),
              status: booking.status.toLowerCase().replaceAll(' ', '_'),
              amount: amount,
            );
            await customersNotifier.addBookingToHistory(customerId, bookingHistory);
            print('Added booking ${booking.id} to history for $customerId');
          }
        }

        print('Synced customer bookings: $customerId (${bookings.length} bookings)');
      }
    } catch (e) {
      print('Error syncing existing bookings to customers: $e');
    }
  }

  DateTime _parseBookingDate(String dateStr) {
    try {
      // Try to parse "MMM dd, yyyy" format (e.g., "Jan 15, 2026")
      final months = {
        'Jan': 1, 'Feb': 2, 'Mar': 3, 'Apr': 4, 'May': 5, 'Jun': 6,
        'Jul': 7, 'Aug': 8, 'Sep': 9, 'Oct': 10, 'Nov': 11, 'Dec': 12
      };
      final parts = dateStr.replaceAll(',', '').split(' ');
      if (parts.length >= 3) {
        final month = months[parts[0]] ?? 1;
        final day = int.tryParse(parts[1]) ?? 1;
        final year = int.tryParse(parts[2]) ?? DateTime.now().year;
        return DateTime(year, month, day);
      }
    } catch (e) {
      print('Error parsing date: $e');
    }
    return DateTime.now();
  }

  Future<void> _saveBookings() async {
    try {
      final bookingsJson = json.encode(state.map((b) => b.toJson()).toList());
      // Save to global storage so all users can access bookings
      await StorageService.saveGlobalBookings(bookingsJson);
      print('LocalBookingNotifier: Saved ${state.length} bookings to global storage');
    } catch (e) {
      print('LocalBookingNotifier: Error saving bookings - $e');
    }
  }

  // Force reload from storage
  Future<void> reload() async {
    _isInitialized = false;
    state = []; // Clear current state
    await _loadBookings();
  }

  Future<void> addBooking(LocalBooking booking) async {
    state = [...state, booking];
    await _saveBookings();

    // Sync customer data when a booking is added
    await _syncCustomerFromBooking(booking);
  }

  Future<void> _syncCustomerFromBooking(LocalBooking booking) async {
    try {
      // Create a customer ID from the customer name (normalized)
      final customerId = 'cust_${booking.customerName.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '')}';

      // Parse amount from total
      final amountStr = booking.total.replaceAll('₱', '').replaceAll(',', '').trim();
      final amount = double.tryParse(amountStr) ?? 0.0;

      // Get current customers
      final customersNotifier = _ref.read(customersProvider.notifier);
      final currentCustomers = _ref.read(customersProvider).value ?? [];

      // Check if customer already exists
      final existingCustomer = currentCustomers.where((c) => c.id == customerId).firstOrNull;

      if (existingCustomer != null) {
        // Update existing customer
        final updatedCustomer = existingCustomer.copyWith(
          totalBookings: existingCustomer.totalBookings + 1,
          lastActiveAt: DateTime.now(),
        );
        await customersNotifier.updateCustomer(updatedCustomer);
      } else {
        // Create new customer
        final newCustomer = CustomerModel(
          id: customerId,
          name: booking.customerName,
          email: '${booking.customerName.toLowerCase().replaceAll(' ', '.')}@email.com',
          phone: booking.customerPhone != 'No phone' ? booking.customerPhone : null,
          status: CustomerStatus.active,
          createdAt: DateTime.now(),
          lastActiveAt: DateTime.now(),
          totalBookings: 1,
          completedBookings: 0,
          cancelledBookings: 0,
          totalSpent: 0.0,
          addresses: booking.location.isNotEmpty ? [booking.location] : [],
        );
        await customersNotifier.addCustomer(newCustomer);
      }

      // Add booking to customer history
      final bookingHistory = CustomerBookingHistory(
        bookingId: booking.id,
        serviceName: '${booking.deviceName} - ${booking.serviceName}',
        technicianName: booking.technician,
        bookingDate: DateTime.now(),
        status: booking.status.toLowerCase().replaceAll(' ', '_'),
        amount: amount,
      );
      await customersNotifier.addBookingToHistory(customerId, bookingHistory);

      print('Customer synced: $customerId');
    } catch (e) {
      print('Error syncing customer from booking: $e');
    }
  }

  Future<void> _updateCustomerStatsOnStatusChange(LocalBooking booking, String newStatus) async {
    try {
      final customerId = 'cust_${booking.customerName.toLowerCase().replaceAll(' ', '_').replaceAll(RegExp(r'[^a-z0-9_]'), '')}';

      // Parse amount from total
      final amountStr = booking.total.replaceAll('₱', '').replaceAll(',', '').trim();
      final amount = double.tryParse(amountStr) ?? 0.0;

      final customersNotifier = _ref.read(customersProvider.notifier);
      final currentCustomers = _ref.read(customersProvider).value ?? [];
      final existingCustomer = currentCustomers.where((c) => c.id == customerId).firstOrNull;

      if (existingCustomer != null) {
        CustomerModel updatedCustomer = existingCustomer;

        if (newStatus == 'Completed') {
          updatedCustomer = existingCustomer.copyWith(
            completedBookings: existingCustomer.completedBookings + 1,
            totalSpent: existingCustomer.totalSpent + amount,
            lastActiveAt: DateTime.now(),
          );
        } else if (newStatus == 'Cancelled') {
          updatedCustomer = existingCustomer.copyWith(
            cancelledBookings: existingCustomer.cancelledBookings + 1,
            lastActiveAt: DateTime.now(),
          );
        }

        await customersNotifier.updateCustomer(updatedCustomer);
      }
    } catch (e) {
      print('Error updating customer stats: $e');
    }
  }

  Future<void> removeBooking(String bookingId) async {
    state = state.where((booking) => booking.id != bookingId).toList();
    await _saveBookings();
  }

  Future<void> updateBookingStatus(String bookingId, String newStatus) async {
    final booking = state.firstWhere((b) => b.id == bookingId);

    // If status is being changed to "Completed", add earnings for the technician
    // and reward points for the customer
    if (newStatus == 'Completed') {
      // Parse the amount from the total string (e.g., "₱299" -> 299.0)
      final amountStr = booking.total.replaceAll('₱', '').replaceAll(',', '').trim();
      final amount = double.tryParse(amountStr) ?? 0.0;

      if (amount > 0) {
        // Add to earnings using the provider (for technician)
        await _ref.read(todayEarningsProvider.notifier).addEarning(
          amount,
          booking.customerName,
          booking.serviceName,
          booking.id,
        );

        // Add reward points to the customer (10 points per ₱500 spent)
        final pointsEarned = (amount / 500).floor() * 10;
        if (pointsEarned > 0) {
          await _ref.read(rewardPointsProvider.notifier).addPoints(pointsEarned);
          print('BookingProvider: Added $pointsEarned reward points for ₱$amount spent');
        }
      }
    }

    // Update customer stats when booking is completed or cancelled
    await _updateCustomerStatsOnStatusChange(booking, newStatus);

    state = state.map((booking) {
      if (booking.id == bookingId) {
        return LocalBooking(
          id: booking.id,
          icon: booking.icon,
          status: newStatus,
          deviceName: booking.deviceName,
          serviceName: booking.serviceName,
          date: booking.date,
          time: booking.time,
          location: booking.location,
          technician: booking.technician,
          total: booking.total,
          customerName: booking.customerName,
          customerPhone: booking.customerPhone,
          priority: booking.priority,
          moreDetails: booking.moreDetails,
          technicianNotes: booking.technicianNotes,
          promoCode: booking.promoCode,
          discountAmount: booking.discountAmount,
          originalPrice: booking.originalPrice,
        );
      }
      return booking;
    }).toList();

    await _saveBookings();
  }

  Future<void> updateBookingNotes(String bookingId, String notes) async {
    state = state.map((booking) {
      if (booking.id == bookingId) {
        return LocalBooking(
          id: booking.id,
          icon: booking.icon,
          status: booking.status,
          deviceName: booking.deviceName,
          serviceName: booking.serviceName,
          date: booking.date,
          time: booking.time,
          location: booking.location,
          technician: booking.technician,
          total: booking.total,
          customerName: booking.customerName,
          customerPhone: booking.customerPhone,
          priority: booking.priority,
          moreDetails: booking.moreDetails,
          technicianNotes: notes,
          promoCode: booking.promoCode,
          discountAmount: booking.discountAmount,
          originalPrice: booking.originalPrice,
        );
      }
      return booking;
    }).toList();

    await _saveBookings();
  }

  Future<void> updateBooking(LocalBooking updatedBooking) async {
    state = state.map((booking) {
      if (booking.id == updatedBooking.id) {
        return updatedBooking;
      }
      return booking;
    }).toList();

    await _saveBookings();
  }
}

final localBookingsProvider = StateNotifierProvider<LocalBookingNotifier, List<LocalBooking>>(
  (ref) => LocalBookingNotifier(ref),
);
