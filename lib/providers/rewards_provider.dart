import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/reward.dart';
import '../services/storage_service.dart';

// Provider to manage reward points (user-specific, persisted)
class RewardPointsNotifier extends StateNotifier<int> {
  String? _lastUserId;
  bool _isInitialized = false;

  RewardPointsNotifier() : super(0) {
    _loadPoints();
  }

  Future<void> _loadPoints() async {
    final currentUserId = StorageService.currentUserId;

    // Check if user changed
    if (_isInitialized && _lastUserId == currentUserId) return;

    // Reset if user changed
    if (_lastUserId != currentUserId) {
      state = 0;
      _isInitialized = false;
    }
    _lastUserId = currentUserId;

    try {
      final data = await StorageService.loadData('reward_points');
      if (data != null) {
        state = int.tryParse(data) ?? 0;
        print('RewardPointsNotifier: Loaded $state points for user $currentUserId');
      } else {
        // New user starts with 0 points
        state = 0;
        print('RewardPointsNotifier: New user $currentUserId starts with 0 points');
      }
      _isInitialized = true;
    } catch (e) {
      print('RewardPointsNotifier: Error loading points - $e');
      state = 0;
      _isInitialized = true;
    }
  }

  Future<void> _savePoints() async {
    try {
      await StorageService.saveData('reward_points', state.toString());
    } catch (e) {
      print('RewardPointsNotifier: Error saving points - $e');
    }
  }

  Future<void> reload() async {
    _isInitialized = false;
    _lastUserId = null;
    state = 0;
    await _loadPoints();
  }

  Future<void> addPoints(int points) async {
    state = state + points;
    await _savePoints();
  }

  Future<void> redeemPoints(int points) async {
    if (state >= points) {
      state = state - points;
      await _savePoints();
    }
  }

  Future<void> setPoints(int points) async {
    state = points;
    await _savePoints();
  }
}

final rewardPointsProvider = StateNotifierProvider<RewardPointsNotifier, int>((ref) {
  return RewardPointsNotifier();
});

// Provider to manage redeemed vouchers (user-specific, persisted)
class RedeemedVouchersNotifier extends StateNotifier<List<RewardVoucher>> {
  String? _lastUserId;
  bool _isInitialized = false;

  RedeemedVouchersNotifier() : super([]) {
    _loadVouchers();
  }

  Future<void> _loadVouchers() async {
    final currentUserId = StorageService.currentUserId;

    // Check if user changed
    if (_isInitialized && _lastUserId == currentUserId) return;

    // Reset if user changed
    if (_lastUserId != currentUserId) {
      state = [];
      _isInitialized = false;
    }
    _lastUserId = currentUserId;

    try {
      final data = await StorageService.loadData('redeemed_vouchers');
      if (data != null && data.isNotEmpty) {
        final List<dynamic> decoded = json.decode(data);
        state = decoded.map((item) => RewardVoucher.fromJson(item)).toList();
        print('RedeemedVouchersNotifier: Loaded ${state.length} vouchers for user $currentUserId');
      } else {
        state = [];
        print('RedeemedVouchersNotifier: No vouchers for user $currentUserId');
      }
      _isInitialized = true;
    } catch (e) {
      print('RedeemedVouchersNotifier: Error loading vouchers - $e');
      state = [];
      _isInitialized = true;
    }
  }

  Future<void> _saveVouchers() async {
    try {
      final data = json.encode(state.map((v) => v.toJson()).toList());
      await StorageService.saveData('redeemed_vouchers', data);
    } catch (e) {
      print('RedeemedVouchersNotifier: Error saving vouchers - $e');
    }
  }

  Future<void> reload() async {
    _isInitialized = false;
    _lastUserId = null;
    state = [];
    await _loadVouchers();
  }

  Future<void> addVoucher(RewardVoucher voucher) async {
    state = [...state, voucher];
    await _saveVouchers();
  }

  Future<void> removeVoucher(String id) async {
    state = state.where((v) => v.id != id).toList();
    await _saveVouchers();
  }
}

final redeemedVouchersProvider = StateNotifierProvider<RedeemedVouchersNotifier, List<RewardVoucher>>((ref) {
  return RedeemedVouchersNotifier();
});

// Available vouchers to redeem
final availableVouchersProvider = Provider<List<RewardVoucher>>((ref) {
  return [
    RewardVoucher(
      id: 'v1',
      title: '₱100 OFF',
      description: 'Get ₱100 discount on any repair service',
      pointsCost: 50,
      discountAmount: 100,
      discountType: 'fixed',
    ),
    RewardVoucher(
      id: 'v2',
      title: '₱250 OFF',
      description: 'Get ₱250 discount on repairs above ₱1,000',
      pointsCost: 100,
      discountAmount: 250,
      discountType: 'fixed',
    ),
    RewardVoucher(
      id: 'v3',
      title: '10% OFF',
      description: 'Get 10% discount on any repair service',
      pointsCost: 75,
      discountAmount: 10,
      discountType: 'percentage',
    ),
    RewardVoucher(
      id: 'v4',
      title: '₱500 OFF',
      description: 'Get ₱500 discount on repairs above ₱2,000',
      pointsCost: 150,
      discountAmount: 500,
      discountType: 'fixed',
    ),
    RewardVoucher(
      id: 'v5',
      title: '20% OFF',
      description: 'Get 20% discount on any repair service',
      pointsCost: 200,
      discountAmount: 20,
      discountType: 'percentage',
    ),
    RewardVoucher(
      id: 'v6',
      title: 'FREE Diagnostic',
      description: 'Free diagnostic service (worth ₱200)',
      pointsCost: 80,
      discountAmount: 200,
      discountType: 'fixed',
    ),
  ];
});
