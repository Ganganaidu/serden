import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

class Review extends Equatable {
  final int id;
  final int proId;
  final String reviewerName;
  final String reviewDate;
  final String? category;
  final String? tag;
  final String text;
  final String? response;
  final int rating;
  final bool isVerified;

  const Review({
    required this.id,
    required this.proId,
    required this.reviewerName,
    required this.reviewDate,
    this.category,
    this.tag,
    required this.text,
    this.response,
    required this.rating,
    this.isVerified = false,
  });

  factory Review.fromJson(Map<String, dynamic> json) {
    final created = DateTime.tryParse(
            (json['createdDate'] as String?) ?? '') ??
        DateTime.now();
    final displayDate = DateFormat('MMM d, yyyy').format(created);

    return Review(
      id: json['reviewId'] as int,
      proId: (json['proId'] as int?) ?? 0,
      reviewerName: (json['reviewerName'] as String?) ?? '',
      reviewDate: displayDate,
      category: null,
      tag: null,
      text: (json['reviewText'] as String?) ?? '',
      response: json['companyResponseText'] as String?,
      rating: (json['rating'] as int?) ?? 5,
      isVerified: (json['isVerified'] as bool?) ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'reviewId': id,
        'proId': proId,
        'reviewerName': reviewerName,
        'reviewText': text,
        if (response != null) 'companyResponseText': response,
        'rating': rating,
        'isVerified': isVerified,
      };

  Review copyWith({String? response}) => Review(
        id: id,
        proId: proId,
        reviewerName: reviewerName,
        reviewDate: reviewDate,
        category: category,
        tag: tag,
        text: text,
        response: response ?? this.response,
        rating: rating,
        isVerified: isVerified,
      );

  @override
  List<Object?> get props =>
      [id, proId, reviewerName, reviewDate, category, tag, text, response, rating, isVerified];
}

// ─── Mock data ────────────────────────────────────────────────────────────────

const List<Review> mockReviews = [
  Review(
    id: 1,
    proId: 0,
    reviewerName: 'Jennifer M.',
    reviewDate: 'May 31, 2026',
    category: 'Kitchen',
    tag: 'Kitchen remodel',
    text:
        'We used Serden to remodel our kitchen. The whole experience was wonderful — Dennis was so helpful and had great suggestions to help us make design choices that fit our vision and budget. Victor and Alex did most of the work and they were fantastic.',
    rating: 5,
    isVerified: true,
  ),
  Review(
    id: 2,
    proId: 0,
    reviewerName: 'Robert T.',
    reviewDate: 'May 14, 2026',
    category: 'Addition',
    tag: 'Home addition',
    text:
        'Very professional, up front about price, great communication and extremely high quality work. Our project manager David and his assistant Alex were on top of everything since day one.',
    response:
        "Thank you, Robert! David and Alex will be glad to hear this. We're so happy with how the addition turned out.",
    rating: 5,
    isVerified: true,
  ),
  Review(
    id: 3,
    proId: 0,
    reviewerName: 'Sarah K.',
    reviewDate: 'Apr 22, 2026',
    category: 'Bathroom',
    tag: 'Bathroom remodel',
    text:
        'We had the very best bathroom remodel experience with Serden. We received a handful of bids, theirs right in the middle on price but way above the rest on detail and professionalism.',
    rating: 5,
    isVerified: true,
  ),
  Review(
    id: 4,
    proId: 0,
    reviewerName: 'Marcus P.',
    reviewDate: 'Apr 9, 2026',
    category: 'Siding',
    tag: 'Siding',
    text:
        'Leo and his crew did an amazing job on the siding. Project manager David was easy to communicate with and very pleasant to deal with — answered every question with professionalism.',
    rating: 5,
    isVerified: true,
  ),
  Review(
    id: 5,
    proId: 0,
    reviewerName: 'Amanda C.',
    reviewDate: 'Mar 18, 2026',
    category: 'Kitchen',
    tag: 'Kitchen remodel',
    text:
        'From the very start, our designer Jasmine listened to our ideas and executed a more beautiful design than we had imagined. Andrew, Jacob, Alex, and Tim were extremely professional and our job site was always clean and tidy.',
    rating: 5,
    isVerified: true,
  ),
];
