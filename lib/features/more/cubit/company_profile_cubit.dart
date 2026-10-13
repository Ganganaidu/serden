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
    final catalogs = await _repository.fetchCatalogs();
    final profile = await _repository.fetchProfile(userId);
    catalogs.fold(
      (failure) => emit(CompanyProfileError(failure.message)),
      (c) => profile.fold(
        (failure) => emit(CompanyProfileError(failure.message)),
        (p) => emit(CompanyProfileLoaded(p, c)),
      ),
    );
  }

  /// Saves the listing. [pendingLogoPath] is a logo picked before the listing
  /// existed; it is uploaded once the listing has an id.
  Future<void> save(CompanyProfile updated, {String? pendingLogoPath}) async {
    final current = state;
    if (current is! CompanyProfileLoaded) return;
    emit(current.copyWith(isSaving: true));
    final result = await _repository.saveProfile(updated);
    await result.fold(
      (failure) async =>
          emit(current.copyWith(isSaving: false, saveError: failure.message)),
      (saved) async {
        var profile = saved;
        String? warning;
        if (pendingLogoPath != null && saved.proId != null) {
          final logo = await _repository.uploadLogo(
            saved.proId!,
            pendingLogoPath,
          );
          logo.fold(
            (f) => warning =
                'Your listing was saved, but the logo could not be uploaded: ${f.message}',
            (name) => profile = profile.copyWith(proLogo: name),
          );
        }
        emit(
          CompanyProfileLoaded(
            profile,
            current.catalogs,
            savedCount: current.savedCount + 1,
            saveError: warning,
          ),
        );
      },
    );
  }

  Future<void> uploadLogo(String filePath) async {
    final current = state;
    if (current is! CompanyProfileLoaded || current.profile.isNew) return;
    emit(current.copyWith(isUploadingLogo: true));
    final result = await _repository.uploadLogo(
      current.profile.proId!,
      filePath,
    );
    result.fold(
      (failure) => emit(
        current.copyWith(isUploadingLogo: false, saveError: failure.message),
      ),
      (name) => emit(
        current.copyWith(
          isUploadingLogo: false,
          profile: current.profile.copyWith(proLogo: name),
        ),
      ),
    );
  }

  Future<void> removeLogo() async {
    final current = state;
    if (current is! CompanyProfileLoaded || current.profile.isNew) return;
    emit(current.copyWith(isUploadingLogo: true));
    final result = await _repository.deleteLogo(current.profile.proId!);
    result.fold(
      (failure) => emit(
        current.copyWith(isUploadingLogo: false, saveError: failure.message),
      ),
      (_) => emit(
        current.copyWith(
          isUploadingLogo: false,
          profile: current.profile.copyWith(clearLogo: true),
        ),
      ),
    );
  }

  Future<void> addProjectPhotos(List<String> filePaths) async {
    var current = state;
    if (current is! CompanyProfileLoaded || current.profile.isNew) return;
    emit(current.copyWith(isUploadingPhoto: true));
    var profile = current.profile;
    String? error;
    for (final path in filePaths) {
      final result = await _repository.uploadProjectPhoto(profile.proId!, path);
      result.fold(
        (failure) => error = failure.message,
        (photo) => profile = profile.copyWith(
          projectPhotos: [photo, ...profile.projectPhotos],
        ),
      );
    }
    emit(
      current.copyWith(
        isUploadingPhoto: false,
        profile: profile,
        saveError: error,
      ),
    );
  }

  Future<void> deleteProjectPhoto(int photoId) async {
    final current = state;
    if (current is! CompanyProfileLoaded || current.profile.isNew) return;
    final result = await _repository.deleteProjectPhoto(
      current.profile.proId!,
      photoId,
    );
    result.fold(
      (failure) => emit(current.copyWith(saveError: failure.message)),
      (_) => emit(
        current.copyWith(
          profile: current.profile.copyWith(
            projectPhotos: [
              for (final p in current.profile.projectPhotos)
                if (p.photoId != photoId) p,
            ],
          ),
        ),
      ),
    );
  }

  Future<List<ServiceArea>> searchLocations(String query) async {
    final result = await _repository.searchLocations(query);
    return result.getOrElse(() => const []);
  }

  Future<(String, String)?> lookupZip(String zip) => _repository.lookupZip(zip);
}
