import 'package:dartz/dartz.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_logger.dart';
import '../models/client_model.dart';

abstract class ClientRepository {
  Future<Either<Failure, List<Client>>> fetchClients(
    int proId, {
    String? searchTerm,
    int pageIndex = 1,
    int pageSize = AppConstants.pageSize,
  });

  Future<Either<Failure, Client>> fetchClientDetail(int clientId);

  Future<Either<Failure, Client>> updateClient(Client client);

  Future<Either<Failure, void>> deleteClient(int clientId);

  Future<Either<Failure, Client>> createClient({
    required int proId,
    required String name,
    String? email,
    String? phoneMobile,
    String? phoneOther,
    String? address,
    String? address2,
    String? city,
    String? state,
    String? zipCode,
    String? privateNotes,
  });
}

class ClientRepositoryImpl implements ClientRepository {
  final ApiClient _apiClient;
  static const bool _useMock = AppConfig.useMockData;

  ClientRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<Either<Failure, List<Client>>> fetchClients(
    int proId, {
    String? searchTerm,
    int pageIndex = 1,
    int pageSize = AppConstants.pageSize,
  }) async {
    AppLogger.api('fetchClients: proId=$proId');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return Right(mockClients);
    }
    try {
      final response = await _apiClient.get(
        '/Clients/pro/$proId',
        queryParams: {
          if (searchTerm != null && searchTerm.isNotEmpty)
            'searchTerm': searchTerm,
          'sortBy': 'name',
          'sortDirection': 'asc',
          'pageIndex': pageIndex,
          'pageSize': pageSize,
        },
      );
      final data = response.data as List<dynamic>;
      final clients = data
          .map((e) => Client.fromJson(e as Map<String, dynamic>))
          .toList();
      AppLogger.api('fetchClients: loaded ${clients.length} clients');
      return Right(clients);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('fetchClients: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Client>> fetchClientDetail(int clientId) async {
    AppLogger.api('fetchClientDetail: clientId=$clientId');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      final client = mockClients.firstWhere(
        (c) => c.clientId == clientId,
        orElse: () => mockClients.first,
      );
      return Right(client);
    }
    try {
      final response = await _apiClient.get('/Clients/$clientId');
      final client = Client.fromJson(response.data as Map<String, dynamic>);
      AppLogger.api('fetchClientDetail: loaded clientId=${client.clientId}');
      return Right(client);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('fetchClientDetail: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Client>> updateClient(Client client) async {
    AppLogger.api('updateClient: clientId=${client.clientId}');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return Right(client);
    }
    try {
      final response = await _apiClient.put(
        '/Clients/${client.clientId}',
        data: {
          'clientId': client.clientId,
          'proId': client.proId,
          if (client.publicId != null) 'publicId': client.publicId,
          'name': client.name,
          if (client.email != null) 'email': client.email,
          if (client.phoneMobile != null) 'phoneMobile': client.phoneMobile,
          if (client.phoneOther != null) 'phoneOther': client.phoneOther,
          if (client.address != null) 'address': client.address,
          if (client.address2 != null) 'address2': client.address2,
          if (client.city != null) 'city': client.city,
          if (client.state != null) 'state': client.state,
          if (client.zipCode != null) 'zipCode': client.zipCode,
          if (client.privateNotes != null) 'privateNotes': client.privateNotes,
          'isActive': client.isActive,
          if (client.createdDate != null)
            'createdDate': client.createdDate!.toIso8601String(),
        },
      );
      // PUT returns 200 with no body — return the updated client we sent
      final updated = response.data != null
          ? Client.fromJson(response.data as Map<String, dynamic>)
          : client;
      AppLogger.api('updateClient: success clientId=${client.clientId}');
      return Right(updated);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('updateClient: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteClient(int clientId) async {
    AppLogger.api('deleteClient: clientId=$clientId');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 500));
      return const Right(null);
    }
    try {
      await _apiClient.delete('/Clients/$clientId');
      AppLogger.api('deleteClient: success clientId=$clientId');
      return const Right(null);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('deleteClient: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Client>> createClient({
    required int proId,
    required String name,
    String? email,
    String? phoneMobile,
    String? phoneOther,
    String? address,
    String? address2,
    String? city,
    String? state,
    String? zipCode,
    String? privateNotes,
  }) async {
    AppLogger.api('createClient: proId=$proId name=$name');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 800));
      final newClient = Client(
        clientId: mockClients.length + 1,
        proId: proId,
        name: name,
        email: email,
        phoneMobile: phoneMobile,
        phoneOther: phoneOther,
        address: address,
        address2: address2,
        city: city,
        state: state,
        zipCode: zipCode,
        privateNotes: privateNotes,
        isActive: true,
        createdDate: DateTime.now(),
      );
      return Right(newClient);
    }
    try {
      final response = await _apiClient.post(
        '/Clients',
        data: {
          'proId': proId,
          'name': name,
          if (email != null && email.isNotEmpty) 'email': email,
          if (phoneMobile != null && phoneMobile.isNotEmpty)
            'phoneMobile': phoneMobile,
          if (phoneOther != null && phoneOther.isNotEmpty)
            'phoneOther': phoneOther,
          if (address != null && address.isNotEmpty) 'address': address,
          if (address2 != null && address2.isNotEmpty) 'address2': address2,
          if (city != null && city.isNotEmpty) 'city': city,
          if (state != null && state.isNotEmpty) 'state': state,
          if (zipCode != null && zipCode.isNotEmpty) 'zipCode': zipCode,
          if (privateNotes != null && privateNotes.isNotEmpty)
            'privateNotes': privateNotes,
          'isActive': true,
        },
      );
      final client = Client.fromJson(response.data as Map<String, dynamic>);
      AppLogger.api('createClient: created clientId=${client.clientId}');
      return Right(client);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('createClient: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }
}
