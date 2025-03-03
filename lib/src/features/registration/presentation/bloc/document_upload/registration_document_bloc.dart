import 'dart:typed_data';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'registration_document_event.dart';
part 'registration_document_state.dart';

class RegistrationDocumentBloc
    extends Bloc<RegistrationDocumentEvent, RegistrationDocumentState> {
  RegistrationDocumentBloc() : super(RegistrationDocumentInitial()) {
    on<UploadRegistrationDocument>(_onUploadRegistrationDocument);
  }

  Future<void> _onUploadRegistrationDocument(
    UploadRegistrationDocument event,
    Emitter<RegistrationDocumentState> emit,
  ) async {
    // You could add any additional processing logic here if needed

    // Emit the new state with the uploaded document details.
    emit(RegistrationDocumentUploaded(
      fileName: event.fileName,
      fileBytes: event.fileBytes,
    ));
  }
}
