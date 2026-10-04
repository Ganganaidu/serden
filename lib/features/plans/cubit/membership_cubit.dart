import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/subscription_usage.dart';
import '../repository/subscription_repository.dart';

part 'membership_state.dart';

class MembershipCubit extends Cubit<MembershipState> {
  final SubscriptionRepository _repository;

  MembershipCubit({required SubscriptionRepository repository})
      : _repository = repository,
        super(const MembershipLoading());

  Future<void> load(int userId) async {
    emit(const MembershipLoading());
    final result = await _repository.fetchUsage(userId);
    // On failure fall back to the free plan so the card still renders.
    emit(MembershipLoaded(result.fold((_) => null, (u) => u)));
  }
}
