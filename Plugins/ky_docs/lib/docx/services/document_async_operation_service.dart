import '../models/document_state.dart';

typedef DocumentStateReader = DocumentState Function();
typedef DocumentStateEmitter = void Function(DocumentState state);
typedef DocumentFailureStateBuilder =
    DocumentState Function(DocumentState failedState, Object error);

class DocumentAsyncOperationService {
  const DocumentAsyncOperationService();

  Future<T?> run<T>({
    required DocumentStateReader readState,
    required DocumentStateEmitter emitState,
    required Future<T> Function() operation,
    required String failureMessage,
    bool clearSyncingOnError = false,
    bool rethrowOnError = false,
    DocumentFailureStateBuilder? failureStateBuilder,
    T? fallback,
  }) async {
    emitState(readState().copyWith(isLoading: true, clearError: true));

    try {
      return await operation();
    } catch (error) {
      var failedState = readState().copyWith(
        isLoading: false,
        errorMessage: '$failureMessage: $error',
      );
      if (clearSyncingOnError) {
        failedState = failedState.copyWith(isSyncing: false);
      }
      final buildFailureState = failureStateBuilder;
      if (buildFailureState != null) {
        failedState = buildFailureState(failedState, error);
      }
      emitState(failedState);

      if (rethrowOnError) rethrow;
      return fallback;
    }
  }
}
