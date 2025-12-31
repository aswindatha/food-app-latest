import 'user.dart';

class DeliveryReview {
  final int id;
  final int donationId;
  final int volunteerId;
  final int rating;
  final String? reviewText;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? volunteer;

  DeliveryReview({
    required this.id,
    required this.donationId,
    required this.volunteerId,
    required this.rating,
    this.reviewText,
    required this.createdAt,
    required this.updatedAt,
    this.volunteer,
  });

  factory DeliveryReview.fromJson(Map<String, dynamic> json) {
    return DeliveryReview(
      id: json['id'] ?? 0,
      donationId: json['donation_id'] ?? 0,
      volunteerId: json['volunteer_id'] ?? 0,
      rating: json['rating'] ?? 0,
      reviewText: json['review_text'],
      createdAt: DateTime.parse(json['created_at'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(json['updated_at'] ?? DateTime.now().toIso8601String()),
      volunteer: json['volunteer'] != null ? User.fromJson(json['volunteer']) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'donation_id': donationId,
      'volunteer_id': volunteerId,
      'rating': rating,
      'review_text': reviewText,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
