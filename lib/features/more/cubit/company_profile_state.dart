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
  final bool isSaving;

  /// Briefly true after a successful profile save (triggers one-shot snackbar).
  final bool justSaved;

  final bool isUploadingLogo;
  final bool isUploadingPhoto;

  final String? saveError;

  const CompanyProfileLoaded(
    this.profile, {
    this.isSaving = false,
    this.justSaved = false,
    this.isUploadingLogo = false,
    this.isUploadingPhoto = false,
    this.saveError,
  });

  CompanyProfileLoaded copyWith({
    CompanyProfile? profile,
    bool? isSaving,
    bool? justSaved,
    bool? isUploadingLogo,
    bool? isUploadingPhoto,
    String? saveError,
  }) =>
      CompanyProfileLoaded(
        profile ?? this.profile,
        isSaving: isSaving ?? this.isSaving,
        justSaved: justSaved ?? this.justSaved,
        isUploadingLogo: isUploadingLogo ?? this.isUploadingLogo,
        isUploadingPhoto: isUploadingPhoto ?? this.isUploadingPhoto,
        saveError: saveError,
      );

  @override
  List<Object?> get props => [
        profile,
        isSaving,
        justSaved,
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
