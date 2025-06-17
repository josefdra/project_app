part of 'edit_project_bloc.dart';

enum EditProjectStatus { initial, loading, ready, success, invalid, failure }

extension EditProjectStatusX on EditProjectStatus {
  bool get isLoadingOrSuccess => [
        EditProjectStatus.loading,
        EditProjectStatus.success,
      ].contains(this);
}

final class EditProjectState extends Equatable {
  const EditProjectState({
    this.status = EditProjectStatus.initial,
    this.text = '',
    this.validationErrors = const {},
  });

  final EditProjectStatus status;
  final String text;
  final Map<String, String?> validationErrors;

  EditProjectState copyWith({
    EditProjectStatus? status,
    String? text,
    Map<String, String?>? validationErrors,
  }) {
    return EditProjectState(
      status: status ?? this.status,
      text: text ?? this.text,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }

  @override
  List<Object?> get props => [status, text, validationErrors];
}
