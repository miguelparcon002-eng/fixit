import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/address_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/rewards_provider.dart';
import '../providers/voucher_provider.dart';
import '../providers/earnings_provider.dart';
import '../providers/auth_provider.dart';
import 'storage_service.dart';

/// Service to manage user session and ensure data isolation between accounts.
/// Call this when a user logs in, logs out, or signs up to reset all user-specific data.
class UserSessionService {
  final Ref _ref;

  UserSessionService(this._ref);

  /// Call this after a user successfully logs in.
  /// This ensures all providers reload data for the new user.
  Future<void> onUserLogin(String userId) async {
    print('UserSessionService: User logged in - $userId');

    // Set the current user for storage isolation
    StorageService.setCurrentUser(userId);

    // Reload all user-specific providers
    await _reloadAllUserData();
  }

  /// Call this when a user logs out.
  /// This clears all cached data and resets providers.
  Future<void> onUserLogout() async {
    print('UserSessionService: User logged out');

    // Clear storage user context
    StorageService.setCurrentUser(null);

    // Invalidate all user-specific providers to clear cached data
    _invalidateAllProviders();
  }

  /// Call this after a new user signs up.
  /// This ensures the new user starts with completely fresh data.
  Future<void> onUserSignup(String userId) async {
    print('UserSessionService: New user signed up - $userId');

    // Set the current user for storage isolation
    StorageService.setCurrentUser(userId);

    // Invalidate all providers to ensure fresh state
    _invalidateAllProviders();

    // New users start with empty data - no need to load anything
    print('UserSessionService: New user initialized with fresh data');
  }

  /// Reload all user-specific data from storage
  Future<void> _reloadAllUserData() async {
    try {
      // Reload bookings
      await _ref.read(localBookingsProvider.notifier).reload();

      // Reload addresses
      await _ref.read(addressProvider.notifier).reload();

      // Reload rewards
      await _ref.read(rewardPointsProvider.notifier).reload();
      await _ref.read(redeemedVouchersProvider.notifier).reload();

      // Reload vouchers
      _ref.invalidate(validVouchersProvider);
      _ref.invalidate(vouchersProvider);
      _ref.invalidate(profileSetupCompleteProvider);

      // Reload earnings (for technicians)
      await _ref.read(todayEarningsProvider.notifier).reload();
      _ref.invalidate(totalEarningsProvider);
      _ref.invalidate(weekEarningsProvider);
      _ref.invalidate(monthEarningsProvider);
      _ref.invalidate(transactionsProvider);

      // Refresh user profile
      _ref.invalidate(currentUserProvider);

      print('UserSessionService: All user data reloaded');
    } catch (e) {
      print('UserSessionService: Error reloading user data - $e');
    }
  }

  /// Invalidate all user-specific providers (clears cached state)
  void _invalidateAllProviders() {
    // Invalidate auth
    _ref.invalidate(currentUserProvider);

    // Invalidate bookings
    _ref.invalidate(localBookingsProvider);

    // Invalidate addresses
    _ref.invalidate(addressProvider);

    // Invalidate rewards
    _ref.invalidate(rewardPointsProvider);
    _ref.invalidate(redeemedVouchersProvider);

    // Invalidate vouchers
    _ref.invalidate(validVouchersProvider);
    _ref.invalidate(vouchersProvider);
    _ref.invalidate(profileSetupCompleteProvider);
    _ref.invalidate(voucherNotifierProvider);

    // Invalidate earnings
    _ref.invalidate(todayEarningsProvider);
    _ref.invalidate(totalEarningsProvider);
    _ref.invalidate(weekEarningsProvider);
    _ref.invalidate(monthEarningsProvider);
    _ref.invalidate(transactionsProvider);

    print('UserSessionService: All providers invalidated');
  }
}

/// Provider for the UserSessionService
final userSessionServiceProvider = Provider((ref) => UserSessionService(ref));
