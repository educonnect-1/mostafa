import 'dart:io';

import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../core/config/supabase_config.dart';
import '../core/errors/exception_mapper.dart';
import '../core/utils/file_validators.dart';

const _uuid = Uuid();

/// Handles every Supabase Storage upload in the app. Storage bucket
/// paths here MUST match the conventions the RLS policies in
/// `schema.sql` §20 expect, or the upload will be rejected server-side:
///   - avatars/{user_id}/{filename}
///   - chat-attachments/{group_id}/{filename}
///   - assignment-submissions/{assignment_id}/{student_id}/{filename}
///   - resources/{group_id}/{filename}   (teacher-only writes)
class StorageService {
  StorageService(this._client);

  final SupabaseClient _client;

  Future<String> uploadAvatar(File file) => _uploadValidated(
        bucket: 'avatars',
        pathSegments: [_requireUid(), _fileName(file)],
        file: file,
        compressIfImage: true,
      );

  Future<String> uploadChatAttachment({
    required String groupId,
    required File file,
  }) =>
      _uploadValidated(
        bucket: 'chat-attachments',
        pathSegments: [groupId, _fileName(file)],
        file: file,
        compressIfImage: true,
      );

  Future<String> uploadAssignmentSubmission({
    required String assignmentId,
    required File file,
  }) =>
      _uploadValidated(
        bucket: 'assignment-submissions',
        pathSegments: [assignmentId, _requireUid(), _fileName(file)],
        file: file,
        compressIfImage: true,
      );

  String _requireUid() {
    final uid = _client.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Cannot upload while signed out.');
    }
    return uid;
  }

  String _fileName(File file) {
    final ext = p.extension(file.path); // includes leading dot
    return '${_uuid.v4()}$ext';
  }

  Future<String> _uploadValidated({
    required String bucket,
    required List<String> pathSegments,
    required File file,
    required bool compressIfImage,
  }) {
    return runGuarded(() async {
      final extension = p.extension(file.path).replaceAll('.', '');
      final sizeBytes = await file.length();
      UploadRules.validate(extension: extension, sizeBytes: sizeBytes);

      File uploadFile = file;
      if (compressIfImage && UploadRules.isImage(extension)) {
        uploadFile = await _compressImage(file) ?? file;
      }

      final objectPath = pathSegments.join('/');
      await _client.storage.from(bucket).upload(
            objectPath,
            uploadFile,
            fileOptions: const FileOptions(upsert: false),
          );
      return objectPath;
    });
  }

  Future<File?> _compressImage(File file) async {
    try {
      final targetPath =
          '${file.parent.path}/compressed_${p.basename(file.path)}';
      final result = await FlutterImageCompress.compressAndGetFile(
        file.absolute.path,
        targetPath,
        quality: 80,
        minWidth: 1600,
        minHeight: 1600,
      );
      return result == null ? null : File(result.path);
    } catch (_) {
      // If compression fails for any reason, fall back to the original
      // file rather than blocking the upload entirely.
      return null;
    }
  }

  /// Signed URL for private buckets (chat-attachments, submissions,
  /// resources). Avatars are served from the public bucket directly.
  Future<String> getSignedUrl({
    required String bucket,
    required String path,
    Duration expiresIn = const Duration(hours: 1),
  }) {
    return runGuarded(() async {
      return _client.storage.from(bucket).createSignedUrl(
            path,
            expiresIn.inSeconds,
          );
    });
  }

  String getPublicUrl({required String bucket, required String path}) {
    return _client.storage.from(bucket).getPublicUrl(path);
  }
}

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService(SupabaseConfig.client);
});
