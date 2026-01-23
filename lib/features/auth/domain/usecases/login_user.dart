import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUser implements UseCase<UserEntity, LoginUserParams> {
  final AuthRepository repository;

  LoginUser(this.repository);

  @override
  Future<UserEntity> call(LoginUserParams params) async {
    if (params.isGoogle) {
      return await repository.signInWithGoogle();
    } else {
      return await repository.signInWithEmail(params.email!, params.password!);
    }
  }
}

class LoginUserParams {
  final bool isGoogle;
  final String? email;
  final String? password;

  LoginUserParams({this.isGoogle = false, this.email, this.password});
}
