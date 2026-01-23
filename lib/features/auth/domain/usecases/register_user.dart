import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUser implements UseCase<UserEntity, RegisterUserParams> {
  final AuthRepository repository;

  RegisterUser(this.repository);

  @override
  Future<UserEntity> call(RegisterUserParams params) async {
    return await repository.registerWithEmail(params.email, params.password);
  }
}

class RegisterUserParams {
  final String email;
  final String password;

  RegisterUserParams({required this.email, required this.password});
}
