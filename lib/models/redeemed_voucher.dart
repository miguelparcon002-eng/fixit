class RedeemedVoucher {
  final String id;
  final String userId;
  final String voucherId;
  final String voucherTitle;
  final String? voucherDescription;
  final int pointsCost;
  final double discountAmount;
  final String discountType;
  final DateTime redeemedAt;
  final DateTime? usedAt;
  final String? bookingId;
  final bool isUsed;
  final DateTime? expiresAt;
  final DateTime createdAt;

  RedeemedVoucher({
    required this.id,
    required this.userId,
    required this.voucherId,
    required this.voucherTitle,
    this.voucherDescription,
    required this.pointsCost,
    required this.discountAmount,
    required this.discountType,
    required this.redeemedAt,
    this.usedAt,
    this.bookingId,
    required this.isUsed,
    this.expiresAt,
    required this.createdAt,
  });

  factory RedeemedVoucher.fromJson(Map<String, dynamic> json) {
    return RedeemedVoucher(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      voucherId: json['voucher_id'] as String,
      voucherTitle: json['voucher_title'] as String,
      voucherDescription: json['voucher_description'] as String?,
      pointsCost: json['points_cost'] as int,
      discountAmount: (json['discount_amount'] as num).toDouble(),
      discountType: json['discount_type'] as String,
      redeemedAt: DateTime.parse(json['redeemed_at'] as String),
      usedAt: json['used_at'] != null ? DateTime.parse(json['used_at'] as String) : null,
      bookingId: json['booking_id'] as String?,
      isUsed: json['is_used'] as bool? ?? false,
      expiresAt: json['expires_at'] != null ? DateTime.parse(json['expires_at'] as String) : null,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'voucher_id': voucherId,
      'voucher_title': voucherTitle,
      'voucher_description': voucherDescription,
      'points_cost': pointsCost,
      'discount_amount': discountAmount,
      'discount_type': discountType,
      'redeemed_at': redeemedAt.toIso8601String(),
      'used_at': usedAt?.toIso8601String(),
      'booking_id': bookingId,
      'is_used': isUsed,
      'expires_at': expiresAt?.toIso8601String(),
      'created_at': createdAt.toIso8601String(),
    };
  }

  RedeemedVoucher copyWith({
    String? id,
    String? userId,
    String? voucherId,
    String? voucherTitle,
    String? voucherDescription,
    int? pointsCost,
    double? discountAmount,
    String? discountType,
    DateTime? redeemedAt,
    DateTime? usedAt,
    String? bookingId,
    bool? isUsed,
    DateTime? expiresAt,
    DateTime? createdAt,
  }) {
    return RedeemedVoucher(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      voucherId: voucherId ?? this.voucherId,
      voucherTitle: voucherTitle ?? this.voucherTitle,
      voucherDescription: voucherDescription ?? this.voucherDescription,
      pointsCost: pointsCost ?? this.pointsCost,
      discountAmount: discountAmount ?? this.discountAmount,
      discountType: discountType ?? this.discountType,
      redeemedAt: redeemedAt ?? this.redeemedAt,
      usedAt: usedAt ?? this.usedAt,
      bookingId: bookingId ?? this.bookingId,
      isUsed: isUsed ?? this.isUsed,
      expiresAt: expiresAt ?? this.expiresAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
