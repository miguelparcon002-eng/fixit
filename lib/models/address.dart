class Address {
  final String id;
  final String street;
  final String city;
  final String neighborhood;
  final bool isDefault;

  Address({
    required this.id,
    required this.street,
    required this.city,
    required this.neighborhood,
    this.isDefault = false,
  });

  Address copyWith({
    String? id,
    String? street,
    String? city,
    String? neighborhood,
    bool? isDefault,
  }) {
    return Address(
      id: id ?? this.id,
      street: street ?? this.street,
      city: city ?? this.city,
      neighborhood: neighborhood ?? this.neighborhood,
      isDefault: isDefault ?? this.isDefault,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'street': street,
    'city': city,
    'neighborhood': neighborhood,
    'isDefault': isDefault,
  };

  factory Address.fromJson(Map<String, dynamic> json) => Address(
    id: json['id'] as String,
    street: json['street'] as String,
    city: json['city'] as String,
    neighborhood: json['neighborhood'] as String,
    isDefault: json['isDefault'] as bool? ?? false,
  );
}
