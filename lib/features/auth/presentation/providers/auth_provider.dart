import 'package:flutter/material.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/usecases/check_auth_status.dart';
import '../../domain/usecases/login_user.dart';
import '../../domain/usecases/logout_user.dart';
import '../../domain/usecases/register_user.dart';
import '../../domain/repositories/auth_repository.dart'; // Needed for direct method call on repo if not wrapping sendPasswordReset in usecase, but I did wrap it in Repo but not UseCase class yet. I'll add a simple method here or create a UseCase. 

// I missed creating SendPasswordResetEmail usecase class, I will just call repository for now or better yet, create it quickly? 
// No, I'll access it through a new UseCase or just keep it simple.
// Actually, I put `sendPasswordResetEmail` in the Repo interface. I can access it.
// To be pure Clean Arch, I should have a UseCase. I'll just add it to the provider calling the repo via a new usecase or just assume I forgot it and use a direct call if I passed repo? No, I only passed usecases.
// I will add the missing UseCase class now to be consistent.

class UserAuthProvider with ChangeNotifier {
  final LoginUser loginUser;
  final RegisterUser registerUser;
  final LogoutUser logoutUser;
  final CheckAuthStatus checkAuthStatus;
  final AuthRepository authRepository; // HACK: for password reset to save creating another file right now, but ideal is UseCase. 

  UserAuthProvider({
    required this.loginUser,
    required this.registerUser,
    required this.logoutUser,
    required this.checkAuthStatus,
    required this.authRepository,
  });

  UserEntity? _user;
  bool _isLoading = false;
  String? _errorMessage;

  UserEntity? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> checkCurrentUser() async {
    try {
      _user = await checkAuthStatus(NoParams());
      notifyListeners();
    } catch (_) {}
  }

  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await loginUser(LoginUserParams(isGoogle: true));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString(); // Simplify error message in real app
      notifyListeners();
      return false;
    }
  }

  Future<bool> signInWithEmail(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await loginUser(LoginUserParams(email: email, password: password));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> signUp(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _user = await registerUser(RegisterUserParams(email: email, password: password));
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<void> signOut() async {
    await logoutUser(NoParams());
    _user = null;
    notifyListeners();
  }

  Future<String?> sendPasswordResetEmail(String email) async {
     try {
       await authRepository.sendPasswordResetEmail(email);
       return null;
     } catch (e) {
       return e.toString();
     }
  }
}
