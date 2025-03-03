part of 'registration_document_bloc.dart';

abstract class RegistrationDocumentState extends Equatable {
  const RegistrationDocumentState();

  @override
  List<Object> get props => [];
}

class RegistrationDocumentInitial extends RegistrationDocumentState {}

class RegistrationDocumentUploaded extends RegistrationDocumentState {
  final String fileName;
  final Uint8List fileBytes;

  const RegistrationDocumentUploaded({
    required this.fileName,
    required this.fileBytes,
  });

  @override
  List<Object> get props => [fileName, fileBytes];
}
