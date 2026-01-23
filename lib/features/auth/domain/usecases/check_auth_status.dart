import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class CheckAuthStatus implements UseCase<UserEntity?, NoParams> {
  final AuthRepository repository;

  CheckAuthStatus(this.repository);

  @override
  Future<UserEntity?> call(NoParams params) async {
    return await repository.getCurrentUser();
  }
}
