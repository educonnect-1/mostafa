import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/errors/app_exception.dart';
import '../../../repositories/assignment_repository.dart';

enum SubmissionFlowStep { idle, previewing, uploading, done }

class SubmissionFlowState {
  const SubmissionFlowState({
    this.step = SubmissionFlowStep.idle,
    this.photo,
    this.error,
  });

  final SubmissionFlowStep step;
  final File? photo;
  final AppException? error;

  SubmissionFlowState copyWith({
    SubmissionFlowStep? step,
    File? photo,
    AppException? error,
    bool clearError = false,
    bool clearPhoto = false,
  }) {
    return SubmissionFlowState(
      step: step ?? this.step,
      photo: clearPhoto ? null : (photo ?? this.photo),
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// Implements the exact flow from spec §15:
///   Open Assignment -> Take Photo -> Preview -> Retake/Confirm -> Upload -> Submit
class SubmissionFlowController extends StateNotifier<SubmissionFlowState> {
  SubmissionFlowController(this._repository, this._assignmentId)
      : super(const SubmissionFlowState());

  final AssignmentRepository _repository;
  final String _assignmentId;

  Future<void> capturePhoto({required bool fromCamera}) async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: fromCamera ? ImageSource.camera : ImageSource.gallery,
      imageQuality: 90,
    );
    if (picked == null) return;
    state = state.copyWith(
      step: SubmissionFlowStep.previewing,
      photo: File(picked.path),
      clearError: true,
    );
  }

  void retake() {
    state = state.copyWith(step: SubmissionFlowStep.idle, clearPhoto: true);
  }

  Future<bool> confirmAndSubmit() async {
    if (state.photo == null) return false;
    state = state.copyWith(step: SubmissionFlowStep.uploading, clearError: true);
    try {
      await _repository.submitPhoto(
        assignmentId: _assignmentId,
        photo: state.photo!,
      );
      state = state.copyWith(step: SubmissionFlowStep.done);
      return true;
    } on AppException catch (e) {
      state = state.copyWith(step: SubmissionFlowStep.previewing, error: e);
      return false;
    }
  }

  void reset() => state = const SubmissionFlowState();
}

final submissionFlowControllerProvider = StateNotifierProvider.autoDispose
    .family<SubmissionFlowController, SubmissionFlowState, String>(
  (ref, assignmentId) => SubmissionFlowController(
    ref.read(assignmentRepositoryProvider),
    assignmentId,
  ),
);
