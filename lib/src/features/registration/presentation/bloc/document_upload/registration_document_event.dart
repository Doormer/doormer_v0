part of 'registration_document_bloc.dart';

abstract class RegistrationDocumentEvent extends Equatable {
  const RegistrationDocumentEvent();

  @override
  List<Object> get props => [];
}

class UploadRegistrationDocument extends RegistrationDocumentEvent {
  final String fileName;
  final Uint8List fileBytes;

  const UploadRegistrationDocument({
    required this.fileName,
    required this.fileBytes,
  });

  @override
  List<Object> get props => [fileName, fileBytes];
}
