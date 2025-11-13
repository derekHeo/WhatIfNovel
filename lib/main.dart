import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'pages/start_screen.dart';
import 'providers/diary_provider.dart';
import 'providers/user_profile_provider.dart';
import 'providers/screen_time_provider.dart';
import 'providers/comment_provider.dart';
import 'providers/app_goal_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/todo_provider.dart';
import 'providers/usage_stats_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase 초기화
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => DiaryProvider()),
        ChangeNotifierProvider(create: (_) => AppGoalProvider()),
        ChangeNotifierProvider(create: (context) => UserProfileProvider()),
        ChangeNotifierProvider(create: (context) => ScreenTimeProvider()),
        ChangeNotifierProvider(create: (context) => CommentProvider()),
        ChangeNotifierProvider(create: (context) => TodoProvider()),
        ChangeNotifierProvider(create: (context) => UsageStatsProvider()),
      ],
      child: MaterialApp(
        title: 'What If',
        theme: ThemeData(
          // iOS 스타일 테마 설정
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xFF007AFF),
          scaffoldBackgroundColor: const Color(0xFFFFFCF3), // 새로운 기본 배경색
          fontFamily: '.SF UI Text', // iOS 기본 폰트
          appBarTheme: const AppBarTheme(
            systemOverlayStyle: SystemUiOverlayStyle.dark,
            backgroundColor: Colors.transparent,
            elevation: 0,
            iconTheme: IconThemeData(color: Colors.black),
            titleTextStyle: TextStyle(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          outlinedButtonTheme: OutlinedButtonThemeData(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        home: const StartScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
