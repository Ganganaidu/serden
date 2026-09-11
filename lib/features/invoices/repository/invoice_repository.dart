import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';

import '../../../core/config/app_config.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/errors/exceptions.dart';
import '../../../core/errors/failures.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/app_logger.dart';
import '../models/invoice_model.dart';

abstract class InvoiceRepository {
  Future<Either<Failure, List<InvoiceSummary>>> fetchInvoices(
    int proId, {
    String? searchTerm,
    String? status,
    String sortBy = 'date',
    String sortDirection = 'desc',
    int pageIndex = 1,
    int pageSize = AppConstants.pageSize,
  });

  Future<Either<Failure, Invoice>> fetchInvoiceDetail(int invoiceId);

  Future<Either<Failure, String>> fetchNextNumber(int proId);

  Future<Either<Failure, Invoice>> createInvoice(Invoice invoice);

  Future<Either<Failure, Invoice>> updateInvoice(Invoice invoice);

  Future<Either<Failure, void>> deleteInvoice(int invoiceId);

  Future<Either<Failure, void>> sendInvoice(int invoiceId);

  Future<Either<Failure, void>> markPaid(String invoicePublicId);

  Future<Either<Failure, InvoicePayment>> recordPayment(
    String invoicePublicId, {
    required DateTime paymentDate,
    required double amount,
    String? paymentMethod,
    String? referenceNumber,
    String? notes,
  });

  Future<Either<Failure, List<InvoicePayment>>> fetchPayments(
      String invoicePublicId);

  Future<Either<Failure, void>> uploadPhoto(
      String invoicePublicId, String filePath);

  Future<Either<Failure, void>> uploadFile(
      String invoicePublicId, String filePath);
}

class InvoiceRepositoryImpl implements InvoiceRepository {
  final ApiClient _apiClient;
  static const bool _useMock = AppConfig.useMockData;

  InvoiceRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  @override
  Future<Either<Failure, List<InvoiceSummary>>> fetchInvoices(
    int proId, {
    String? searchTerm,
    String? status,
    String sortBy = 'date',
    String sortDirection = 'desc',
    int pageIndex = 1,
    int pageSize = AppConstants.pageSize,
  }) async {
    AppLogger.api('fetchInvoices: proId=$proId status=$status');
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return Right(mockInvoices);
    }
    try {
      final response = await _apiClient.get(
        '/Invoices/pro/$proId',
        queryParams: {
          if (searchTerm != null && searchTerm.isNotEmpty)
            'searchTerm': searchTerm,
          if (status != null && status.isNotEmpty) 'status': status,
          'sortBy': sortBy,
          'sortDirection': sortDirection,
          'pageIndex': pageIndex,
          'pageSize': pageSize,
        },
      );
      final data = response.data as List<dynamic>;
      final invoices = data
          .map((e) => InvoiceSummary.fromJson(e as Map<String, dynamic>))
          .toList();
      AppLogger.api('fetchInvoices: loaded ${invoices.length} invoices');
      return Right(invoices);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('fetchInvoices: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Invoice>> fetchInvoiceDetail(int invoiceId) async {
    AppLogger.api('fetchInvoiceDetail: invoiceId=$invoiceId');
    try {
      final response = await _apiClient.get('/Invoices/$invoiceId');
      final invoice = Invoice.fromJson(response.data as Map<String, dynamic>);
      AppLogger.api(
          'fetchInvoiceDetail: loaded invoiceId=${invoice.invoiceId}');
      return Right(invoice);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('fetchInvoiceDetail: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, String>> fetchNextNumber(int proId) async {
    AppLogger.api('fetchNextNumber: proId=$proId');
    try {
      final response =
          await _apiClient.get('/Invoices/pro/$proId/next-number');
      return Right(response.data.toString());
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('fetchNextNumber: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Invoice>> createInvoice(Invoice invoice) async {
    AppLogger.api('createInvoice: proId=${invoice.proId}');
    try {
      final response = await _apiClient.post(
        '/Invoices',
        data: {
          'proId': invoice.proId,
          if (invoice.clientId != null) 'clientId': invoice.clientId,
          'invoiceDate': invoice.invoiceDate.toIso8601String(),
          if (invoice.daysToPay != null) 'daysToPay': invoice.daysToPay,
          if (invoice.poNumber != null && invoice.poNumber!.isNotEmpty)
            'poNumber': invoice.poNumber,
          'groupItemsIntoSections': invoice.groupItemsIntoSections,
          'subtotal': invoice.subtotal,
          if (invoice.markupType != null) 'markupType': invoice.markupType,
          if (invoice.markupValue != null) 'markupValue': invoice.markupValue,
          if (invoice.discountType != null) 'discountType': invoice.discountType,
          if (invoice.discountValue != null)
            'discountValue': invoice.discountValue,
          if (invoice.depositType != null) 'depositType': invoice.depositType,
          if (invoice.depositValue != null) 'depositValue': invoice.depositValue,
          if (invoice.taxName != null) 'taxName': invoice.taxName,
          if (invoice.taxRate != null) 'taxRate': invoice.taxRate,
          'total': invoice.total,
          'showClientSignature': invoice.showClientSignature,
          'showMySignature': invoice.showMySignature,
          if (invoice.notes != null && invoice.notes!.isNotEmpty)
            'notes': invoice.notes,
          if (invoice.privateNotes != null && invoice.privateNotes!.isNotEmpty)
            'privateNotes': invoice.privateNotes,
          'sections': invoice.sections.map((e) => e.toJson()).toList(),
          'lineItems': invoice.lineItems.map((e) => e.toJson()).toList(),
        },
      );
      final created = Invoice.fromJson(response.data as Map<String, dynamic>);
      AppLogger.api('createInvoice: created invoiceId=${created.invoiceId}');
      return Right(created);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('createInvoice: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, Invoice>> updateInvoice(Invoice invoice) async {
    AppLogger.api('updateInvoice: invoiceId=${invoice.invoiceId}');
    try {
      final response = await _apiClient.put(
        '/Invoices/${invoice.invoiceId}',
        data: invoice.toJson(),
      );
      final updated = response.data != null
          ? Invoice.fromJson(response.data as Map<String, dynamic>)
          : invoice;
      AppLogger.api('updateInvoice: success invoiceId=${invoice.invoiceId}');
      return Right(updated);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('updateInvoice: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteInvoice(int invoiceId) async {
    AppLogger.api('deleteInvoice: invoiceId=$invoiceId');
    try {
      await _apiClient.delete('/Invoices/$invoiceId');
      AppLogger.api('deleteInvoice: success invoiceId=$invoiceId');
      return const Right(null);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('deleteInvoice: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> sendInvoice(int invoiceId) async {
    AppLogger.api('sendInvoice: invoiceId=$invoiceId');
    try {
      await _apiClient.post('/Invoices/$invoiceId/send');
      AppLogger.api('sendInvoice: success invoiceId=$invoiceId');
      return const Right(null);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('sendInvoice: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> markPaid(String invoicePublicId) async {
    AppLogger.api('markPaid: invoicePublicId=$invoicePublicId');
    try {
      await _apiClient.post('/Invoices/$invoicePublicId/mark-paid');
      AppLogger.api('markPaid: success invoicePublicId=$invoicePublicId');
      return const Right(null);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('markPaid: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, InvoicePayment>> recordPayment(
    String invoicePublicId, {
    required DateTime paymentDate,
    required double amount,
    String? paymentMethod,
    String? referenceNumber,
    String? notes,
  }) async {
    AppLogger.api(
        'recordPayment: invoicePublicId=$invoicePublicId amount=$amount');
    try {
      final response = await _apiClient.post(
        '/Invoices/$invoicePublicId/record-payment',
        data: {
          'paymentDate': paymentDate.toIso8601String(),
          'amount': amount,
          if (paymentMethod != null) 'paymentMethod': paymentMethod,
          if (referenceNumber != null && referenceNumber.isNotEmpty)
            'referenceNumber': referenceNumber,
          if (notes != null && notes.isNotEmpty) 'notes': notes,
        },
      );
      final payment =
          InvoicePayment.fromJson(response.data as Map<String, dynamic>);
      AppLogger.api(
          'recordPayment: recorded paymentId=${payment.invoicePaymentId}');
      return Right(payment);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('recordPayment: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, List<InvoicePayment>>> fetchPayments(
      String invoicePublicId) async {
    AppLogger.api('fetchPayments: invoicePublicId=$invoicePublicId');
    try {
      final response =
          await _apiClient.get('/Invoices/$invoicePublicId/payments');
      final data = response.data as List<dynamic>;
      final payments = data
          .map((e) => InvoicePayment.fromJson(e as Map<String, dynamic>))
          .toList();
      AppLogger.api('fetchPayments: loaded ${payments.length} payments');
      return Right(payments);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('fetchPayments: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> uploadPhoto(
      String invoicePublicId, String filePath) async {
    AppLogger.api('uploadPhoto: invoicePublicId=$invoicePublicId');
    try {
      final formData =
          FormData.fromMap({'file': await MultipartFile.fromFile(filePath)});
      await _apiClient.post('/invoices/$invoicePublicId/photos',
          data: formData);
      AppLogger.api('uploadPhoto: success invoicePublicId=$invoicePublicId');
      return const Right(null);
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
  Future<Either<Failure, void>> uploadFile(
      String invoicePublicId, String filePath) async {
    AppLogger.api('uploadFile: invoicePublicId=$invoicePublicId');
    try {
      final formData =
          FormData.fromMap({'file': await MultipartFile.fromFile(filePath)});
      await _apiClient.post('/invoices/$invoicePublicId/files', data: formData);
      AppLogger.api('uploadFile: success invoicePublicId=$invoicePublicId');
      return const Right(null);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('uploadFile: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }
}
