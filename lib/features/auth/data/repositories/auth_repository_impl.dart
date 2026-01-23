import '../../../../core/error/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource remoteDataSource;

  AuthRepositoryImpl({required this.remoteDataSource});

  @override
  Future<UserEntity> signInWithGoogle() async {
    return await remoteDataSource.signInWithGoogle();
  }

  @override
  Future<UserEntity> signInWithEmail(String email, String password) async {
    return await remoteDataSource.signInWithEmail(email, password);
  }

  @override
  Future<UserEntity> registerWithEmail(String email, String password) async {
    return await remoteDataSource.registerWithEmail(email, password);
  }

  @override
  Future<void> signOut() async {
    return await remoteDataSource.signOut();
  }

  @override
  Future<UserEntity?> getCurrentUser() async {
    return await remoteDataSource.getCurrentUser();
  }

  @override
  Future<void> sendPasswordResetEmail(String email) async {
    return await remoteDataSource.sendPasswordResetEmail(email);
  }
}
