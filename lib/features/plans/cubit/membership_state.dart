part of 'membership_cubit.dart';

sealed class MembershipState extends Equatable {
  const MembershipState();
  @override
  List<Object?> get props => [];
}

class MembershipLoading extends MembershipState {
  const MembershipLoading();
}

class MembershipLoaded extends MembershipState {
  /// Null when the usage call failed — treat as the Basic plan.
  final SubscriptionUsage? usage;
  const MembershipLoaded(this.usage);
  @override
  List<Object?> get props => [usage];
}
