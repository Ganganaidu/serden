part of 'markups_cubit.dart';

abstract class MarkupsState {
  const MarkupsState();
}

class MarkupsInitial extends MarkupsState {
  const MarkupsInitial();
}

class MarkupsLoading extends MarkupsState {
  const MarkupsLoading();
}

class MarkupsLoaded extends MarkupsState {
  final List<MarkupTemplate> templates;
  const MarkupsLoaded(this.templates);
}

class MarkupsError extends MarkupsState {
  final String message;
  const MarkupsError(this.message);
}
