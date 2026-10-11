import 'package:equatable/equatable.dart';

import '../../core/constants/app_constants.dart';

/// A file attached to an estimate or invoice (`EstimateAttachmentViewModel` /
/// `InvoiceAttachmentViewModel` — identical shape).
class DocAttachment extends Equatable {
  final int attachmentId;
  final String? fileName;
  final String? fileUrl;
  final int? fileSize;
  final String? contentType;
  final int sortOrder;

  const DocAttachment({
    this.attachmentId = 0,
    this.fileName,
    this.fileUrl,
    this.fileSize,
    this.contentType,
    this.sortOrder = 0,
  });

  /// Absolute URL — the API's `fileUrl` when absolute, else built from the
  /// bare filename against the uploads origin.
  String? get url {
    final u = fileUrl?.trim();
    if (u != null && u.isNotEmpty) {
      return u.startsWith('http') ? u : AppConstants.projectPhotoUrl(u);
    }
    final f = fileName?.trim();
    if (f != null && f.isNotEmpty) return AppConstants.projectPhotoUrl(f);
    return null;
  }

  String get displayName => (fileName ?? '').trim().isNotEmpty
      ? fileName!.trim()
      : 'Attachment';

  String? get extension {
    final name = displayName;
    final i = name.lastIndexOf('.');
    return i == -1 ? null : name.substring(i + 1);
  }

  factory DocAttachment.fromJson(Map<String, dynamic> json) => DocAttachment(
        attachmentId: json['attachmentId'] as int? ?? 0,
        fileName: json['fileName'] as String?,
        fileUrl: json['fileUrl'] as String?,
        fileSize: (json['fileSize'] as num?)?.toInt(),
        contentType: json['contentType'] as String?,
        sortOrder: json['sortOrder'] as int? ?? 0,
      );

  static List<DocAttachment> listFromJson(dynamic raw) =>
      (raw as List<dynamic>?)
          ?.map((e) => DocAttachment.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [];

  @override
  List<Object?> get props =>
      [attachmentId, fileName, fileUrl, fileSize, contentType, sortOrder];
}

/// A photo already uploaded to a document, reduced to what previews need.
class DocPhotoRef extends Equatable {
  final String url;
  final String? caption;
  const DocPhotoRef(this.url, {this.caption});

  @override
  List<Object?> get props => [url, caption];
}
