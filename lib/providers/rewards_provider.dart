import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reward.dart';
import '../models/redeemed_voucher.dart';
import '../services/redeemed_voucher_service.dart';
import 'booking_provider.dart';
import 'auth_provider.dart';
import '../core/utils/app_logger.dart';

// Service provider
final redeemedVoucherServiceProvider = Provider((ref) => RedeemedVoucherService());

// FutureProvider to calculate reward points from Supabase bookings
final rewardPointsProvider = FutureProvider<int>((ref) async {
  final user = ref.watch(currentUserProvider).value;

  if (user == null) return 0;

  try {
    // Get completed bookings from Supabase for this customer
    final bookingsAsync = await ref.watch(customerBookingsProvider.future);
    final completedBookings = bookingsAsync.where((b) => b.status == 'completed').toList();

    // Calculate total points earned from completed bookings
    int earnedPoints = 0;

    for (final booking in completedBookings) {
      final amount = booking.finalCost ?? booking.estimatedCost ?? 0.0;

      // Calculate points: 1 point per ₱50 spent
      final pointsForBooking = (amount / 50).floor();
      earnedPoints += pointsForBooking;
    }

    // Get redeemed vouchers to calculate spent points
    final voucherService = ref.watch(redeemedVoucherServiceProvider);
    final redeemedVouchers = await voucherService.getUserRedeemedVouchers(user.id);

    // Calculate total points spent on vouchers
    int spentPoints = 0;
    for (final voucher in redeemedVouchers) {
      spentPoints += voucher.pointsCost;
    }

    // Calculate remaining points
    final remainingPoints = earnedPoints - spentPoints;

    AppLogger.p('RewardPointsProvider: Earned $earnedPoints points, spent $spentPoints points, remaining $remainingPoints points');

    return remainingPoints > 0 ? remainingPoints : 0;
  } catch (e) {
    AppLogger.p('RewardPointsProvider: Error calculating points from Supabase - $e');
    return 0;
  }
});

// StreamProvider for real-time redeemed vouchers from Supabase
final redeemedVouchersProvider = StreamProvider<List<RedeemedVoucher>>((ref) {
  final voucherService = ref.watch(redeemedVoucherServiceProvider);
  final user = ref.watch(currentUserProvider).value;

  if (user == null) return Stream.value([]);

  return voucherService.watchUserRedeemedVouchers(user.id);
});

// Provider to get unused (available) redeemed vouchers
final unusedVouchersProvider = FutureProvider<List<RedeemedVoucher>>((ref) async {
  final voucherService = ref.watch(redeemedVoucherServiceProvider);
  final user = ref.watch(currentUserProvider).value;

  if (user == null) return [];

  return voucherService.getUnusedVouchers(user.id);
});

// Available vouchers to redeem (catalog)
final availableVouchersProvider = Provider<List<RewardVoucher>>((ref) {
  return [
    RewardVoucher(
      id: 'v1',
      title: '₱100 OFF',
      description: 'Get ₱100 discount on any repair service',
      pointsCost: 100,
      discountAmount: 100,
      discountType: 'fixed',
    ),
    RewardVoucher(
      id: 'v2',
      title: '₱250 OFF',
      description: 'Get ₱250 discount on repairs above ₱1,000',
      pointsCost: 200,
      discountAmount: 250,
      discountType: 'fixed',
    ),
    RewardVoucher(
      id: 'v3',
      title: '10% OFF',
      description: 'Get 10% discount on any repair service',
      pointsCost: 150,
      discountAmount: 10,
      discountType: 'percentage',
    ),
    RewardVoucher(
      id: 'v4',
      title: '₱500 OFF',
      description: 'Get ₱500 discount on repairs above ₱2,000',
      pointsCost: 300,
      discountAmount: 500,
      discountType: 'fixed',
    ),
    RewardVoucher(
      id: 'v5',
      title: '20% OFF',
      description: 'Get 20% discount on any repair service',
      pointsCost: 400,
      discountAmount: 20,
      discountType: 'percentage',
    ),
  ];
});
