import '../../../utils/formatters/formatter.dart';

class AddressModel {
  String id;
  final String name;
  final String phoneNumber;
  final String street;
  final String city;
  final String state;
  final String postalCode;
  final String country;
  final DateTime? dateTime;
  bool selectedAddress;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  AddressModel({
    required this.id,
    required this.name,
    required this.phoneNumber,
    required this.street,
    required this.city,
    required this.state,
    required this.postalCode,
    required this.country,
    this.dateTime,
    this.selectedAddress = true,
    this.createdAt,
    this.updatedAt,
  });

  String get formattedPhoneNo => TFormatter.formatPhoneNumber(phoneNumber);

  static AddressModel empty() {
    return AddressModel(
      id: '',
      name: '',
      phoneNumber: '',
      street: '',
      city: '',
      state: '',
      postalCode: '',
      country: '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone_number': phoneNumber, // ✅ snake_case
      'street': street,
      'city': city,
      'state': state,
      'postal_code': postalCode, // ✅ snake_case
      'country': country,
      'date_time': dateTime?.toIso8601String(), // ✅ snake_case
      'selected_address': selectedAddress, // ✅ snake_case
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  factory AddressModel.fromJson(Map<String, dynamic> data) {
    if (data.isEmpty) return AddressModel.empty();

    return AddressModel(
      id: data['id'] ?? '',
      name: data['name'] ?? '',
      phoneNumber: data['phone_number'] ?? '', // ✅ snake_case
      street: data['street'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      postalCode: data['postal_code'] ?? '', // ✅ snake_case
      country: data['country'] ?? '',
      dateTime: data['date_time'] != null
          ? DateTime.parse(data['date_time'] as String) // ✅ snake_case
          : null,
      selectedAddress: data['selected_address'] ?? false, // ✅ snake_case
      createdAt: data['created_at'] != null
          ? DateTime.parse(data['created_at'] as String)
          : null,
      updatedAt: data['updated_at'] != null
          ? DateTime.parse(data['updated_at'] as String)
          : null,
    );
  }

  factory AddressModel.fromMap(Map<String, dynamic> data) {
    return AddressModel(
      id: data['id']?.toString() ?? '',
      name: data['name'] ?? '',
      phoneNumber: data['phone_number'] ?? '', // ✅ snake_case
      street: data['street'] ?? '',
      city: data['city'] ?? '',
      state: data['state'] ?? '',
      postalCode: data['postal_code'] ?? '', // ✅ snake_case
      country: data['country'] ?? '',
      dateTime: data['date_time'] != null
          ? DateTime.parse(data['date_time'] as String) // ✅ snake_case
          : null,
      selectedAddress: data['selected_address'] ?? false, // ✅ snake_case
    );
  }

  @override
  String toString() {
    return '$street, $city, $state, $postalCode, $country';
  }
}
