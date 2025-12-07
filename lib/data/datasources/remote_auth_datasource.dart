import 'package:dio/dio.dart';
import '../../core/constants/api_constants.dart';
import '../../core/errors/failures.dart';
import '../../core/utils/result.dart';

class RemoteAuthDataSource {
  final Dio _dio;
  final String? Function() _getAccessToken;

  RemoteAuthDataSource(this._dio, this._getAccessToken);

  Future<Result<String>> getOAuthUrl() async {
    try {
      final token = _getAccessToken();
      if (token == null) {
        return const Error(AuthFailure('Not authenticated'));
      }

      final response = await _dio.get(
        ApiConstants.connectGmailPath,
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return Success(response.data['authUrl'] as String);
    } on DioException catch (e) {
      String errorMessage = 'Connection failed';
      if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Make sure the backend server is running on port 3000.';
      } else if (e.type == DioExceptionType.connectionError) {
        final baseUrl = ApiConstants.baseUrl;
        errorMessage = 'Cannot connect to server at $baseUrl.\n\n'
            'Please check:\n'
            '1. Backend server is running (npm start in lib/backend)\n'
            '2. API_BASE_URL in .env file is correct\n'
            '3. If using Cloudflare tunnel, ensure it\'s active\n'
            '4. For Android emulator: http://10.0.2.2:3000\n'
            '5. For physical device: Use your computer IP or Cloudflare URL';
      } else if (e.response != null) {
        errorMessage = e.response?.data?['error'] ?? e.message ?? 'Server error';
      } else {
        errorMessage = e.message ?? 'Unknown error';
      }
      return Error(ServerFailure(errorMessage));
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> connectGmail(String code) async {
    try {
      final token = _getAccessToken();
      if (token == null) {
        return const Error(AuthFailure('Not authenticated'));
      }

      await _dio.post(
        ApiConstants.oauthCallbackPath,
        data: {'code': code},
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return const Success(null);
    } on DioException catch (e) {
      return Error(ServerFailure(e.response?.data?['error'] ?? e.message ?? 'Unknown error'));
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  Future<Result<bool>> isGmailConnected() async {
    try {
      final token = _getAccessToken();
      if (token == null) {
        return const Success(false);
      }

      final response = await _dio.get(
        '${ApiConstants.connectGmailPath}/status',
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );

      return Success(response.data['connected'] as bool? ?? false);
    } catch (_) {
      return const Success(false);
    }
  }
}

