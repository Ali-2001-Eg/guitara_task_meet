import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:guitara_task/core/service_locator/service_locator.dart';
import 'package:guitara_task/feature/web_rtc/choose_name_screen.dart';
import 'feature/web_rtc/get_stream_screen.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await DI.init();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const ChooseNameScreen(),
        ),
        GoRoute(
          path: '/webrtc/:userName',
          builder: (context, state) {
            final userName = state.pathParameters['userName']!;
            return GetStreamScreenIO(userName: userName);
          },
        ),
      ],
    );

    return MaterialApp.router(
      title: 'Video Call App',
      scaffoldMessengerKey: scaffoldMessengerKey,
      routerConfig: router,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
    );
  }
}
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();
final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();
