import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/storage/secure_storage.dart';
import '../model/user_model.dart';

class AuthRepository {
  AuthRepository({
    required ApiClient apiClient,
    required SecureStorage secureStorage,
  }) : _apiClient = apiClient,
       _secureStorage = secureStorage;

  final ApiClient _apiClient;
  final SecureStorage _secureStorage;

  Future<UserModel> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.login,
        data: {'username': username, 'password': password},
      );

      final data = response.data ?? <String, dynamic>{};
      final token = _extractToken(data);

      if (token == null || token.trim().isEmpty) {
        throw const ApiException(
          message: 'Login response did not include a token.',
        );
      }

      await _secureStorage.writeJwt(token);

      return UserModel.fromJson(
        _extractUserPayload(data, fallbackUsername: username),
      );
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        ApiConstants.register,
        data: {
          'username': name,
          'name': name,
          'email': email,
          'password': password,
        },
      );

      final data = response.data ?? <String, dynamic>{};
      await _saveTokenIfPresent(data);

      return UserModel.fromJson(
        _extractUserPayload(data, fallbackUsername: name),
      );
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<UserModel> profile() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        ApiConstants.profile,
      );

      return UserModel.fromJson(response.data ?? <String, dynamic>{});
    } on DioException catch (exception) {
      throw ApiException.fromDioException(exception);
    }
  }

  Future<void> logout() {
    return _secureStorage.deleteJwt();
  }

  Future<void> _saveTokenIfPresent(Map<String, dynamic> data) async {
    final token = _extractToken(data);

    if (token is String && token.trim().isNotEmpty) {
      await _secureStorage.writeJwt(token);
    }
  }

  String? _extractToken(Map<String, dynamic> data) {
    final nestedData = data['data'];
    final token =
        data['jwt'] ??
        data['token'] ??
        data['access_token'] ??
        data['accessToken'] ??
        (nestedData is Map ? nestedData['jwt'] : null) ??
        (nestedData is Map ? nestedData['token'] : null) ??
        (nestedData is Map ? nestedData['access_token'] : null) ??
        (nestedData is Map ? nestedData['accessToken'] : null);

    return token?.toString();
  }

  Map<String, dynamic> _extractUserPayload(
    Map<String, dynamic> data, {
    String? fallbackUsername,
  }) {
    final nestedData = data['data'];
    final user =
        data['user'] ?? (nestedData is Map ? nestedData['user'] : null);

    if (user is Map<String, dynamic>) {
      return user;
    }

    if (user is Map) {
      return Map<String, dynamic>.from(user);
    }

    final source = nestedData is Map<String, dynamic>
        ? nestedData
        : nestedData is Map
        ? Map<String, dynamic>.from(nestedData)
        : data;

    return {
      'id': source['id'] ?? '',
      'username': source['username'] ?? fallbackUsername ?? '',
      'name': source['name'] ?? fallbackUsername ?? '',
      'email': source['email'] ?? '',
    };
  }
}
