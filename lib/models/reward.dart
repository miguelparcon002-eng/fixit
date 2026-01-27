class RewardVoucher {
  final String id;
  final String title;
  final String description;
  final int pointsCost;
  final int discountAmount;
  final String discountType; // 'percentage' or 'fixed'
  final bool isRedeemed;

  RewardVoucher({
    required this.id,
    required this.title,
    required this.description,
    required this.pointsCost,
    required this.discountAmount,
    required this.discountType,
    this.isRedeemed = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'pointsCost': pointsCost,
    'discountAmount': discountAmount,
    'discountType': discountType,
    'isRedeemed': isRedeemed,
  };

  factory RewardVoucher.fromJson(Map<String, dynamic> json) => RewardVoucher(
    id: json['id'] as String,
    title: json['title'] as String,
    description: json['description'] as String,
    pointsCost: json['pointsCost'] as int,
    discountAmount: json['discountAmount'] as int,
    discountType: json['discountType'] as String,
    isRedeemed: json['isRedeemed'] as bool? ?? false,
  );

  RewardVoucher copyWith({
    String? id,
    String? title,
    String? description,
    int? pointsCost,
    int? discountAmount,
    String? discountType,
    bool? isRedeemed,
  }) {
    return RewardVoucher(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      pointsCost: pointsCost ?? this.pointsCost,
      discountAmount: discountAmount ?? this.discountAmount,
      discountType: discountType ?? this.discountType,
      isRedeemed: isRedeemed ?? this.isRedeemed,
    );
  }
}
