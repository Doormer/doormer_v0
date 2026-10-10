import 'package:doormer/src/dev/fake_backend/fake_backend_state.dart';
import 'package:doormer/src/dev/fake_backend/fake_request.dart';
import 'package:doormer/src/dev/fake_backend/fake_response.dart';
import 'package:doormer/src/dev/fake_backend/fake_route.dart';

/// Where the fake hands out upload addresses. The `.invalid` domain never
/// resolves, so nothing leaves the browser.
const fakeStorageHost = 'fake-storage.invalid';

/// Uploading a CV and preferences, and registering as a candidate.
///
/// These are the paths the app calls today. `taka-api` serves them under
/// `/v1`, so against the real API these requests fail.
class RegistrationRoutes {
  final FakeBackendState _state;

  RegistrationRoutes(this._state);

  List<FakeRoute> get routes => [
        FakeRoute('POST', '/candidate/cv-upload', _uploadAddress),
        // Uploads go straight to storage, without the API's token.
        FakeRoute('PUT', fakeStorageHost, _storeUpload, needsToken: false),
        FakeRoute('POST', '/candidate/register', _register),
      ];

  FakeResponse _uploadAddress(FakeRequest request) {
    final fileName =
        request.queryParameters['file_name']?.toString() ?? 'upload';
    return FakeResponse.ok({
      'signed_upload_destination_url':
          'https://$fakeStorageHost/uploads/${Uri.encodeComponent(fileName)}',
    });
  }

  FakeResponse _storeUpload(FakeRequest request) => const FakeResponse(201);

  FakeResponse _register(FakeRequest request) {
    _state.registrationStatus = 1;
    return const FakeResponse.ok({});
  }
}
