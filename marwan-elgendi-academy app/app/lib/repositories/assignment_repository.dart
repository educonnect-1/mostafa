import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../core/config/supabase_config.dart';
import '../core/errors/app_exception.dart';
import '../core/errors/exception_mapper.dart';
import '../models/assignment.dart';
import '../services/storage_service.dart';

/// The embedded `assignment_submissions(*)` select below relies on RLS
/// (`submissions_select_own_or_teacher` in schema.sql) to automatically
/// scope the joined rows to just the signed-in student's own
/// submission — no extra `.eq('student_id', ...)` filter is needed or
/// even possible to bypass client-side.
class AssignmentRepository {
  AssignmentRepository(this._client, this._storageService);

  final SupabaseClient _client;
  final StorageService _storageService;

  Future<List<Assignment>> getMyAssignments() {
    return runGuarded(() async {
      final rows = await _client
          .from('assignments')
          .select('*, assignment_submissions(*)')
          .order('deadline');
      return (rows as List)
          .map((r) => Assignment.fromJson(r as Map<String, dynamic>))
          .toList();
    });
  }

  Future<Assignment> getAssignmentById(String id) {
    return runGuarded(() async {
      final row = await _client
          .from('assignments')
          .select('*, assignment_submissions(*)')
          .eq('id', id)
          .single();
      return Assignment.fromJson(row);
    });
  }

  /// Uploads the homework photo, then upserts the submission row. The
  /// database trigger `enforce_submission_rules` (schema.sql) rejects
  /// this at the SQL level if the deadline has passed or the
  /// assignment was manually closed — this app never trusts its own
  /// deadline check as the source of truth, only the DB's.
  Future<void> submitPhoto({
    required String assignmentId,
    required File photo,
  }) {
    return runGuarded(() async {
      final uid = _client.auth.currentUser?.id;
      if (uid == null) throw const SessionExpiredException();

      final path = await _storageService.uploadAssignmentSubmission(
        assignmentId: assignmentId,
        file: photo,
      );

      await _client.from('assignment_submissions').upsert(
        {
          'assignment_id': assignmentId,
          'student_id': uid,
          'photo_storage_path': path,
        },
        onConflict: 'assignment_id,student_id',
      );
    });
  }

  Future<String> getSubmissionPhotoUrl(String storagePath) {
    return _storageService.getSignedUrl(
      bucket: 'assignment-submissions',
      path: storagePath,
    );
  }
}

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  return AssignmentRepository(
    SupabaseConfig.client,
    ref.read(storageServiceProvider),
  );
});
