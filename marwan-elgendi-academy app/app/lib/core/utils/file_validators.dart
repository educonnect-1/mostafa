import '../errors/app_exception.dart';

/// Centralized upload constraints so every feature (chat attachments,
/// assignment submissions, resources, avatars) validates the same way
/// instead of re-implementing checks per screen.
class UploadRules {
  UploadRules._();

  static const Set<String> imageExtensions = {'jpg', 'jpeg', 'png', 'webp', 'heic'};
  static const Set<String> documentExtensions = {'pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt'};

  static const int maxImageBytes = 10 * 1024 * 1024; // 10 MB
  static const int maxDocumentBytes = 25 * 1024 * 1024; // 25 MB

  static bool isImage(String extension) =>
      imageExtensions.contains(extension.toLowerCase().replaceAll('.', ''));

  static bool isDocument(String extension) =>
      documentExtensions.contains(extension.toLowerCase().replaceAll('.', ''));

  /// Throws a [ValidationAppException] with a user-friendly message if
  /// the file doesn't pass. Call this before ever starting an upload.
  static void validate({
    required String extension,
    required int sizeBytes,
  }) {
    final ext = extension.toLowerCase().replaceAll('.', '');
    final isImg = isImage(ext);
    final isDoc = isDocument(ext);

    if (!isImg && !isDoc) {
      throw ValidationAppException(
        'That file type (.$ext) isn\'t supported. '
        'Allowed: images, PDF, and common document formats.',
      );
    }

    final maxBytes = isImg ? maxImageBytes : maxDocumentBytes;
    if (sizeBytes > maxBytes) {
      final maxMb = (maxBytes / (1024 * 1024)).toStringAsFixed(0);
      throw ValidationAppException('That file is too large. Max size is $maxMb MB.');
    }
  }
}
