import '../error/failures.dart';

abstract class UseCase<Type, Params> {
  Future<Type> call(Params params);
}

class NoParams {}
