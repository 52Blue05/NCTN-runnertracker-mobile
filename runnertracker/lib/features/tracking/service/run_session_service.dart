import 'package:dio/dio.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../model/run_session_model.dart';

class RunSessionService {
  RunSessionService({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  final ApiClient _apiClient;

  /// POST /api/v1/runs — Lưu buổi chạy lên server
  /// Trả về RunSessionModel nếu thành công, throw exception nếu lỗi
  Future<RunSessionModel> createRunSession(RunSessionModel session) async {
    try {
      final response = await _apiClient.post(
        ApiConstants.runs,
        data: session.toJson(),
      );

      final data = response.data;
      // Backend trả về ApiResponse<RunSessionResponse>
      if (data is Map<String, dynamic> && data['data'] != null) {
        return RunSessionModel.fromJson(data['data'] as Map<String, dynamic>);
      }
      // Nếu response trực tiếp là RunSessionResponse
      if (data is Map<String, dynamic>) {
        return RunSessionModel.fromJson(data);
      }
      throw Exception('Unexpected response format');
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.connectionError ||
          e.type == DioExceptionType.receiveTimeout) {
        throw NetworkException('Không thể kết nối đến server. Dữ liệu sẽ được lưu tạm.');
      }
      rethrow;
    }
  }

  /// GET /api/v1/runs — Lấy danh sách buổi chạy
  Future<List<RunSessionModel>> getRunSessions({int page = 0, int size = 10}) async {
    final response = await _apiClient.get(
      ApiConstants.runs,
      queryParameters: {'page': page, 'size': size},
    );
    final data = response.data;
    if (data is Map<String, dynamic> && data['data'] != null) {
      final pageData = data['data'] as Map<String, dynamic>;
      final content = pageData['content'] as List<dynamic>? ?? [];
      return content
          .map((e) => RunSessionModel.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    return [];
  }
}

/// Custom exception cho lỗi mạng
class NetworkException implements Exception {
  final String message;
  NetworkException(this.message);
  @override
  String toString() => message;
}
