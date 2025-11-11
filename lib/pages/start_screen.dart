import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:page_transition/page_transition.dart';
import '../providers/auth_provider.dart';
import '../providers/user_profile_provider.dart';
import '../providers/app_goal_provider.dart';
import '../providers/todo_provider.dart';
import 'home_screen.dart';
import 'profile_edit_page.dart';

class StartScreen extends StatefulWidget {
  const StartScreen({super.key});

  @override
  State<StartScreen> createState() => _StartScreenState();
}

class _StartScreenState extends State<StartScreen> {
  @override
  void initState() {
    super.initState();
    // 이미 로그인된 사용자가 있으면 자동으로 홈 화면으로 이동
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      print('[StartScreen] 자동 로그인 체크 시작');
      print('[StartScreen] 로그인 상태: ${authProvider.isLoggedIn}');
      print('[StartScreen] 사용자 이메일: ${authProvider.userEmail}');

      if (authProvider.isLoggedIn) {
        // 로그인 상태일 때 프로필과 목표 데이터 로드
        print('[StartScreen] 로그인 상태 확인 - 사용자 데이터 로드 시작');
        await _loadUserData();
        if (mounted) {
          _navigateToNextScreen();
        }
      }
    });
  }

  /// 사용자 데이터 로드 (프로필 + 목표 + Todo)
  Future<void> _loadUserData() async {
    final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);
    final appGoalProvider = Provider.of<AppGoalProvider>(context, listen: false);
    final todoProvider = Provider.of<TodoProvider>(context, listen: false);

    print('[StartScreen] 사용자 데이터 로드 시작');

    await Future.wait([
      userProfileProvider.reloadProfile(),
      appGoalProvider.reloadGoals(),
      todoProvider.reloadTodos(),
    ]);

    print('[StartScreen] 사용자 데이터 로드 완료');
    print('[StartScreen] 프로필 이름: ${userProfileProvider.userProfile.name}');
    print('[StartScreen] 필수 프로필 존재: ${userProfileProvider.hasRequiredProfile}');
  }

  /// 프로필 상태에 따라 다음 화면으로 이동
  void _navigateToNextScreen() {
    final userProfileProvider = Provider.of<UserProfileProvider>(context, listen: false);

    print('[StartScreen] 화면 이동 결정');
    print('[StartScreen] hasRequiredProfile: ${userProfileProvider.hasRequiredProfile}');

    // 프로필 필수 정보가 없으면 프로필 작성 페이지로 이동
    if (!userProfileProvider.hasRequiredProfile) {
      print('[StartScreen] 프로필 작성 페이지로 이동');
      Navigator.of(context).pushReplacement(
        PageTransition(
          type: PageTransitionType.fade,
          child: const ProfileEditPage(isFirstTime: true),
          duration: const Duration(milliseconds: 400),
        ),
      );
    } else {
      // 프로필이 있으면 홈 화면으로 이동
      print('[StartScreen] 홈 화면으로 이동');
      Navigator.of(context).pushReplacement(
        PageTransition(
          type: PageTransitionType.fade,
          child: const HomeScreen(),
          duration: const Duration(milliseconds: 400),
        ),
      );
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    print('[StartScreen] Google 로그인 시작');
    final success = await authProvider.signInWithGoogle();

    if (success && mounted) {
      print('[StartScreen] Google 로그인 성공 - 사용자 데이터 로드 시작');
      // 로그인 성공 후 사용자 데이터 로드
      await _loadUserData();

      if (mounted) {
        _navigateToNextScreen();
      }
    } else if (authProvider.errorMessage != null && mounted) {
      print('[StartScreen] Google 로그인 실패: ${authProvider.errorMessage}');
      // 에러 발생 시 알림 표시
      showCupertinoDialog(
        context: context,
        builder: (context) => CupertinoAlertDialog(
          title: const Text('로그인 실패'),
          content: Text(authProvider.errorMessage ?? '알 수 없는 오류가 발생했습니다.'),
          actions: [
            CupertinoDialogAction(
              isDefaultAction: true,
              child: const Text('확인'),
              onPressed: () {
                Navigator.of(context).pop();
                authProvider.clearError();
              },
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6A3),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 2),
                // 로고 텍스트
                const Text(
                  'what if',
                  style: TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF007AFF),
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '평행우주의 나를 만나보세요',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.black54,
                    fontWeight: FontWeight.w400,
                  ),
                ),
                const Spacer(flex: 3),
                // 구글 로그인 버튼
                Consumer<AuthProvider>(
                  builder: (context, authProvider, child) {
                    if (authProvider.isLoading) {
                      return const CupertinoActivityIndicator(radius: 16);
                    }
                    return SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: ElevatedButton.icon(
                        onPressed: _handleGoogleSignIn,
                        icon: Image.asset(
                          'assets/images/google_logo.png',
                          height: 24,
                          width: 24,
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.login, color: Colors.white);
                          },
                        ),
                        label: const Text(
                          'Google로 시작하기',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF007AFF),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
