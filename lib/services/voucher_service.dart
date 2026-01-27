import 'dart:convert';
import 'storage_service.dart';

class Voucher {
  final String id;
  final String code;
  final String title;
  final String description;
  final double discountPercent;
  final DateTime expiresAt;
  final bool isUsed;
  final DateTime createdAt;

  Voucher({
    required this.id,
    required this.code,
    required this.title,
    required this.description,
    required this.discountPercent,
    required this.expiresAt,
    this.isUsed = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  bool get isValid => !isUsed && !isExpired;

  Voucher copyWith({
    String? id,
    String? code,
    String? title,
    String? description,
    double? discountPercent,
    DateTime? expiresAt,
    bool? isUsed,
    DateTime? createdAt,
  }) {
    return Voucher(
      id: id ?? this.id,
      code: code ?? this.code,
      title: title ?? this.title,
      description: description ?? this.description,
      discountPercent: discountPercent ?? this.discountPercent,
      expiresAt: expiresAt ?? this.expiresAt,
      isUsed: isUsed ?? this.isUsed,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'title': title,
    'description': description,
    'discountPercent': discountPercent,
    'expiresAt': expiresAt.toIso8601String(),
    'isUsed': isUsed,
    'createdAt': createdAt.toIso8601String(),
  };

  factory Voucher.fromJson(Map<String, dynamic> json) => Voucher(
    id: json['id'] as String,
    code: json['code'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    discountPercent: (json['discountPercent'] as num).toDouble(),
    expiresAt: DateTime.parse(json['expiresAt'] as String),
    isUsed: json['isUsed'] as bool? ?? false,
    createdAt: json['createdAt'] != null
        ? DateTime.parse(json['createdAt'] as String)
        : DateTime.now(),
  );
}

class VoucherService {
  static const String _storageKey = 'vouchers';
  static const String _setupCompleteKey = 'profile_setup_complete';

  // Check if profile setup is complete
  Future<bool> isProfileSetupComplete() async {
    final data = await StorageService.loadData(_setupCompleteKey);
    return data == 'true';
  }

  // Mark profile setup as complete
  Future<void> markProfileSetupComplete() async {
    await StorageService.saveData(_setupCompleteKey, 'true');
  }

  // Get all vouchers
  Future<List<Voucher>> getVouchers() async {
    try {
      final data = await StorageService.loadData(_storageKey);
      if (data != null && data.isNotEmpty) {
        final List<dynamic> decoded = json.decode(data);
        return decoded.map((item) => Voucher.fromJson(item)).toList();
      }
      return [];
    } catch (e) {
      print('VoucherService: Error loading vouchers - $e');
      return [];
    }
  }

  // Save vouchers
  Future<void> _saveVouchers(List<Voucher> vouchers) async {
    try {
      final data = json.encode(vouchers.map((v) => v.toJson()).toList());
      await StorageService.saveData(_storageKey, data);
    } catch (e) {
      print('VoucherService: Error saving vouchers - $e');
    }
  }

  // Add a voucher
  Future<void> addVoucher(Voucher voucher) async {
    final vouchers = await getVouchers();
    vouchers.add(voucher);
    await _saveVouchers(vouchers);
  }

  // Mark voucher as used
  Future<void> useVoucher(String voucherId) async {
    final vouchers = await getVouchers();
    final updatedVouchers = vouchers.map((v) {
      if (v.id == voucherId) {
        return v.copyWith(isUsed: true);
      }
      return v;
    }).toList();
    await _saveVouchers(updatedVouchers);
  }

  // Create welcome voucher for new customers
  Future<Voucher> createWelcomeVoucher() async {
    final voucher = Voucher(
      id: 'welcome_${DateTime.now().millisecondsSinceEpoch}',
      code: 'WELCOME20',
      title: '20% Off First Repair',
      description: 'Welcome discount for completing your profile setup',
      discountPercent: 20.0,
      expiresAt: DateTime.now().add(const Duration(days: 30)),
    );
    await addVoucher(voucher);
    return voucher;
  }

  // Get valid (unused, not expired) vouchers
  Future<List<Voucher>> getValidVouchers() async {
    final vouchers = await getVouchers();
    return vouchers.where((v) => v.isValid).toList();
  }
}
