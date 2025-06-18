part of 'edit_name_bloc.dart';

enum EditNameStatus { initial, loading, ready, success, invalid, failure }

extension EditNameStatusX on EditNameStatus {
  bool get isLoadingOrSuccess => [
        EditNameStatus.loading,
        EditNameStatus.success,
      ].contains(this);
}

final class EditNameState extends Equatable {
  const EditNameState({
    this.status = EditNameStatus.initial,
    this.text = '',
    this.validationErrors = const {},
  });

  final EditNameStatus status;
  final String text;
  final Map<String, String?> validationErrors;

  EditNameState copyWith({
    EditNameStatus? status,
    String? text,
    Map<String, String?>? validationErrors,
  }) {
    return EditNameState(
      status: status ?? this.status,
      text: text ?? this.text,
      validationErrors: validationErrors ?? this.validationErrors,
    );
  }

  @override
  List<Object?> get props => [status, text, validationErrors];
}
