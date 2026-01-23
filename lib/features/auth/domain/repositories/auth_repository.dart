import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<UserEntity> signInWithGoogle();
  Future<UserEntity> signInWithEmail(String email, String password);
  Future<UserEntity> registerWithEmail(String email, String password);
  Future<void> signOut();
  Future<UserEntity?> getCurrentUser();
  Future<void> sendPasswordResetEmail(String email);
}
