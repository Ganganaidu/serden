import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_logger.dart';
import '../models/lead_model.dart';

abstract class LeadRepository {
  Future<Either<Failure, List<Lead>>> fetchLeads(
    int userId, {
    String? search,
    int pageIndex = 0,
    int pageSize = AppConstants.pageSize,
  });

  Future<Either<Failure, Lead>> fetchLeadDetail(int requestId, int userId);

  Future<Either<Failure, Lead>> createLead({
    required int userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? streetAddress,
    String? addressLine2,
    String? city,
    String? state,
    String? zipCode,
    String? requestText,
    String? categoryName,
    String? leadSource,
    double? leadCost,
    LeadStatus? status,
  });

  Future<Either<Failure, Lead>> updateLead(Lead lead, int userId);

  Future<Either<Failure, void>> updateLeadStatus(
      int requestId, int userId, LeadStatus status, {String? notes});

  Future<Either<Failure, void>> deleteLead(int requestId, int userId);

  Future<Either<Failure, List<LeadNote>>> fetchNotes(
      int requestId, int userId);

  Future<Either<Failure, LeadNote>> addNote(
      int requestId, int userId, String noteText);

  Future<Either<Failure, void>> deleteNote(
      int requestId, int userId, int noteId);

  Future<Either<Failure, List<LeadPhotoDto>>> fetchPhotos(
      int requestId, int userId);

  Future<Either<Failure, LeadPhotoDto>> uploadPhoto(
      int requestId, int userId, String filePath);

  Future<Either<Failure, void>> deletePhoto(
      int requestId, int userId, String blobPath);

  Future<Either<Failure, List<LeadHistory>>> fetchHistory(
      int requestId, int userId);
}

class LeadRepositoryImpl implements LeadRepository {
  final ApiClient _apiClient;
  static const bool _useMock = AppConfig.useMockData;

  LeadRepositoryImpl({required ApiClient apiClient}) : _apiClient = apiClient;

  @override
  Future<Either<Failure, List<Lead>>> fetchLeads(
    int userId, {
    String? search,
    int pageIndex = 0,
    int pageSize = AppConstants.pageSize,
  }) async {
    AppLogger.api('fetchLeads: userId=$userId');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return Right(mockLeads);
    }
    try {
      final response = await _apiClient.get(
        '/RequestQuotes/my-requests',
        queryParams: {
          'userId': userId,
          if (search != null && search.isNotEmpty) 'search': search,
          'statusGroup': 'all',
          'pageIndex': pageIndex,
          'pageSize': pageSize,
        },
      );
      final data = response.data as List<dynamic>;
      final leads =
          data.map((e) => Lead.fromJson(e as Map<String, dynamic>)).toList();
      AppLogger.api('fetchLeads: loaded ${leads.length} leads');
      return Right(leads);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('fetchLeads: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Lead>> fetchLeadDetail(
      int requestId, int userId) async {
    AppLogger.api('fetchLeadDetail: requestId=$requestId');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      final lead = mockLeads.firstWhere(
        (l) => l.requestId == requestId,
        orElse: () => mockLeads.first,
      );
      return Right(lead);
    }
    try {
      final response = await _apiClient.get(
        '/RequestQuotes/my-requests/$requestId',
        queryParams: {'userId': userId},
      );
      final lead = Lead.fromJson(response.data as Map<String, dynamic>);
      AppLogger.api('fetchLeadDetail: loaded requestId=${lead.requestId}');
      return Right(lead);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('fetchLeadDetail: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Lead>> createLead({
    required int userId,
    String? firstName,
    String? lastName,
    String? phone,
    String? email,
    String? streetAddress,
    String? addressLine2,
    String? city,
    String? state,
    String? zipCode,
    String? requestText,
    String? categoryName,
    String? leadSource,
    double? leadCost,
    LeadStatus? status,
  }) async {
    AppLogger.api('createLead: userId=$userId');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      final lead = Lead(
        requestId: mockLeads.length + 100,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        email: email,
        streetAddress: streetAddress,
        addressLine2: addressLine2,
        city: city,
        state: state,
        zipCode: zipCode,
        requestText: requestText,
        categoryName: categoryName,
        proId: 1,
        publicId: 'mock-new-${DateTime.now().millisecondsSinceEpoch}',
        createdDate: DateTime.now(),
        status: status ?? LeadStatus.newLead,
        leadSource: leadSource,
        leadCost: leadCost,
      );
      return Right(lead);
    }
    try {
      final response = await _apiClient.post(
        '/RequestQuotes/my-requests',
        queryParams: {'userId': userId},
        data: {
          if (firstName != null && firstName.isNotEmpty) 'firstName': firstName,
          if (lastName != null && lastName.isNotEmpty) 'lastName': lastName,
          if (phone != null && phone.isNotEmpty) 'phone': phone,
          if (email != null && email.isNotEmpty) 'email': email,
          if (streetAddress != null && streetAddress.isNotEmpty)
            'streetAddress': streetAddress,
          if (addressLine2 != null && addressLine2.isNotEmpty)
            'addressLine2': addressLine2,
          if (city != null && city.isNotEmpty) 'city': city,
          if (state != null && state.isNotEmpty) 'state': state,
          if (zipCode != null && zipCode.isNotEmpty) 'zipCode': zipCode,
          if (requestText != null && requestText.isNotEmpty)
            'requestText': requestText,
          if (categoryName != null && categoryName.isNotEmpty)
            'categoryName': categoryName,
          if (leadSource != null && leadSource.isNotEmpty)
            'leadSource': leadSource,
          if (leadCost != null) 'leadCost': leadCost,
          'status': (status ?? LeadStatus.newLead).apiValue,
          'createdDate': DateTime.now().toIso8601String(),
        },
      );
      final lead = Lead.fromJson(response.data as Map<String, dynamic>);
      AppLogger.api('createLead: created requestId=${lead.requestId}');
      return Right(lead);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('createLead: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Lead>> updateLead(Lead lead, int userId) async {
    AppLogger.api('updateLead: requestId=${lead.requestId}');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return Right(lead);
    }
    try {
      final response = await _apiClient.put(
        '/RequestQuotes/my-requests/${lead.requestId}',
        queryParams: {'userId': userId},
        data: {
          if (lead.firstName != null) 'firstName': lead.firstName,
          if (lead.lastName != null) 'lastName': lead.lastName,
          if (lead.phone != null) 'phone': lead.phone,
          if (lead.email != null) 'email': lead.email,
          if (lead.streetAddress != null) 'streetAddress': lead.streetAddress,
          if (lead.addressLine2 != null) 'addressLine2': lead.addressLine2,
          if (lead.city != null) 'city': lead.city,
          if (lead.state != null) 'state': lead.state,
          if (lead.zipCode != null) 'zipCode': lead.zipCode,
          if (lead.requestText != null) 'requestText': lead.requestText,
          if (lead.leadSource != null) 'leadSource': lead.leadSource,
          if (lead.leadCost != null) 'leadCost': lead.leadCost,
          'status': lead.status.apiValue,
          'createdDate': lead.createdDate.toIso8601String(),
        },
      );
      final updated = response.data != null
          ? Lead.fromJson(response.data as Map<String, dynamic>)
          : lead;
      AppLogger.api('updateLead: success requestId=${lead.requestId}');
      return Right(updated);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('updateLead: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> updateLeadStatus(
      int requestId, int userId, LeadStatus status, {String? notes}) async {
    AppLogger.api('updateLeadStatus: requestId=$requestId status=${status.apiValue}');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return const Right(null);
    }
    try {
      await _apiClient.patch(
        '/RequestQuotes/my-requests/$requestId',
        queryParams: {'userId': userId},
        data: {
          'status': status.apiValue,
          if (notes != null) 'notes': notes,
        },
      );
      AppLogger.api('updateLeadStatus: success requestId=$requestId');
      return const Right(null);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('updateLeadStatus: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteLead(int requestId, int userId) async {
    AppLogger.api('deleteLead: requestId=$requestId');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return const Right(null);
    }
    try {
      await _apiClient.delete(
        '/RequestQuotes/my-requests/$requestId',
        queryParams: {'userId': userId},
      );
      AppLogger.api('deleteLead: success requestId=$requestId');
      return const Right(null);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('deleteLead: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<LeadNote>>> fetchNotes(
      int requestId, int userId) async {
    AppLogger.api('fetchNotes: requestId=$requestId');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      return const Right([]);
    }
    try {
      final response = await _apiClient.get(
        '/RequestQuotes/my-requests/$requestId/notes',
        queryParams: {'userId': userId},
      );
      final data = response.data as List<dynamic>;
      return Right(data
          .map((e) => LeadNote.fromJson(e as Map<String, dynamic>))
          .toList());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('fetchNotes: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, LeadNote>> addNote(
      int requestId, int userId, String noteText) async {
    AppLogger.api('addNote: requestId=$requestId');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return Right(LeadNote(
        leadNoteId: DateTime.now().millisecondsSinceEpoch,
        requestId: requestId,
        noteText: noteText,
        createdDateUtc: DateTime.now().toUtc(),
      ));
    }
    try {
      final response = await _apiClient.post(
        '/RequestQuotes/my-requests/$requestId/notes',
        queryParams: {'userId': userId},
        data: {'noteText': noteText},
      );
      final note = LeadNote.fromJson(response.data as Map<String, dynamic>);
      AppLogger.api('addNote: created noteId=${note.leadNoteId}');
      return Right(note);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('addNote: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteNote(
      int requestId, int userId, int noteId) async {
    AppLogger.api('deleteNote: requestId=$requestId noteId=$noteId');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return const Right(null);
    }
    try {
      await _apiClient.delete(
        '/RequestQuotes/my-requests/$requestId/notes/$noteId',
        queryParams: {'userId': userId},
      );
      AppLogger.api('deleteNote: success noteId=$noteId');
      return const Right(null);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('deleteNote: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<LeadPhotoDto>>> fetchPhotos(
      int requestId, int userId) async {
    AppLogger.api('fetchPhotos: requestId=$requestId');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return const Right([]);
    }
    try {
      final response = await _apiClient.get(
        '/RequestQuotes/my-requests/$requestId/photos',
        queryParams: {'userId': userId},
      );
      final data = response.data as List<dynamic>;
      return Right(data
          .map((e) => LeadPhotoDto.fromJson(e as Map<String, dynamic>))
          .toList());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('fetchPhotos: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, LeadPhotoDto>> uploadPhoto(
      int requestId, int userId, String filePath) async {
    AppLogger.api('uploadPhoto: requestId=$requestId');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      return Right(LeadPhotoDto(
          fileName: 'mock.jpg',
          blobPath: 'mock/path',
          url: 'https://picsum.photos/200'));
    }
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      final response = await _apiClient.post(
        '/RequestQuotes/my-requests/$requestId/photos',
        queryParams: {'userId': userId},
        data: formData,
      );
      return Right(
          LeadPhotoDto.fromJson(response.data as Map<String, dynamic>));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('uploadPhoto: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deletePhoto(
      int requestId, int userId, String blobPath) async {
    AppLogger.api('deletePhoto: requestId=$requestId');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return const Right(null);
    }
    try {
      await _apiClient.delete(
        '/RequestQuotes/my-requests/$requestId/photos',
        queryParams: {'userId': userId, 'blobPath': blobPath},
      );
      return const Right(null);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('deletePhoto: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<LeadHistory>>> fetchHistory(
      int requestId, int userId) async {
    AppLogger.api('fetchHistory: requestId=$requestId');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      return Right([
        LeadHistory(
          leadHistoryId: 1,
          requestId: requestId,
          eventText: 'Lead added manually',
          createdDateUtc: DateTime.now().subtract(const Duration(hours: 2)),
        ),
      ]);
    }
    try {
      final response = await _apiClient.get(
        '/RequestQuotes/my-requests/$requestId/history',
        queryParams: {'userId': userId},
      );
      final data = response.data as List<dynamic>;
      return Right(data
          .map((e) => LeadHistory.fromJson(e as Map<String, dynamic>))
          .toList());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('fetchHistory: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }
}
