import 'package:equatable/equatable.dart';

/// Which signature on a document — the `{kind}` path segment of
/// `/estimates|invoices/{publicId}/signatures/{kind}`.
///
/// The API accepts only `customer` or `company` (confirmed from its 400
/// response; swagger just says "string").
enum SignatureKind {
  client('customer'),
  company('company');

  final String apiValue;
  const SignatureKind(this.apiValue);
}

/// SignatureViewModel from the signature endpoints.
class DocSignature extends Equatable {
  final String? fileUrl;
  final DateTime? signedDate;

  const DocSignature({this.fileUrl, this.signedDate});

  factory DocSignature.fromJson(Map<String, dynamic> json) => DocSignature(
        fileUrl: json['fileUrl'] as String?,
        signedDate: DateTime.tryParse(json['signedDate'] as String? ?? ''),
      );

  @override
  List<Object?> get props => [fileUrl, signedDate];
}
