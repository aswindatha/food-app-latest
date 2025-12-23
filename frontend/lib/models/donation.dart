import 'user.dart';

class Donation {
  final int id;
  final int donorId;
  final String title;
  final String description;
  final String donationType;
  final int quantity;
  final String unit;
  final DateTime expiryDate;
  final String pickupAddress;
  final DateTime? pickupTime;
  final String status;
  final int? volunteerId;
  final int? organizationId;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? donor;
  final User? volunteer;
  final User? organization;

  Donation({
    required this.id,
    required this.donorId,
    required this.title,
    required this.description,
    required this.donationType,
    required this.quantity,
    required this.unit,
    required this.expiryDate,
    required this.pickupAddress,
    this.pickupTime,
    required this.status,
    this.volunteerId,
    this.organizationId,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    this.donor,
    this.volunteer,
    this.organization,
  });

  factory Donation.fromJson(Map<String, dynamic> json) {
    return Donation(
      id: json['id'] ?? 0,
      donorId: json['donor_id'] ?? 0,
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      donationType: json['donation_type'] ?? '',
      quantity: json['quantity'] ?? 0,
      unit: json['unit'] ?? '',
      expiryDate: DateTime.parse(json['expiry_date'] ?? DateTime.now().toIso8601String()),
      pickupAddress: json['pickup_address'] ?? '',
      pickupTime: json['pickup_time'] != null ? DateTime.parse(json['pickup_time']) : null,
      status: json['status'] ?? '',
      volunteerId: json['volunteer_id'],
      organizationId: json['organization_id'],
      imageUrl: json['image_url'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      donor: json['donor'] != null ? User.fromJson(json['donor']) : null,
      volunteer: json['volunteer'] != null ? User.fromJson(json['volunteer']) : null,
      organization: json['organization'] != null ? User.fromJson(json['organization']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'donor_id': donorId,
      'title': title,
      'description': description,
      'donation_type': donationType,
      'quantity': quantity,
      'unit': unit,
      'expiry_date': expiryDate.toIso8601String(),
      'pickup_address': pickupAddress,
      'pickup_time': pickupTime?.toIso8601String(),
      'status': status,
      'volunteer_id': volunteerId,
      'organization_id': organizationId,
      'image_url': imageUrl,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  Donation copyWith({
    int? id,
    int? donorId,
    String? title,
    String? description,
    String? donationType,
    int? quantity,
    String? unit,
    DateTime? expiryDate,
    String? pickupAddress,
    DateTime? pickupTime,
    String? status,
    int? volunteerId,
    int? organizationId,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    User? donor,
    User? volunteer,
    User? organization,
  }) {
    return Donation(
      id: id ?? this.id,
      donorId: donorId ?? this.donorId,
      title: title ?? this.title,
      description: description ?? this.description,
      donationType: donationType ?? this.donationType,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      expiryDate: expiryDate ?? this.expiryDate,
      pickupAddress: pickupAddress ?? this.pickupAddress,
      pickupTime: pickupTime ?? this.pickupTime,
      status: status ?? this.status,
      volunteerId: volunteerId ?? this.volunteerId,
      organizationId: organizationId ?? this.organizationId,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      donor: donor ?? this.donor,
      volunteer: volunteer ?? this.volunteer,
      organization: organization ?? this.organization,
    );
  }

  bool get isEditable => status == 'available' || status == 'current';
  bool get isExpired => status == 'expired';
  bool get isDonated => status == 'donated';
  bool get isCurrent => status == 'available' || status == 'current';

  String get statusDisplay {
    switch (status) {
      case 'current':
      case 'available':
        return 'Available';
      case 'donated':
        return 'Donated';
      case 'expired':
        return 'Expired';
      default:
        return status;
    }
  }

  String get typeDisplay {
    switch (donationType) {
      case 'FOOD':
        return 'Food';
      case 'CLOTHES':
        return 'Clothes';
      case 'MEDICINE':
        return 'Medicine';
      case 'OTHER':
        return 'Other';
      default:
        return donationType;
    }
  }
}
