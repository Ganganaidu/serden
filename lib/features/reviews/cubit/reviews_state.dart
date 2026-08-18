part of 'reviews_cubit.dart';

abstract class ReviewsState extends Equatable {
  const ReviewsState();
  @override
  List<Object?> get props => [];
}

class ReviewsInitial extends ReviewsState {
  const ReviewsInitial();
}

class ReviewsLoading extends ReviewsState {
  const ReviewsLoading();
}

class ReviewsLoaded extends ReviewsState {
  final List<Review> reviews;
  final double averageRating;
  final int totalCount;
  final int star5Count;
  final int star4Count;
  final int star3Count;

  const ReviewsLoaded({
    required this.reviews,
    required this.averageRating,
    required this.totalCount,
    required this.star5Count,
    required this.star4Count,
    required this.star3Count,
  });

  int get awaitingResponse => reviews.where((r) => r.response == null).length;

  @override
  List<Object?> get props =>
      [reviews, averageRating, totalCount, star5Count, star4Count, star3Count];
}

class ReviewsError extends ReviewsState {
  final String message;
  const ReviewsError(this.message);
  @override
  List<Object?> get props => [message];
}
