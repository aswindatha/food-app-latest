import 'donation.dart';
import 'user.dart';

class VolunteerRequest {
  final int id;
  final int donationId;
  final int organizationId;
  final int volunteerId;
  final String status;
  final String? message;
  final DateTime createdAt;
  final DateTime updatedAt;
  final Donation? donation;
  final User? organization;
  final User? volunteer;

  VolunteerRequest({
    required this.id,
    required this.donationId,
    required this.organizationId,
    required this.volunteerId,
    required this.status,
    this.message,
    required this.createdAt,
    required this.updatedAt,
    this.donation,
    this.organization,
    this.volunteer,
  });

  factory VolunteerRequest.fromJson(Map<String, dynamic> json) {
    final donationJson = json['donation'] ?? json['Donation'];
    final organizationJson = json['organization'] ?? json['Organization'];
    final volunteerJson = json['volunteer'] ?? json['Volunteer'];

    return VolunteerRequest(
      id: json['id'] ?? 0,
      donationId: json['donation_id'] ?? 0,
      organizationId: json['organization_id'] ?? 0,
      volunteerId: json['volunteer_id'] ?? 0,
      status: json['status'] ?? '',
      message: json['message'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      donation: donationJson != null ? Donation.fromJson(donationJson) : null,
      organization: organizationJson != null ? User.fromJson(organizationJson) : null,
      volunteer: volunteerJson != null ? User.fromJson(volunteerJson) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'donation_id': donationId,
      'organization_id': organizationId,
      'volunteer_id': volunteerId,
      'status': status,
      'message': message,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'donation': donation?.toJson(),
      'organization': organization?.toJson(),
      'volunteer': volunteer?.toJson(),
    };
  }
}
