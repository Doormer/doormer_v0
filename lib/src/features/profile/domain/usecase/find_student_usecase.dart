import '../entity/found_student.dart';
import '../repository/friends_repository.dart';

class FindStudentUseCase {
  final FriendsRepository repository;

  const FindStudentUseCase(this.repository);

  /// [friendCode] is 8 characters with no dash.
  Future<FoundStudent> call(String friendCode) =>
      repository.findStudent(friendCode);
}
