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
      return Error(ServerFailure(e.response?.data?['error'] ?? e.message ?? 'Unknown error'));
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

