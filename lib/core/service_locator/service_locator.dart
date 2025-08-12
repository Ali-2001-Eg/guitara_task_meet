import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:guitara_task/core/extensions/context_extension.dart';
import 'package:guitara_task/core/http/api_consumer.dart';
import 'package:guitara_task/main.dart';
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

final GetIt getIt = GetIt.instance;
class DI {
  static Future<void> init() async{
    getIt.registerLazySingleton<Dio>(
      () {
        return Dio(
          BaseOptions(
            baseUrl: "",
            connectTimeout: const Duration(seconds: 60),
            headers: {
              'Accept': 'application/json',
              'Content-Type': 'application/json',
              'Cache-Control': 'no-cache',
              'Pragma': 'no-cache',
              'Accept-Language':
                  navigatorKey.currentContext?.isArabic??true ? 'ar' : 'en',
              'Authorization': 'Bearer ',
            },
          ),
        )..interceptors.addAll([
            if (kDebugMode)
              PrettyDioLogger(
                requestHeader: true,
                requestBody: true,
                responseBody: true,
                responseHeader: false,
                error: true,
                compact: true,
                enabled: true,
                request: true,
                maxWidth: 90,
              ),
          ]);
      },
    );
  getIt.registerLazySingleton<ApiConsumer>(() => BaseApiConsumer(dio: getIt<Dio>()));
  }

}