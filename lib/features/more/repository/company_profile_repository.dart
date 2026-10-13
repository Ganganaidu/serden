import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_logger.dart';
import '../models/company_profile_model.dart';

/// Mirrors the web "My company" page (Serden.Web/Components/Pages/Users/MyCompany.razor):
/// the profile, categories, highlights and areas served each have their own endpoint.
abstract class CompanyProfileRepository {
  /// The signed-in user's listing, or a blank (new) one when they have none.
  Future<Either<Failure, CompanyProfile>> fetchProfile(int userId);

  /// Categories, highlights and states the form picks from.
  Future<Either<Failure, ProfileCatalogs>> fetchCatalogs();

  /// Creates (no `proId`) or updates the listing, then saves its categories,
  /// highlights and areas served. Returns the listing as stored.
  Future<Either<Failure, CompanyProfile>> saveProfile(CompanyProfile profile);

  /// Uploads [filePath] as the logo; returns the bare filename now stored.
  Future<Either<Failure, String>> uploadLogo(int proId, String filePath);

  Future<Either<Failure, Unit>> deleteLogo(int proId);

  Future<Either<Failure, ProPhoto>> uploadProjectPhoto(
    int proId,
    String filePath,
  );

  Future<Either<Failure, Unit>> deleteProjectPhoto(int proId, int photoId);

  /// Location suggestions for "Areas served".
  Future<Either<Failure, List<ServiceArea>>> searchLocations(String query);

  /// `(city, state)` for a ZIP code, or null when unknown.
  Future<(String, String)?> lookupZip(String zip);
}

class CompanyProfileRepositoryImpl implements CompanyProfileRepository {
  final ApiClient _apiClient;

  CompanyProfileRepositoryImpl({required ApiClient apiClient})
    : _apiClient = apiClient;

  Future<Either<Failure, T>> _guard<T>(
    String name,
    Future<T> Function() body,
  ) async {
    try {
      return Right(await body());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('CompanyProfileRepository.$name unexpected: $e');
      return const Left(UnexpectedFailure());
    }
  }

  List<int> _ids(dynamic data) => (data as List<dynamic>? ?? const [])
      .whereType<num>()
      .map((n) => n.toInt())
      .toList();

  // ── Read ────────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, CompanyProfile>> fetchProfile(int userId) =>
      _guard('fetchProfile', () async {
        AppLogger.api('CompanyProfileRepository.fetchProfile: userId=$userId');
        CompanyProfile pro;
        try {
          final res = await _apiClient.get('/Pros/user/$userId');
          pro = CompanyProfile.fromJson(res.data as Map<String, dynamic>);
        } on ServerException catch (e) {
          // No listing yet: the form starts blank and saving creates one.
          if (e.statusCode == 404) return CompanyProfile(userId: userId);
          rethrow;
        }
        final proId = pro.proId!;

        final categories = await _apiClient.get('/Pros/$proId/categories');
        final tags = await _apiClient.get('/Pros/$proId/servicetags');

        // Failing to load these must not look like "none selected": saving
        // would then erase them, so these errors propagate.
        var areasReady = false;
        late List<ServiceArea> areas;
        try {
          final res = await _apiClient.get('/Pros/$proId/service-areas');
          final data = res.data as Map<String, dynamic>;
          areasReady = data['ready'] as bool? ?? false;
          areas = (data['items'] as List<dynamic>? ?? const [])
              .map((e) => ServiceArea.fromAreaJson(e as Map<String, dynamic>))
              .toList();
        } on ServerException catch (e) {
          if (e.statusCode != 404) rethrow;
          // Older API without standardized locations: plain free-text areas.
          final res = await _apiClient.get('/Pros/$proId/areas-served');
          areas = (res.data as List<dynamic>? ?? const [])
              .map((e) => ServiceArea.fromAreaJson(e as Map<String, dynamic>))
              .toList();
        }

        // Photos are display-only; a failure here shouldn't block the form.
        var photos = <ProPhoto>[];
        try {
          final res = await _apiClient.get('/Pros/$proId/project-photos');
          photos = (res.data as List<dynamic>)
              .map((e) => ProPhoto.fromJson(e as Map<String, dynamic>))
              .toList();
        } catch (e) {
          AppLogger.error('fetchProfile: project photos failed: $e');
        }

        return pro.copyWith(
          categoryIds: _ids(categories.data),
          serviceTagIds: _ids(tags.data),
          serviceAreas: areas,
          areasReady: areasReady,
          projectPhotos: photos,
        );
      });

  @override
  Future<Either<Failure, ProfileCatalogs>> fetchCatalogs() => _guard(
    'fetchCatalogs',
    () async {
      final categories = <ProfileOption>[];
      try {
        final cats = await _apiClient.get('/directory-categories');
        final catData = cats.data as Map<String, dynamic>;
        for (final g in (catData['groups'] as List<dynamic>? ?? const [])) {
          final group = g as Map<String, dynamic>;
          for (final c in (group['categories'] as List<dynamic>? ?? const [])) {
            categories.add(
              _category(c as Map<String, dynamic>, group['name'] as String?),
            );
          }
        }
        for (final c in (catData['ungrouped'] as List<dynamic>? ?? const [])) {
          categories.add(_category(c as Map<String, dynamic>, null));
        }
      } on ServerException catch (e) {
        if (e.statusCode != 404) rethrow;
        // Older API: the company categories (the table a company's
        // category links point to), without groups.
        final cats = await _apiClient.get(
          '/ProCategories',
          queryParams: {'isActive': true},
        );
        for (final c in (cats.data as List<dynamic>)) {
          final m = c as Map<String, dynamic>;
          if (m['isActive'] == false) continue;
          categories.add(
            ProfileOption(
              id: (m['proCategoryId'] as num).toInt(),
              name: m['categoryName'] as String? ?? '',
            ),
          );
        }
      }
      categories.sort(
        (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
      );

      final tags = await _apiClient.get('/servicetags');
      final highlights = (tags.data as List<dynamic>).map((t) {
        final m = t as Map<String, dynamic>;
        return ProfileOption(
          id: (m['serviceTagID'] as num).toInt(),
          name: m['tagName'] as String? ?? '',
          subtitle: m['description'] as String?,
        );
      }).toList();

      final st = await _apiClient.get('/states');
      final states = <String, String>{
        for (final s in (st.data as List<dynamic>))
          (s as Map<String, dynamic>)['state'] as String:
              s['stateName'] as String? ?? s['state'] as String,
      };

      return ProfileCatalogs(
        categories: categories,
        highlights: highlights,
        states: states,
      );
    },
  );

  ProfileOption _category(Map<String, dynamic> c, String? groupName) =>
      ProfileOption(
        id: (c['id'] as num).toInt(),
        name: c['name'] as String? ?? '',
        subtitle: (c['groupName'] as String?) ?? groupName,
      );

  // ── Save ────────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, CompanyProfile>> saveProfile(CompanyProfile profile) =>
      _guard('saveProfile', () async {
        AppLogger.api(
          'CompanyProfileRepository.saveProfile: proId=${profile.proId}',
        );
        var proId = profile.proId ?? 0;
        if (proId == 0) {
          final res = await _apiClient.post('/Pros', data: profile.toJson());
          proId = ((res.data as Map<String, dynamic>)['proId'] as num).toInt();
        } else {
          await _apiClient.put('/Pros/$proId', data: profile.toJson());
        }

        await _apiClient.post(
          '/Pros/$proId/categories',
          data: profile.categoryIds,
        );
        await _apiClient.post(
          '/Pros/$proId/servicetags',
          data: profile.serviceTagIds,
        );

        if (profile.areasReady) {
          await _apiClient.put(
            '/Pros/$proId/service-areas',
            data: {
              'locationIds': [
                for (final a in profile.serviceAreas)
                  if (a.locationId != null) a.locationId,
              ],
              // Older entries no location matches stay as they are.
              'keepEntryIds': [
                for (final a in profile.serviceAreas)
                  if (a.locationId == null && a.id > 0) a.id,
              ],
            },
          );
        } else {
          await _apiClient.post(
            '/Pros/$proId/areas-served',
            data: [for (final a in profile.serviceAreas) a.areaName],
          );
        }

        // Read back what the server stored (slug, photos, area ids, …).
        final fresh = await fetchProfile(profile.userId ?? 0);
        return fresh.fold(
          (f) => throw ServerException(f.message),
          (p) => p.isNew ? profile.copyWith(proId: proId) : p,
        );
      });

  // ── Images ──────────────────────────────────────────────────────────────────

  Future<MultipartFile> _imagePart(String filePath) async {
    final name = filePath.split(RegExp(r'[\\/]')).last;
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    // The API accepts jpg, jpeg, png, gif, webp (bmp for project photos) and
    // checks the content type, so send both explicitly.
    final type = switch (ext) {
      'png' => 'png',
      'gif' => 'gif',
      'webp' => 'webp',
      'bmp' => 'bmp',
      _ => 'jpeg',
    };
    return MultipartFile.fromFile(
      filePath,
      filename: name,
      contentType: DioMediaType('image', type),
    );
  }

  @override
  Future<Either<Failure, String>> uploadLogo(int proId, String filePath) =>
      _guard('uploadLogo', () async {
        final formData = FormData.fromMap({'file': await _imagePart(filePath)});
        final res = await _apiClient.post(
          '/Pros/$proId/upload-image',
          data: formData,
        );
        final name = (res.data as Map<String, dynamic>)['imageUrl'] as String?;
        // The API answers 200 with an empty name when blob storage rejects it.
        if (name == null || name.isEmpty) {
          throw ServerException(
            'The logo could not be saved. Please try again.',
          );
        }
        return name;
      });

  @override
  Future<Either<Failure, Unit>> deleteLogo(int proId) =>
      _guard('deleteLogo', () async {
        await _apiClient.delete('/Pros/$proId/delete-image');
        return unit;
      });

  @override
  Future<Either<Failure, ProPhoto>> uploadProjectPhoto(
    int proId,
    String filePath,
  ) => _guard('uploadProjectPhoto', () async {
    final formData = FormData.fromMap({'file': await _imagePart(filePath)});
    final res = await _apiClient.post(
      '/Pros/$proId/project-photos',
      data: formData,
    );
    return ProPhoto.fromJson(res.data as Map<String, dynamic>);
  });

  @override
  Future<Either<Failure, Unit>> deleteProjectPhoto(int proId, int photoId) =>
      _guard('deleteProjectPhoto', () async {
        await _apiClient.delete('/Pros/$proId/project-photos/$photoId');
        return unit;
      });

  // ── Lookups ─────────────────────────────────────────────────────────────────

  @override
  Future<Either<Failure, List<ServiceArea>>> searchLocations(String query) =>
      _guard('searchLocations', () async {
        try {
          final res = await _apiClient.get(
            '/Locations/search',
            queryParams: {'q': query, 'limit': 8},
          );
          final items =
              (res.data as Map<String, dynamic>)['items'] as List<dynamic>? ??
              const [];
          return items
              .map(
                (e) => ServiceArea.fromLocationJson(e as Map<String, dynamic>),
              )
              .toList();
        } on ServerException catch (e) {
          if (e.statusCode != 404) rethrow;
          // Older API: search the ZIP database, as the web form did before
          // standardized locations. Digits find ZIP codes, text finds cities.
          final res = await _apiClient.get(
            '/zipcodes/search',
            queryParams: {'term': query},
          );
          final seen = <String>{};
          final out = <ServiceArea>[];
          for (final e in (res.data as List<dynamic>)) {
            final m = e as Map<String, dynamic>;
            final zip = m['zipCode'] as String? ?? '';
            final city = m['city'] as String? ?? '';
            final state = m['state'] as String? ?? '';
            final area = zip.isNotEmpty
                ? ServiceArea(areaName: zip, typeLabel: 'ZIP code')
                : ServiceArea(areaName: '$city, $state', typeLabel: 'City');
            if (seen.add(area.areaName)) out.add(area);
          }
          return out;
        }
      });

  @override
  Future<(String, String)?> lookupZip(String zip) async {
    try {
      final res = await _apiClient.get('/zipcodes/$zip');
      final m = res.data as Map<String, dynamic>;
      final city = m['city'] as String? ?? '';
      // An unknown ZIP comes back as blank fields.
      if (city.isEmpty) return null;
      return (city, m['state'] as String? ?? '');
    } catch (_) {
      return null; // Only a convenience; city and state can be typed.
    }
  }
}
