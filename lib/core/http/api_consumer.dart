import 'dart:convert';
import 'dart:developer';
import 'package:guitara_task/core/extensions/context_extension.dart';

import '../../main.dart';
import '../helper/logger.dart';
import 'either.dart';
import 'failure.dart';
import 'package:dio/dio.dart';

abstract final class ApiConsumer {
  Future<Either<Failure, Map<String, dynamic>>> get(
    String url, {
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? data,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  });

  Future<Either<Failure, Map<String, dynamic>>> post(
    String url, {
    Map<String, dynamic>? data,
    FormData? formData,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

   Future<Either<Failure, Map<String, dynamic>>> postFormData(
    String url, {
    Map<String, dynamic>? data,
    FormData? formData,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  Future<Either<Failure, Map<String, dynamic>>> patch(
    String url, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  Future<Either<Failure, Map<String, dynamic>>> put(
    String url, {
    Object? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    bool formData = false,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  Future<Either<Failure, Map<String, dynamic>>> delete(
    String url, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
  });

  Future<Either<Failure, String>> downloadFile({
    required String url,
    required String savePath,
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  });

  Future<Either<Failure, Map<String, dynamic>>> head(String url, {
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  });

  Future<Either<Failure, Map<String, dynamic>>> uploadFile(
    String url, {
    required Map<String, dynamic> formData,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  });

  void addInterceptor(Interceptor interceptor);

  void removeAllInterceptors();

  void updateHeader(Map<String, dynamic> headers);

  Future<Either<Failure, Map<String, dynamic>>> retryApiCall(
    Future<Either<Failure, Map<String, dynamic>>> Function() apiCall, {
    int retryCount = 0,
  });
}

final class BaseApiConsumer implements ApiConsumer {
  final Dio _dio;
  final int maxRetries;
  final Duration retryDelay;

  BaseApiConsumer({
    required Dio dio,
    int maxRetries = 5,
    Duration retryDelay = const Duration(seconds: 2),
  })  : _dio = dio,
        maxRetries = 2,
        retryDelay = const Duration(seconds: 5);

  @override
  Future<Either<Failure, Map<String, dynamic>>> retryApiCall(
    Future<Either<Failure, Map<String, dynamic>>> Function() apiCall, {
    int retryCount = 2,
  }) async {
    final result = await apiCall();
    return result.fold(
      (failure) async {
        if (retryCount < maxRetries) {
          log("API failed, retrying attempt #${retryCount + 1}");
          await Future.delayed(retryDelay);
          return retryApiCall(apiCall, retryCount: retryCount + 1); //recursion
        } else {
          log("Max retries reached, API failed: ${failure.message}");
          return Left(failure);
        }
      },
      (success) => Right(success),
    );
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> get(
    String url, {
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? data,
    CancelToken? cancelToken,
    ProgressCallback? onReceiveProgress,
  }) async {
    apiCall() async {
      try {
        final response = await _dio.get(
          url,
          queryParameters: queryParameters,
          options: Options(headers: headers),
          cancelToken: cancelToken,
          data: data,
          onReceiveProgress: onReceiveProgress,
        );
        return Right<Failure, Map<String, dynamic>>(
            response.data as Map<String, dynamic>);
      } on DioException catch (e) {
        loggerError(e.toString());
        final failure = _handleDioError(e);
        return Left<Failure, Map<String, dynamic>>(failure);
      } catch (e) {
        return Left<Failure, Map<String, dynamic>>(
            UnknownFailure(message: 'An unexpected error occurred: $e'));
      }
    }

    return await retryApiCall(apiCall);
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> head(String url, {
    Map<String, dynamic>? headers,
    Map<String, dynamic>? queryParameters,
    CancelToken? cancelToken,
  }) async {
          try {
        final response = await _dio.head(
          url,
          queryParameters: queryParameters,
          options: Options(headers: headers),
          cancelToken: cancelToken,
        );
        return Right<Failure, Map<String, dynamic>>(
            response.data as Map<String, dynamic>);
      } on DioException catch (e) {
        loggerError(e.toString());
        final failure = _handleDioError(e);
        return Left<Failure, Map<String, dynamic>>(failure);
      } catch (e) {
            return Left<Failure, Map<String, dynamic>>(
            UnknownFailure(message: 'An unexpected error occurred: $e'));
      }
    }

  @override
  Future<Either<Failure, Map<String, dynamic>>> patch(
    String url, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      Response response = await _dio.patch(
        url,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: cancelToken,
        data: data,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      return Right(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      loggerError(e.toString());
      final failure = _handleDioError(e);
      return Left(failure);
    } catch (e) {
      return Left(UnknownFailure(
          message: 'An unexpected error occurred${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> post(
    String url, {
    Map<String, dynamic>? data,
    FormData? formData,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      Response response = await _dio.post(
        url,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        data: data,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      log('right');
      return Right(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      log('left $e');
      loggerError(e.toString());
      final failure = _handleDioError(e);
      return Left(failure);
    } catch (e) {
      return Left(UnknownFailure(
          message: 'An unexpected error occurred${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> put(
    String url, {
    Object? data,
    bool formData = false,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      Response response = await _dio.put(
        url,
        queryParameters: queryParameters,
        options: Options(headers: headers),
        cancelToken: cancelToken,
        data: data,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      return Right(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      loggerError(e.toString());
      final failure = _handleDioError(e);
      return Left(failure);
    } catch (e) {
      return Left(UnknownFailure(
          message: 'An unexpected error occurred${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> delete(
    String url, {
    Map<String, dynamic>? data,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      Response response = await _dio.delete(
        url,
        queryParameters: queryParameters,
        data: data,
        options: Options(headers: headers),
        cancelToken: cancelToken,
      );

      return Right(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      loggerError(e.toString());
      final failure = _handleDioError(e);
      return Left(failure);
    } catch (e) {
      return Left(UnknownFailure(
          message: 'An unexpected error occurred${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, String>> downloadFile({
    required String url,
    required String savePath,
    ProgressCallback? onReceiveProgress,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    try {
      await _dio.download(
        url,
        savePath,
        onReceiveProgress: onReceiveProgress,
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
      );

      return Right(savePath); // Return the saved file path
    } on DioException catch (e) {
      loggerError(e.toString());
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(
          message: 'An unexpected error occurred ${e.toString()}'));
    }
  }

  @override
  Future<Either<Failure, Map<String, dynamic>>> uploadFile(String url,
      {required Map<String, dynamic> formData,
      Map<String, dynamic>? queryParameters,
      Options? options,
      CancelToken? cancelToken,
      ProgressCallback? onSendProgress,
      ProgressCallback? onReceiveProgress}) async {
    try {
      Response response = await _dio.post(
        url,
        data: FormData.fromMap(formData),
        queryParameters: queryParameters,
        options: options,
        cancelToken: cancelToken,
        onSendProgress: onSendProgress,
        onReceiveProgress: onReceiveProgress,
      );

      return Right(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      loggerError(e.toString());
      return Left(_handleDioError(e));
    } catch (e) {
      return Left(UnknownFailure(
          message: 'An unexpected error occurred${e.toString()}'));
    }
  }

  @override
  void removeAllInterceptors() {
    _dio.options.headers.clear();
  }

  @override
  void updateHeader(Map<String, dynamic> headers) {
    _dio.options.headers.addAll(headers);
  }

  @override
  void addInterceptor(Interceptor interceptor) {
    _dio.interceptors.add(interceptor);
  }

  Failure _handleDioError(DioException error) {
    switch (error.type) {
      case DioExceptionType.cancel:
        navigatorKey.currentContext!.showErrorMessage('تم الغاء الطلب ');
        return ServerFailure(message: 'تم إلغاء الطلب ');
      case DioExceptionType.connectionTimeout:
        navigatorKey.currentContext!.showErrorMessage('انتهت مهلة الاتصال ');
        return ServerFailure(message: 'انتهت مهلة الاتصال ');
      case DioExceptionType.receiveTimeout:
        navigatorKey.currentContext!.showErrorMessage('انتهت مهلة الاتصال ');
        return ServerFailure(message: 'انتهت مهلة الاستقبال في الاتصال ');
      case DioExceptionType.sendTimeout:
        navigatorKey.currentContext!.showErrorMessage('انتهت مهلة الاتصال ');
        return ServerFailure(message: 'انتهت مهلة الإرسال في الاتصال ');
      case DioExceptionType.badResponse:
        if (error.response?.data != null) {
          try {
            final data = error.response!.data;
            final Map<String, dynamic> decoded =
                data is String ? json.decode(data) : data;
            if (error.response?.statusCode == 503) {
              return ServerFailure(message: 'network failure ${error.message}');
            }
            if (error.response?.statusCode == 401) {
              navigatorKey.currentContext!.showErrorMessage('عاود التسجيل من فضلك');
              return UnauthorizedFailure(
                  message: error.message ?? 'غير مصرح لك');
            }
            if (error.response?.statusCode == 413) {
              navigatorKey.currentContext!
                  .showErrorMessage('File size is too large');

              return ServerFailure(
                message: 'File size is too large',
              );
            }
            if(error.response?.statusCode == 404){
              navigatorKey.currentContext!.showErrorMessage('404');
              return ServerFailure(
                message: '404',
              );
            }
            if (error.response?.statusCode == 407) {
              loggerWarn('APP IS OPENED IN ANOTHER DEVICE');
              return SyncAppFailure(message: 'تم فتح التطبيق في جهاز آخر');
            }
            if(error.response?.statusCode == 402){
              return PaymentFailure(message: error.message??"");
            }
            // Handle OTP failure for 409 status code
            if (error.response?.statusCode == 409) {
              loggerWarn('VERIFYERROR');
              return VerifyOTPFailure(message: 'خطأ في التحقق من الكود');
            }
            if (decoded.containsKey('message')) {
              String message = decoded['message'];

              // Process validation errors if present
              // 🧠 Handle validation errors
              if (decoded.containsKey('result') && decoded['result'] is Map) {
                final errors = decoded['result'] as Map<String, dynamic>;
                List<String> messages = [];

                errors.forEach((key, value) {
                  if (value is List) {
                    messages.addAll(value.map((e) => '$key: $e'));
                  } else if (value is String) {
                    messages.add('$key: $value');
                  }
                });

                final message = decoded['message'] ?? 'حدث خطأ ما';

                // Show first message to user
                if (messages.isNotEmpty) {
                  navigatorKey.currentContext!.showErrorMessage(messages.first);
                }

                return ValidationFailure(
                  message: messages.first,
                  errors: messages,
                );
              }



              // navigatorKey.currentContext!.showErrorMessage(message);
              return ServerFailure(message: message);
            }
          } catch (e) {
            // navigatorKey.currentContext!.showErrorMessage(e.toString());
            return ServerFailure(
                message:
                    'Received invalid status code: ${error.response?.statusCode}');
          }
        }
        // navigatorKey.currentContext!.showErrorMessage(error.message!);
        return ServerFailure(
            message:
                'Received invalid status code: ${error.response?.statusCode}');
      case DioExceptionType.badCertificate:
        return ServerFailure(message: 'تعذر الاتصال ');
      case DioExceptionType.connectionError:
        navigatorKey.currentContext!.showErrorMessage('تعذر الاتصال ');
        return NetworkFailure(message: 'تعذر الاتصال ');
      case DioExceptionType.unknown:
      default:
        return UnknownFailure(message: 'Unexpected error: ${error.message}');
    }
  }
  
  @override
  Future<Either<Failure, Map<String, dynamic>>> postFormData(
     String url, {
    Map<String, dynamic>? data,
    FormData? formData,
    Map<String, dynamic>? queryParameters,
    Map<String, dynamic>? headers,
    CancelToken? cancelToken,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      Response response = await _dio.post(
        url,
        queryParameters: queryParameters,
        options: Options(headers: headers ),
        data: formData,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
        onReceiveProgress: onReceiveProgress,
      );
      log('right');
      return Right(response.data as Map<String, dynamic>);
    } on DioException catch (e) {
      log('left $e');
      loggerError(e.toString());
      final failure = _handleDioError(e);
      return Left(failure);
    } catch (e) {
      return Left(UnknownFailure(
          message: 'An unexpected error occurred${e.toString()}'));
    }
  }
  }

