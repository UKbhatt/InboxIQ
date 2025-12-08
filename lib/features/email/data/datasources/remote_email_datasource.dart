import 'package:dio/dio.dart';
import '../../../../core/constants/api_constants.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/utils/result.dart';
import '../models/email_model.dart';
import '../models/email_detail_model.dart';
import '../../domain/entities/email.dart';
import '../../domain/entities/email_detail.dart';

class RemoteEmailDataSource {
  final Dio _dio;
  final String? Function() _getAccessToken;

  RemoteEmailDataSource(this._dio, this._getAccessToken);

  Future<Result<List<Email>>> getEmails({
    int? limit,
    String? pageToken,
    int? offset,
    String? type,
  }) async {
    try {
      final token = _getAccessToken();
      if (token == null) {
        return const Error(AuthFailure('Not authenticated'));
      }

      final queryParams = <String, dynamic>{};
      if (limit != null) queryParams['limit'] = limit;
      if (offset != null) queryParams['offset'] = offset;
      if (pageToken != null) queryParams['pageToken'] = pageToken;
      if (type != null) queryParams['type'] = type;

      final response = await _dio.get(
        ApiConstants.emailsPath,
        queryParameters: queryParams,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final emails = (response.data['emails'] as List<dynamic>)
          .map((json) => EmailModel.fromGmailApi(json as Map<String, dynamic>))
          .toList();

      return Success(emails);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return const Error(NetworkFailure('Connection timeout'));
      }
      return Error(
        ServerFailure(
          e.response?.data?['error'] ?? e.message ?? 'Unknown error',
        ),
      );
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  Future<Result<Map<String, dynamic>>> getSyncStatus() async {
    try {
      final token = _getAccessToken();
      if (token == null) {
        return const Error(AuthFailure('Not authenticated'));
      }

      final response = await _dio.get(
        ApiConstants.emailSyncStatusPath,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return Success(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return const Error(NetworkFailure('Connection timeout'));
      }
      return Error(
        ServerFailure(
          e.response?.data?['error'] ?? e.message ?? 'Unknown error',
        ),
      );
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  Future<Result<void>> startSync() async {
    try {
      final token = _getAccessToken();
      if (token == null) {
        return const Error(AuthFailure('Not authenticated'));
      }

      await _dio.post(
        ApiConstants.emailSyncPath,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      return const Success(null);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return const Error(NetworkFailure('Connection timeout'));
      }
      return Error(
        ServerFailure(
          e.response?.data?['error'] ?? e.message ?? 'Unknown error',
        ),
      );
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  Future<Result<Email>> getEmailById(String emailId) async {
    try {
      final token = _getAccessToken();
      if (token == null) {
        return const Error(AuthFailure('Not authenticated'));
      }

      final response = await _dio.get(
        '${ApiConstants.emailsPath}/$emailId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final email = EmailModel.fromGmailApi(
        response.data as Map<String, dynamic>,
      );
      return Success(email);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return const Error(NetworkFailure('Connection timeout'));
      }
      return Error(
        ServerFailure(
          e.response?.data?['error'] ?? e.message ?? 'Unknown error',
        ),
      );
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  Future<Result<EmailDetail>> getEmailDetailById(String emailId) async {
    try {
      final token = _getAccessToken();
      if (token == null) {
        return const Error(AuthFailure('Not authenticated'));
      }

      final response = await _dio.get(
        '${ApiConstants.emailsPath}/$emailId',
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );

      final emailDetail = EmailDetailModel.fromJson(
        response.data as Map<String, dynamic>,
      );
      return Success(emailDetail);
    } on DioException catch (e) {
      if (e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout) {
        return const Error(NetworkFailure('Connection timeout'));
      }
      return Error(
        ServerFailure(
          e.response?.data?['error'] ?? e.message ?? 'Unknown error',
        ),
      );
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }
}
