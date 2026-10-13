part of 'company_profile_cubit.dart';

abstract class CompanyProfileState extends Equatable {
  const CompanyProfileState();
  @override
  List<Object?> get props => [];
}

class CompanyProfileLoading extends CompanyProfileState {
  const CompanyProfileLoading();
}

class CompanyProfileLoaded extends CompanyProfileState {
  final CompanyProfile profile;
  final ProfileCatalogs catalogs;
  final bool isSaving;

  /// Increments after each successful save (triggers a one-shot snackbar).
  final int savedCount;

  final bool isUploadingLogo;
  final bool isUploadingPhoto;

  /// One-shot error text; the screen shows it and it clears on the next emit.
  final String? saveError;

  const CompanyProfileLoaded(
    this.profile,
    this.catalogs, {
    this.isSaving = false,
    this.savedCount = 0,
    this.isUploadingLogo = false,
    this.isUploadingPhoto = false,
    this.saveError,
  });

  CompanyProfileLoaded copyWith({
    CompanyProfile? profile,
    bool? isSaving,
    int? savedCount,
    bool? isUploadingLogo,
    bool? isUploadingPhoto,
    String? saveError,
  }) => CompanyProfileLoaded(
    profile ?? this.profile,
    catalogs,
    isSaving: isSaving ?? this.isSaving,
    savedCount: savedCount ?? this.savedCount,
    isUploadingLogo: isUploadingLogo ?? this.isUploadingLogo,
    isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
    saveError: saveError,
  );

  @override
  List<Object?> get props => [
    profile,
    catalogs,
    isSaving,
    savedCount,
    isUploadingLogo,
    isUploadingPhoto,
    saveError,
  ];
}

class CompanyProfileError extends CompanyProfileState {
  final String message;
  const CompanyProfileError(this.message);
  @override
  List<Object?> get props => [message];
}
