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
    String? updatedAfter,
  }) {
    final queryParams = <String, dynamic>{
      if (limit != null) 'limit': limit,
      if (offset != null) 'offset': offset,
      if (pageToken != null) 'pageToken': pageToken,
      if (type != null) 'type': type,
      if (updatedAfter != null) 'updated_after': updatedAfter,
    };

    return _authorized((options) async {
      final response = await _dio.get(
        ApiConstants.emailsPath,
        queryParameters: queryParams,
        options: options,
      );
      return (response.data['emails'] as List<dynamic>)
          .map((json) => EmailModel.fromGmailApi(json as Map<String, dynamic>))
          .toList();
    });
  }

  Future<Result<Map<String, dynamic>>> getSyncStatus() {
    return _authorized((options) async {
      final response = await _dio.get(
        ApiConstants.emailSyncStatusPath,
        options: options,
      );
      final data = response.data;
      if (data is Map<String, dynamic>) return data;
      return {
        'hasSynced': false,
        'inProgress': false,
        'lastSyncAt': null,
        'totalEmails': 0,
        'lastError': null,
      };
    });
  }

  Future<Result<void>> startSync() {
    return _authorized((options) async {
      await _dio.post(ApiConstants.emailSyncPath, options: options);
    });
  }

  Future<Result<Email>> getEmailById(String emailId) {
    return _authorized((options) async {
      final response = await _dio.get(
        '${ApiConstants.emailsPath}/$emailId',
        options: options,
      );
      return EmailModel.fromGmailApi(response.data as Map<String, dynamic>);
    });
  }

  Future<Result<EmailDetail>> getEmailDetailById(String emailId) {
    return _authorized((options) async {
      final response = await _dio.get(
        '${ApiConstants.emailsPath}/$emailId',
        options: options,
      );
      return EmailDetailModel.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<Result<String>> getEmailSummary(String emailId) {
    return _authorized((options) async {
      final response = await _dio.post(
        '${ApiConstants.emailsPath}/$emailId/summary',
        options: options,
      );
      return response.data['summary'] as String;
    });
  }

  Future<Result<void>> markAsRead(String emailId) {
    return _authorized((options) async {
      await _dio.put('${ApiConstants.emailsPath}/$emailId/read', options: options);
    });
  }

  Future<Result<T>> _authorized<T>(
    Future<T> Function(Options options) request,
  ) async {
    final token = _getAccessToken();
    if (token == null) {
      return Error(const AuthFailure('Not authenticated'));
    }
    try {
      final options = Options(headers: {'Authorization': 'Bearer $token'});
      return Success(await request(options));
    } on DioException catch (e) {
      return Error(_failureFrom(e));
    } catch (e) {
      return Error(ServerFailure(e.toString()));
    }
  }

  Failure _failureFrom(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return const NetworkFailure('Connection timeout');
      case DioExceptionType.connectionError:
        return const NetworkFailure(
          'Cannot reach the server. Check your connection and try again.',
        );
      default:
        final data = e.response?.data;
        final serverMessage = data is Map<String, dynamic>
            ? data['error'] as String?
            : null;
        return ServerFailure(serverMessage ?? e.message ?? 'Unknown error');
    }
  }
}
