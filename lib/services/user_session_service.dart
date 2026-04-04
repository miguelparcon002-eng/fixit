import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/address_provider.dart';
import '../providers/booking_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/ratings_provider.dart';
import '../providers/rewards_provider.dart';
import '../providers/support_ticket_provider.dart';
import '../providers/technician_stats_provider.dart';
import '../providers/voucher_provider.dart';
import '../providers/earnings_provider.dart';
import '../providers/auth_provider.dart';
import 'fcm_service.dart';
import 'storage_service.dart';
import '../core/utils/app_logger.dart';
class UserSessionService {
  final Ref _ref;
  UserSessionService(this._ref);
  Future<void> onUserLogin(String userId) async {
    AppLogger.p('UserSessionService: User logged in - $userId');
    StorageService.setCurrentUser(userId);
    await FCMService.saveTokenForUser(userId);
    await _reloadAllUserData();
  }
  Future<void> onUserLogout() async {
    AppLogger.p('UserSessionService: User logged out');
    final userId = StorageService.currentUserId;
    if (userId != null) await FCMService.clearTokenForUser(userId);
    StorageService.setCurrentUser(null);
    _invalidateAllProviders();
  }
  Future<void> onUserSignup(String userId) async {
    AppLogger.p('UserSessionService: New user signed up - $userId');
    StorageService.setCurrentUser(userId);
    _invalidateAllProviders();
    AppLogger.p('UserSessionService: New user initialized with fresh data');
  }
  Future<void> _reloadAllUserData() async {
    try {
      _ref.invalidate(customerBookingsProvider);
      _ref.invalidate(technicianBookingsProvider);
      _ref.invalidate(userAddressesProvider);
      _ref.invalidate(rewardPointsProvider);
      _ref.invalidate(redeemedVouchersProvider);
      _ref.invalidate(unusedVouchersProvider);
      _ref.invalidate(profileSetupCompleteProvider);
      _ref.invalidate(todayEarningsProvider);
      _ref.invalidate(totalEarningsProvider);
      _ref.invalidate(weekEarningsProvider);
      _ref.invalidate(monthEarningsProvider);
      _ref.invalidate(transactionsProvider);
      _ref.invalidate(currentUserProvider);
      _ref.invalidate(profileProvider);
      _ref.invalidate(technicianStatsProvider);
      _ref.invalidate(ratingsProvider);
      _ref.invalidate(supportTicketsProvider);
      AppLogger.p('UserSessionService: All user data reloaded');
    } catch (e) {
      AppLogger.p('UserSessionService: Error reloading user data - $e');
    }
  }
  void _invalidateAllProviders() {
    _ref.invalidate(currentUserProvider);
    _ref.invalidate(profileProvider);
    _ref.invalidate(customerBookingsProvider);
    _ref.invalidate(technicianBookingsProvider);
    _ref.invalidate(userAddressesProvider);
    _ref.invalidate(rewardPointsProvider);
    _ref.invalidate(redeemedVouchersProvider);
    _ref.invalidate(unusedVouchersProvider);
    _ref.invalidate(profileSetupCompleteProvider);
    _ref.invalidate(todayEarningsProvider);
    _ref.invalidate(totalEarningsProvider);
    _ref.invalidate(weekEarningsProvider);
    _ref.invalidate(monthEarningsProvider);
    _ref.invalidate(transactionsProvider);
    _ref.invalidate(technicianStatsProvider);
    _ref.invalidate(ratingsProvider);
    _ref.invalidate(supportTicketsProvider);
    AppLogger.p('UserSessionService: All providers invalidated');
  }
}
final userSessionServiceProvider = Provider((ref) => UserSessionService(ref));