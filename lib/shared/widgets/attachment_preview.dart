import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../models/doc_attachment.dart';
import 'document_form.dart' show formatFileSize, iconForFileExtension;

/// Full-screen zoomable photo view. Tap anywhere or the X to dismiss.
Future<void> showPhotoViewer(BuildContext context, String url,
    {String? caption}) {
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black87,
    builder: (dialogContext) => GestureDetector(
      onTap: () => Navigator.pop(dialogContext),
      child: Stack(
        children: [
          Positioned.fill(
            child: InteractiveViewer(
              minScale: 0.8,
              maxScale: 4,
              child: Center(
                child: Image.network(url,
                    errorBuilder: (_, __, ___) => const Icon(
                        Icons.broken_image_outlined,
                        color: Colors.white54,
                        size: 48)),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 8,
            right: 8,
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () => Navigator.pop(dialogContext),
            ),
          ),
          if ((caption ?? '').trim().isNotEmpty)
            Positioned(
              left: 16,
              right: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
              child: Text(
                caption!.trim(),
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
        ],
      ),
    ),
  );
}

/// Opens an uploaded file in the system viewer / browser.
Future<void> openAttachment(BuildContext context, DocAttachment file) async {
  final url = file.url;
  final ok = url != null &&
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Could not open this file.')),
    );
  }
}

/// Tappable thumbnail of an already-uploaded photo; opens [showPhotoViewer].
class UploadedPhotoThumb extends StatelessWidget {
  final DocPhotoRef photo;
  final double size;
  const UploadedPhotoThumb({super.key, required this.photo, this.size = 76});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => showPhotoViewer(context, photo.url, caption: photo.caption),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.network(
          photo.url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Container(
            width: size,
            height: size,
            color: AppColors.grayTint,
            child: const Icon(Icons.broken_image_outlined,
                size: 18, color: AppColors.inkFaint),
          ),
        ),
      ),
    );
  }
}

/// One row for an uploaded file: icon, name, size; tap to open/preview.
class UploadedFileRow extends StatelessWidget {
  final DocAttachment file;
  const UploadedFileRow({super.key, required this.file});

  @override
  Widget build(BuildContext context) {
    final isImage = (file.contentType ?? '').startsWith('image/');
    return InkWell(
      onTap: () {
        final url = file.url;
        if (isImage && url != null) {
          showPhotoViewer(context, url, caption: file.displayName);
        } else {
          openAttachment(context, file);
        }
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Icon(iconForFileExtension(file.extension),
                size: 20, color: AppColors.inkSoft),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(file.displayName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.rowTitle.copyWith(fontSize: 14)),
                  if (file.fileSize != null)
                    Text(formatFileSize(file.fileSize!),
                        style: AppTextStyles.caption),
                ],
              ),
            ),
            const Icon(Icons.open_in_new, size: 16, color: AppColors.inkFaint),
          ],
        ),
      ),
    );
  }
}

/// Card for detail pages listing uploaded photos and files with previews.
/// Renders nothing when both lists are empty.
class DocAttachmentsCard extends StatelessWidget {
  final List<DocPhotoRef> photos;
  final List<DocAttachment> files;
  const DocAttachmentsCard(
      {super.key, this.photos = const [], this.files = const []});

  @override
  Widget build(BuildContext context) {
    if (photos.isEmpty && files.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Photos and attachments',
              style: AppTextStyles.rowTitle.copyWith(fontSize: 15)),
          if (photos.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [for (final p in photos) UploadedPhotoThumb(photo: p)],
            ),
          ],
          if (files.isNotEmpty) ...[
            const SizedBox(height: 4),
            for (var i = 0; i < files.length; i++) ...[
              if (i > 0 || photos.isNotEmpty)
                const Divider(height: 1, color: AppColors.line),
              UploadedFileRow(file: files[i]),
            ],
          ],
        ],
      ),
    );
  }
}
