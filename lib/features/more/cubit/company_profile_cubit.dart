import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/company_profile_model.dart';
import '../repository/company_profile_repository.dart';

part 'company_profile_state.dart';

class CompanyProfileCubit extends Cubit<CompanyProfileState> {
  final CompanyProfileRepository _repository;

  CompanyProfileCubit({required CompanyProfileRepository repository})
      : _repository = repository,
        super(const CompanyProfileLoading());

  Future<void> load(int userId) async {
    emit(const CompanyProfileLoading());
    final result = await _repository.fetchProfile(userId);
    result.fold(
      (failure) => emit(CompanyProfileError(failure.message)),
      (profile) => emit(CompanyProfileLoaded(profile)),
    );
  }

  Future<void> save(CompanyProfile updated) async {
    final current = state;
    if (current is! CompanyProfileLoaded) return;
    emit(current.copyWith(isSaving: true, justSaved: false));
    final result = await _repository.updateProfile(updated);
    result.fold(
      (failure) => emit(
          current.copyWith(isSaving: false, saveError: failure.message)),
      (profile) => emit(CompanyProfileLoaded(profile, justSaved: true)),
    );
  }

  Future<void> uploadLogo(int proId, String filePath) async {
    final current = state;
    if (current is! CompanyProfileLoaded) return;
    emit(current.copyWith(isUploadingLogo: true));
    final result = await _repository.uploadLogo(proId, filePath);
    result.fold(
      (failure) => emit(current.copyWith(
          isUploadingLogo: false, saveError: failure.message)),
      (logoFileName) => emit(current.copyWith(
        isUploadingLogo: false,
        profile: current.profile.copyWith(proLogo: logoFileName),
      )),
    );
  }

  Future<void> addProjectPhoto(int proId, String filePath) async {
    final current = state;
    if (current is! CompanyProfileLoaded) return;
    emit(current.copyWith(isUploadingPhoto: true));
    final result = await _repository.uploadProjectPhoto(proId, filePath);
    result.fold(
      (failure) => emit(current.copyWith(
          isUploadingPhoto: false, saveError: failure.message)),
      (photo) {
        final updated = [...current.profile.projectPhotos, photo];
        emit(current.copyWith(
          isUploadingPhoto: false,
          profile: current.profile.copyWith(projectPhotos: updated),
        ));
      },
    );
  }
}
