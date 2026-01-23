import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'features/wallpaper/data/datasources/wallpaper_remote_data_source.dart';
import 'features/wallpaper/data/repositories/wallpaper_repository_impl.dart';
import 'features/wallpaper/domain/repositories/wallpaper_repository.dart';
import 'features/wallpaper/domain/usecases/get_wallpapers.dart';
import 'features/wallpaper/presentation/providers/wallpaper_provider.dart';

import 'features/auth/data/datasources/auth_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/repositories/auth_repository.dart';
import 'features/auth/domain/usecases/login_user.dart';
import 'features/auth/domain/usecases/register_user.dart';
import 'features/auth/domain/usecases/logout_user.dart';
import 'features/auth/domain/usecases/check_auth_status.dart';
import 'features/auth/presentation/providers/auth_provider.dart';

final sl = GetIt.instance;

Future<void> init() async {
  //! Features - Wallpaper
  // Provider
  sl.registerFactory(
    () => WallpaperProvider(getWallpapersUseCase: sl()),
  );

  // Use cases
  sl.registerLazySingleton(() => GetWallpapers(sl()));

  // Repository
  sl.registerLazySingleton<WallpaperRepository>(
    () => WallpaperRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<WallpaperRemoteDataSource>(
    () => WallpaperRemoteDataSourceImpl(client: sl()),
  );

  //! Features - Auth
  // Provider
  sl.registerFactory(
    () => UserAuthProvider(
      loginUser: sl(),
      registerUser: sl(),
      logoutUser: sl(),
      checkAuthStatus: sl(),
      authRepository: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoginUser(sl()));
  sl.registerLazySingleton(() => RegisterUser(sl()));
  sl.registerLazySingleton(() => LogoutUser(sl()));
  sl.registerLazySingleton(() => CheckAuthStatus(sl()));

  // Repository
  sl.registerLazySingleton<AuthRepository>(
    () => AuthRepositoryImpl(remoteDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<AuthRemoteDataSource>(
    () => AuthRemoteDataSourceImpl(
      firebaseAuth: sl(),
      googleSignIn: sl(),
    ),
  );

  //! External
  sl.registerLazySingleton(() => http.Client());
  sl.registerLazySingleton(() => FirebaseAuth.instance);
  sl.registerLazySingleton(() => GoogleSignIn());
}
