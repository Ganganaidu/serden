import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/errors/failures.dart';
import '../models/review_model.dart';
import '../repository/review_repository.dart';

part 'reviews_state.dart';

class ReviewsCubit extends Cubit<ReviewsState> {
  final ReviewRepository _repository;

  ReviewsCubit({required ReviewRepository repository})
      : _repository = repository,
        super(const ReviewsInitial());

  ReviewsLoaded? get _loaded =>
      state is ReviewsLoaded ? state as ReviewsLoaded : null;

  Future<void> fetch(int proId) async {
    if (state is ReviewsLoading) return;
    emit(const ReviewsLoading());
    final result = await _repository.fetchReviews(proId);
    result.fold(
      (f) => emit(ReviewsError(f.message)),
      (r) => emit(ReviewsLoaded(
        reviews: r.reviews,
        averageRating: r.averageRating,
        totalCount: r.totalCount,
        star5Count: r.star5Count,
        star4Count: r.star4Count,
        star3Count: r.star3Count,
      )),
    );
  }

  Future<Either<Failure, void>> respond({
    required int reviewId,
    required String companyResponseText,
    required int currentUserId,
  }) async {
    final result = await _repository.respondToReview(
      reviewId: reviewId,
      companyResponseText: companyResponseText,
      currentUserId: currentUserId,
    );
    result.fold(
      (_) {},
      (_) {
        final loaded = _loaded;
        if (loaded == null) return;
        final next = loaded.reviews.map((r) {
          if (r.id != reviewId) return r;
          return r.copyWith(response: companyResponseText);
        }).toList();
        emit(ReviewsLoaded(
          reviews: next,
          averageRating: loaded.averageRating,
          totalCount: loaded.totalCount,
          star5Count: loaded.star5Count,
          star4Count: loaded.star4Count,
          star3Count: loaded.star3Count,
        ));
      },
    );
    return result;
  }

  Future<Either<Failure, void>> sendRequest({
    required int proId,
    required String toEmail,
    required String fromEmail,
    required String subject,
    required String message,
    String? reviewPageUrl,
  }) {
    return _repository.sendReviewRequest(
      proId: proId,
      toEmail: toEmail,
      fromEmail: fromEmail,
      subject: subject,
      message: message,
      reviewPageUrl: reviewPageUrl,
    );
  }
}
