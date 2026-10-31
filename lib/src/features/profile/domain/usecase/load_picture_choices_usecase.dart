import '../entity/picture_choice.dart';
import '../repository/friends_repository.dart';

class LoadPictureChoicesUseCase {
  final FriendsRepository repository;

  const LoadPictureChoicesUseCase(this.repository);

  Future<List<PictureChoice>> call() => repository.loadPictureChoices();
}
