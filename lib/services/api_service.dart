import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/usage_data.dart';

/// Claude API Service
/// Adapted from Usage4Claude by f-is-h
/// https://github.com/f-is-h/Usage4Claude
/// MIT License - Copyright (c) 2025 f-is-h

class ApiService {
  static const String _baseUrl = 'https://claude.ai/api';

  Map<String, String> _buildHeaders(String sessionKey) {
    return {
      'accept': '*/*',
      'accept-language': 'en-US,en;q=0.9',
      'content-type': 'application/json',
      'anthropic-client-platform': 'web_claude_ai',
      'anthropic-client-version': '1.0.0',
      'user-agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/131.0.0.0 Safari/537.36',
      'origin': 'https://claude.ai',
      'referer': 'https://claude.ai/settings/usage',
      'sec-fetch-dest': 'empty',
      'sec-fetch-mode': 'cors',
      'sec-fetch-site': 'same-origin',
      'cookie': 'sessionKey=$sessionKey',
    };
  }

  Future<ApiResult<UsageData>> fetchUsage({
    required String organizationId,
    required String sessionKey,
  }) async {
    final url = Uri.parse('$_baseUrl/organizations/$organizationId/usage');
    print('[API] Fetching usage from: $url');
    
    try {
      final response = await http.get(
        url,
        headers: _buildHeaders(sessionKey),
      ).timeout(const Duration(seconds: 30));

      print('[API] Response status: ${response.statusCode}');
      print('[API] Response body: ${response.body.substring(0, response.body.length.clamp(0, 500))}');

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        
        if (json.containsKey('error')) {
          final errorType = json['error']['type'] as String?;
          final errorMessage = json['error']['message'] as String? ?? 'Unknown error';
          print('[API] Error in response: $errorType - $errorMessage');
          
          if (errorType == 'permission_error') {
            return ApiResult.failure(ApiError.sessionExpired, 'Session expired. Please update your session key.');
          }
          return ApiResult.failure(ApiError.unknown, errorMessage);
        }
        
        final usageData = UsageData.fromJson(json);
        print('[API] Successfully parsed usage data');
        return ApiResult.success(usageData);
      } else if (response.statusCode == 401) {
        print('[API] 401 Unauthorized');
        return ApiResult.failure(ApiError.sessionExpired, 'Session expired (401). Please update your session key.');
      } else if (response.statusCode == 403) {
        print('[API] 403 Forbidden');
        return ApiResult.failure(ApiError.sessionExpired, 'Access denied (403). Please update your session key.');
      } else if (response.statusCode == 503) {
        print('[API] 503 Service unavailable');
        return ApiResult.failure(ApiError.cloudflareBlocked, 'Cloudflare blocked the request. Try again later.');
      } else {
        print('[API] Unexpected status code: ${response.statusCode}');
        return ApiResult.failure(ApiError.networkError, 'HTTP ${response.statusCode}: ${response.reasonPhrase}');
      }
    } on SocketException catch (e) {
      print('[API] Socket exception: $e');
      return ApiResult.failure(ApiError.networkError, 'Network error: Unable to connect. Check your internet.');
    } on HttpException catch (e) {
      print('[API] HTTP exception: $e');
      return ApiResult.failure(ApiError.networkError, 'HTTP error: $e');
    } on FormatException catch (e) {
      print('[API] Format exception: $e');
      return ApiResult.failure(ApiError.unknown, 'Invalid response format from server.');
    } catch (e) {
      print('[API] Unexpected error: $e');
      return ApiResult.failure(ApiError.networkError, 'Error: $e');
    }
  }

  Future<ApiResult<List<Organization>>> fetchOrganizations({
    required String sessionKey,
  }) async {
    final url = Uri.parse('$_baseUrl/organizations');
    print('[API] Fetching organizations from: $url');
    
    try {
      final response = await http.get(
        url,
        headers: _buildHeaders(sessionKey),
      ).timeout(const Duration(seconds: 30));

      print('[API] Response status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        final organizations = json
            .map((item) => Organization.fromJson(item as Map<String, dynamic>))
            .toList();
        print('[API] Found ${organizations.length} organizations');
        return ApiResult.success(organizations);
      } else if (response.statusCode == 401 || response.statusCode == 403) {
        return ApiResult.failure(ApiError.sessionExpired, 'Invalid session key. Please check and try again.');
      } else {
        return ApiResult.failure(ApiError.networkError, 'HTTP ${response.statusCode}');
      }
    } on SocketException catch (e) {
      print('[API] Socket exception: $e');
      return ApiResult.failure(ApiError.networkError, 'Network error: Unable to connect.');
    } catch (e) {
      print('[API] Error fetching organizations: $e');
      return ApiResult.failure(ApiError.networkError, 'Error: $e');
    }
  }
}

class Organization {
  final String uuid;
  final String name;

  Organization({required this.uuid, required this.name});

  factory Organization.fromJson(Map<String, dynamic> json) {
    return Organization(
      uuid: json['uuid'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

enum ApiError {
  networkError,
  sessionExpired,
  cloudflareBlocked,
  noData,
  unknown,
}

class ApiResult<T> {
  final T? data;
  final ApiError? error;
  final String? errorMessage;
  final bool isSuccess;

  ApiResult._({this.data, this.error, this.errorMessage, required this.isSuccess});

  factory ApiResult.success(T data) => ApiResult._(data: data, isSuccess: true);
  factory ApiResult.failure(ApiError error, [String? message]) => ApiResult._(
    error: error, 
    errorMessage: message ?? error.defaultMessage,
    isSuccess: false,
  );
}

extension ApiErrorMessage on ApiError {
  String get defaultMessage {
    switch (this) {
      case ApiError.networkError:
        return 'Network error. Check your connection.';
      case ApiError.sessionExpired:
        return 'Session expired. Update your session key.';
      case ApiError.cloudflareBlocked:
        return 'Request blocked. Try again later.';
      case ApiError.noData:
        return 'No data received.';
      case ApiError.unknown:
        return 'An unknown error occurred.';
    }
  }
}
