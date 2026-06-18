import 'package:dio/dio.dart';

import '../storage/secure_storage.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._secureStorage);

  final SecureStorage _secureStorage;

  @override
  void onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final jwt = await _secureStorage.readJwt();

    if (jwt != null && jwt.trim().isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $jwt';
    }

    handler.next(options);
  }
}
