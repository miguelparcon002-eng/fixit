import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/customer_model.dart';

final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});

// Provider for all customers
final customersProvider = StateNotifierProvider<CustomersNotifier, AsyncValue<List<CustomerModel>>>((ref) {
  return CustomersNotifier(ref.watch(supabaseClientProvider));
});

// Provider for a single customer by ID
final customerByIdProvider = Provider.family<CustomerModel?, String>((ref, customerId) {
  final customersAsync = ref.watch(customersProvider);
  return customersAsync.whenOrNull(
    data: (customers) => customers.where((c) => c.id == customerId).firstOrNull,
  );
});

// Provider for active customers count
final activeCustomersCountProvider = Provider<int>((ref) {
  final customersAsync = ref.watch(customersProvider);
  return customersAsync.whenOrNull(
    data: (customers) => customers.where((c) => c.isCurrentlyActive).length,
  ) ?? 0;
});

// Provider for customer booking history
final customerBookingHistoryProvider = FutureProvider.family<List<CustomerBookingHistory>, String>((ref, customerId) async {
  final supabase = ref.watch(supabaseClientProvider);
  final notifier = CustomersNotifier(supabase);
  return notifier.getCustomerBookingHistory(customerId);
});

class CustomersNotifier extends StateNotifier<AsyncValue<List<CustomerModel>>> {
  final SupabaseClient _supabase;
  static const String _storageKey = 'customers_data';

  CustomersNotifier(this._supabase) : super(const AsyncValue.loading()) {
    loadCustomers();
  }

  Future<void> loadCustomers() async {
    try {
      state = const AsyncValue.loading();

      // Try to load from Supabase local_storage table
      final response = await _supabase
          .from('local_storage')
          .select('value')
          .eq('key', _storageKey)
          .maybeSingle();

      List<CustomerModel> customers = [];

      if (response != null && response['value'] != null) {
        final List<dynamic> jsonList = jsonDecode(response['value'] as String);
        customers = jsonList.map((json) => CustomerModel.fromJson(json)).toList();
      }

      // Sort by last active date (most recent first)
      customers.sort((a, b) {
        if (a.lastActiveAt == null && b.lastActiveAt == null) return 0;
        if (a.lastActiveAt == null) return 1;
        if (b.lastActiveAt == null) return -1;
        return b.lastActiveAt!.compareTo(a.lastActiveAt!);
      });

      state = AsyncValue.data(customers);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _saveToSupabase(List<CustomerModel> customers) async {
    try {
      final jsonString = jsonEncode(customers.map((c) => c.toJson()).toList());

      await _supabase.from('local_storage').upsert({
        'key': _storageKey,
        'value': jsonString,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'key');
    } catch (e) {
      print('Error saving customers to Supabase: $e');
    }
  }

  Future<void> addCustomer(CustomerModel customer) async {
    final currentCustomers = state.value ?? [];

    // Check if customer already exists
    final existingIndex = currentCustomers.indexWhere((c) => c.id == customer.id);

    List<CustomerModel> updatedCustomers;
    if (existingIndex >= 0) {
      // Update existing customer
      updatedCustomers = [...currentCustomers];
      updatedCustomers[existingIndex] = customer;
    } else {
      // Add new customer
      updatedCustomers = [customer, ...currentCustomers];
    }

    state = AsyncValue.data(updatedCustomers);
    await _saveToSupabase(updatedCustomers);
  }

  Future<void> updateCustomer(CustomerModel customer) async {
    final currentCustomers = state.value ?? [];
    final index = currentCustomers.indexWhere((c) => c.id == customer.id);

    if (index >= 0) {
      final updatedCustomers = [...currentCustomers];
      updatedCustomers[index] = customer;
      state = AsyncValue.data(updatedCustomers);
      await _saveToSupabase(updatedCustomers);
    }
  }

  Future<void> updateCustomerActivity(String customerId) async {
    final currentCustomers = state.value ?? [];
    final index = currentCustomers.indexWhere((c) => c.id == customerId);

    if (index >= 0) {
      final updatedCustomers = [...currentCustomers];
      updatedCustomers[index] = updatedCustomers[index].copyWith(
        lastActiveAt: DateTime.now(),
      );
      state = AsyncValue.data(updatedCustomers);
      await _saveToSupabase(updatedCustomers);
    }
  }

  Future<void> updateCustomerStatus(String customerId, CustomerStatus status) async {
    final currentCustomers = state.value ?? [];
    final index = currentCustomers.indexWhere((c) => c.id == customerId);

    if (index >= 0) {
      final updatedCustomers = [...currentCustomers];
      updatedCustomers[index] = updatedCustomers[index].copyWith(
        status: status,
      );
      state = AsyncValue.data(updatedCustomers);
      await _saveToSupabase(updatedCustomers);
    }
  }

  Future<void> incrementBookingStats(String customerId, {
    bool completed = false,
    bool cancelled = false,
    double? amount,
  }) async {
    final currentCustomers = state.value ?? [];
    final index = currentCustomers.indexWhere((c) => c.id == customerId);

    if (index >= 0) {
      final customer = currentCustomers[index];
      final updatedCustomers = [...currentCustomers];
      updatedCustomers[index] = customer.copyWith(
        totalBookings: customer.totalBookings + 1,
        completedBookings: completed ? customer.completedBookings + 1 : customer.completedBookings,
        cancelledBookings: cancelled ? customer.cancelledBookings + 1 : customer.cancelledBookings,
        totalSpent: amount != null ? customer.totalSpent + amount : customer.totalSpent,
        lastActiveAt: DateTime.now(),
      );
      state = AsyncValue.data(updatedCustomers);
      await _saveToSupabase(updatedCustomers);
    }
  }

  Future<List<CustomerBookingHistory>> getCustomerBookingHistory(String customerId) async {
    try {
      // Try to load from Supabase local_storage table
      final response = await _supabase
          .from('local_storage')
          .select('value')
          .eq('key', 'booking_history_$customerId')
          .maybeSingle();

      if (response != null && response['value'] != null) {
        final List<dynamic> jsonList = jsonDecode(response['value'] as String);
        return jsonList.map((json) => CustomerBookingHistory.fromJson(json)).toList();
      }

      return [];
    } catch (e) {
      print('Error loading booking history: $e');
      return [];
    }
  }

  Future<void> addBookingToHistory(String customerId, CustomerBookingHistory booking) async {
    try {
      final history = await getCustomerBookingHistory(customerId);
      final updatedHistory = [booking, ...history];

      final jsonString = jsonEncode(updatedHistory.map((b) => b.toJson()).toList());

      await _supabase.from('local_storage').upsert({
        'key': 'booking_history_$customerId',
        'value': jsonString,
        'updated_at': DateTime.now().toIso8601String(),
      }, onConflict: 'key');
    } catch (e) {
      print('Error saving booking history: $e');
    }
  }

  List<CustomerModel> getFilteredCustomers({
    String? searchQuery,
    CustomerStatus? statusFilter,
    bool? activeOnly,
  }) {
    final customers = state.value ?? [];

    return customers.where((customer) {
      // Search filter
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final query = searchQuery.toLowerCase();
        final matchesSearch = customer.name.toLowerCase().contains(query) ||
            customer.email.toLowerCase().contains(query) ||
            (customer.phone?.contains(query) ?? false);
        if (!matchesSearch) return false;
      }

      // Status filter
      if (statusFilter != null && customer.status != statusFilter) {
        return false;
      }

      // Active filter
      if (activeOnly == true && !customer.isCurrentlyActive) {
        return false;
      }

      return true;
    }).toList();
  }
}
