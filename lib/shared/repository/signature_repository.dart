import 'package:dartz/dartz.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;

import '../../core/errors/exceptions.dart';
import '../../core/errors/failures.dart';
import '../../core/network/api_client.dart';
import '../../core/utils/app_logger.dart';
import '../models/doc_signature.dart';

/// The API accepts only JPEG (max 10MB), which has no transparency — flatten
/// the PNG onto white and re-encode. Top-level so it can run via [compute].
Uint8List _pngToJpeg(Uint8List png) {
  final src = img.decodePng(png);
  if (src == null) throw const FormatException('Invalid signature image');
  final flat = img.Image(width: src.width, height: src.height, numChannels: 3)
    ..clear(img.ColorRgb8(255, 255, 255));
  img.compositeImage(flat, src);
  return img.encodeJpg(flat, quality: 90);
}

enum SignedDocumentType {
  estimate('estimates'),
  invoice('invoices');

  final String segment;
  const SignedDocumentType(this.segment);
}

/// Estimate/Invoice signature endpoints
/// (`/{estimates|invoices}/{publicId}/signatures/{kind}`).
abstract class SignatureRepository {
  /// Uploads [png] as the signature. POST creates, PUT replaces, so the
  /// existing state ([replace]) decides which verb is used.
  Future<Either<Failure, DocSignature>> saveSignature(
    SignedDocumentType type,
    String publicId,
    SignatureKind kind,
    Uint8List png, {
    required bool replace,
  });

  Future<Either<Failure, void>> deleteSignature(
      SignedDocumentType type, String publicId, SignatureKind kind);
}

class SignatureRepositoryImpl implements SignatureRepository {
  final ApiClient _apiClient;
  SignatureRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  String _path(SignedDocumentType t, String id, SignatureKind k) =>
      '/${t.segment}/$id/signatures/${k.apiValue}';

  @override
  Future<Either<Failure, DocSignature>> saveSignature(
    SignedDocumentType type,
    String publicId,
    SignatureKind kind,
    Uint8List png, {
    required bool replace,
  }) async {
    AppLogger.api('saveSignature: ${type.segment}/$publicId ${kind.apiValue}');
    try {
      final jpg = await compute(_pngToJpeg, png);
      final form = FormData.fromMap({
        'file': MultipartFile.fromBytes(jpg,
            filename: '${kind.apiValue}-signature.jpg',
            contentType: DioMediaType('image', 'jpeg')),
      });
      final path = _path(type, publicId, kind);
      final response = replace
          ? await _apiClient.put(path, data: form)
          : await _apiClient.post(path, data: form);
      final data = response.data;
      return Right(data is Map<String, dynamic>
          ? DocSignature.fromJson(data)
          : DocSignature(signedDate: DateTime.now()));
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('saveSignature: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }

  @override
  Future<Either<Failure, void>> deleteSignature(
      SignedDocumentType type, String publicId, SignatureKind kind) async {
    try {
      await _apiClient.delete(_path(type, publicId, kind));
      return const Right(null);
    } on UnauthorizedException catch (e) {
      return Left(UnauthorizedFailure(e.message));
    } on ServerException catch (e) {
      return Left(ServerFailure(e.message, statusCode: e.statusCode));
    } on NetworkException catch (e) {
      return Left(NetworkFailure(e.message));
    } catch (e) {
      AppLogger.error('deleteSignature: unexpected — $e');
      return const Left(UnexpectedFailure());
    }
  }
}
