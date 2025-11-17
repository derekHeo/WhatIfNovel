import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/app_goal_provider.dart';
import '../services/android_usage_service.dart';
import '../widgets/app_selector_bottom_sheet.dart';
import 'home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> with WidgetsBindingObserver {
  int _currentStep = 0; // 0: 환영, 1: 권한, 2: 앱 선택 & 목표 설정
  bool _hasPermission = false;
  late Map<String, Map<String, TextEditingController>> _controllers;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkPermission();
    final goals = Provider.of<AppGoalProvider>(context, listen: false).goals;
    _controllers = {
      for (var goal in goals)
        goal.name: {
          'hours': TextEditingController(text: goal.goalHours.toString()),
          'minutes': TextEditingController(text: goal.goalMinutes.toString()),
        }
    };
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controllers.forEach((_, value) {
      value['hours']!.dispose();
      value['minutes']!.dispose();
    });
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    // 앱이 포그라운드로 돌아올 때 권한 상태 다시 확인
    if (state == AppLifecycleState.resumed && _currentStep == 1) {
      _checkPermission();
    }
  }

  Future<void> _checkPermission() async {
    final usageService = AndroidUsageService();
    final hasPermission = await usageService.checkUsagePermission();
    setState(() {
      _hasPermission = hasPermission;
      // 권한이 허용되고 권한 단계에 있다면 자동으로 다음 단계로
      if (_hasPermission && _currentStep == 1) {
        _currentStep = 2;
      }
    });
  }

  Future<void> _requestPermission() async {
    final usageService = AndroidUsageService();
    await usageService.requestUsagePermission();
    // 앱이 포그라운드로 돌아올 때 didChangeAppLifecycleState에서 자동으로 권한 확인
  }

  void _showAppSelector() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => const AppSelectorBottomSheet(),
    ).then((_) {
      setState(() {
        final goals = Provider.of<AppGoalProvider>(context, listen: false).goals;
        for (var goal in goals) {
          if (!_controllers.containsKey(goal.name)) {
            _controllers[goal.name] = {
              'hours': TextEditingController(text: goal.goalHours.toString()),
              'minutes': TextEditingController(text: goal.goalMinutes.toString()),
            };
          }
        }
      });
    });
  }

  Future<void> _completeOnboarding() async {
    final appGoalProvider = Provider.of<AppGoalProvider>(context, listen: false);

    // 목표 저장
    for (var entry in _controllers.entries) {
      final appName = entry.key;
      final controllers = entry.value;
      final hours = int.tryParse(controllers['hours']!.text) ?? 0;
      final minutes = int.tryParse(controllers['minutes']!.text) ?? 0;

      // 시간과 분이 모두 0인 경우 체크
      final totalMinutes = hours * 60 + minutes;
      if (totalMinutes == 0) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$appName의 목표 시간은 최소 1분 이상이어야 합니다'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        return; // 저장 중단
      }

      await appGoalProvider.updateGoal(appName, hours, minutes);
    }

    // 온보딩 완료 플래그 저장
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('onboarding_completed', true);

    // 홈 화면으로 이동
    if (mounted) {
      Navigator.of(context).pushReplacement(
        CupertinoPageRoute(builder: (context) => const HomeScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBFA),
      body: SafeArea(
        child: _buildCurrentStep(),
      ),
    );
  }

  Widget _buildCurrentStep() {
    switch (_currentStep) {
      case 0:
        return _buildWelcomeStep();
      case 1:
        return _buildPermissionStep();
      case 2:
        return _buildGoalSettingStep();
      default:
        return const SizedBox();
    }
  }

  // Step 0: 환영 메시지
  Widget _buildWelcomeStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.waving_hand,
            size: 80,
            color: Colors.orange,
          ),
          const SizedBox(height: 32),
          const Text(
            '안녕하세요!',
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            '저희 서비스는 스마트폰 사용시간을 토대로\n2가지 다른 미래 시나리오를 생성해드립니다.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () {
                setState(() {
                  _currentStep = 1;
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '시작하기',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 1: 권한 요청
  Widget _buildPermissionStep() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _hasPermission ? Icons.check_circle : Icons.shield,
            size: 80,
            color: _hasPermission ? Colors.green : Colors.blue,
          ),
          const SizedBox(height: 32),
          Text(
            _hasPermission ? '권한이 허용되었습니다!' : '앱 사용 통계 권한이 필요합니다',
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            _hasPermission
                ? '이제 앱을 선택하고 목표 시간을 설정해주세요.'
                : '스마트폰 사용 시간을 분석하기 위해\n앱 사용 통계 권한이 필요합니다.',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey.shade700,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _hasPermission
                  ? () {
                      setState(() {
                        _currentStep = 2;
                      });
                    }
                  : _requestPermission,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                _hasPermission ? '다음' : '권한 허용하기',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Step 2: 앱 선택 & 목표 설정
  Widget _buildGoalSettingStep() {
    final goals = Provider.of<AppGoalProvider>(context).goals;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            '간단히 목표 시간 설정을 통해\n서비스를 시작해보세요!',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 32),
          // 앱 선택 & 목표 설정 카드
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 2,
                  blurRadius: 10,
                )
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      '목표 사용시간',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    OutlinedButton.icon(
                      onPressed: _showAppSelector,
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('앱 추가'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (goals.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 32.0),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.apps, size: 48, color: Colors.grey),
                          SizedBox(height: 12),
                          Text(
                            '등록된 앱이 없습니다',
                            style: TextStyle(color: Colors.grey, fontSize: 14),
                          ),
                          SizedBox(height: 4),
                          Text(
                            '"앱 추가" 버튼을 눌러 시작하세요',
                            style: TextStyle(color: Colors.grey, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  ...goals.map((goal) => _buildGoalInputRow(goal)).toList(),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // 시작하기 버튼
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: goals.isEmpty ? null : _completeOnboarding,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                '시작해보기',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalInputRow(goal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    goal.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('목표:'),
                const SizedBox(width: 8),
                _buildTimeInput(_controllers[goal.name]!['hours']!),
                const SizedBox(width: 4),
                const Text('h'),
                const SizedBox(width: 8),
                _buildTimeInput(_controllers[goal.name]!['minutes']!),
                const SizedBox(width: 4),
                const Text('m'),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, size: 20, color: Colors.red),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            onPressed: () => _deleteApp(goal.name),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteApp(String appName) async {
    final appGoalProvider = Provider.of<AppGoalProvider>(context, listen: false);

    // 컨트롤러 제거
    if (_controllers.containsKey(appName)) {
      _controllers[appName]!['hours']!.dispose();
      _controllers[appName]!['minutes']!.dispose();
      _controllers.remove(appName);
    }

    // Provider에서 삭제
    await appGoalProvider.deleteApp(appName);

    setState(() {
      // UI 업데이트
    });
  }

  Widget _buildTimeInput(TextEditingController controller) {
    return SizedBox(
      width: 50,
      height: 35,
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly, // 숫자만 입력 가능
        ],
        decoration: InputDecoration(
          contentPadding: EdgeInsets.zero,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        ),
      ),
    );
  }
}
