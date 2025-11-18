import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AIGenerationLoadingDialog extends StatefulWidget {
  final VoidCallback? onComplete; // 100% 도달 시 호출될 콜백

  const AIGenerationLoadingDialog({super.key, this.onComplete});

  @override
  State<AIGenerationLoadingDialog> createState() =>
      _AIGenerationLoadingDialogState();
}

class _AIGenerationLoadingDialogState extends State<AIGenerationLoadingDialog>
    with SingleTickerProviderStateMixin {
  double _progress = 0.0;
  int _currentStepIndex = 0;

  // 단계별 메시지와 예상 시간 (초)
  // 실제 API 응답 시간: 약 55-60초
  final List<Map<String, dynamic>> _steps = [
    {
      'message': '사용 시간 데이터를 분석하는 중이에요...',
      'duration': 12, // 12초
      'icon': '📊',
    },
    {
      'message': 'AI가 당신의 패턴을 학습하고 있어요...',
      'duration': 15, // 15초
      'icon': '🤖',
    },
    {
      'message': '미래 예측 시나리오를 구성하는 중이에요...',
      'duration': 18, // 18초
      'icon': '🔮',
    },
    {
      'message': '스토리를 다듬고 완성하는 중이에요...',
      'duration': 20, // 20초
      'icon': '✨',
    },
  ];

  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _startProgress();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  /// 진행률 시뮬레이션
  void _startProgress() {
    // 총 예상 시간 계산
    final totalDuration =
        _steps.fold<int>(0, (sum, step) => sum + (step['duration'] as int));

    int elapsedTime = 0;

    // 1초마다 진행률 업데이트
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));

      if (!mounted) return false;

      elapsedTime++;

      // 현재 단계 확인
      int accumulatedTime = 0;
      for (int i = 0; i < _steps.length; i++) {
        accumulatedTime += _steps[i]['duration'] as int;
        if (elapsedTime <= accumulatedTime) {
          if (_currentStepIndex != i) {
            setState(() {
              _currentStepIndex = i;
            });
          }
          break;
        }
      }

      // 전체 진행률 계산 (100%까지 도달)
      final newProgress = (elapsedTime / totalDuration).clamp(0.0, 1.0);

      setState(() {
        _progress = newProgress;
      });

      // 100% 도달 시 콜백 실행
      if (_progress >= 1.0 && widget.onComplete != null) {
        widget.onComplete!();
        return false; // 루프 종료
      }

      // 진행률이 100% 미만이면 계속
      return _progress < 1.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentStep = _steps[_currentStepIndex];

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFCF3),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 20,
              spreadRadius: 5,
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 상단 아이콘 애니메이션
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 500),
              child: Text(
                currentStep['icon'],
                key: ValueKey(_currentStepIndex),
                style: const TextStyle(fontSize: 64),
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .shimmer(duration: 2000.ms)
                .shake(hz: 2, curve: Curves.easeInOutCubic),

            const SizedBox(height: 24),

            // AI 생성 중 타이틀
            const Text(
              'What If 시나리오 생성 중',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            )
                .animate()
                .fadeIn(duration: 600.ms)
                .slideY(begin: -0.2, end: 0),

            const SizedBox(height: 16),

            // 단계별 메시지
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 600),
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.3),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: Text(
                currentStep['message'],
                key: ValueKey(_currentStepIndex),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: Colors.black54,
                  height: 1.5,
                ),
              ),
            ),

            const SizedBox(height: 32),

            // 프로그레스 바
            Stack(
              alignment: Alignment.centerLeft,
              children: [
                // 배경 프로그레스 바
                Container(
                  height: 12,
                  width: MediaQuery.of(context).size.width * 0.7,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                // 진행 프로그레스 바
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 1000),
                    curve: Curves.easeInOut,
                    height: 12,
                    width: MediaQuery.of(context).size.width * 0.7 * _progress,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.blue.shade400,
                          Colors.purple.shade400,
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  )
                      .animate(onPlay: (controller) => controller.repeat())
                      .shimmer(
                        duration: 2000.ms,
                        color: Colors.white.withOpacity(0.3),
                      ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // 퍼센트 표시
            Text(
              '${(_progress * 100).toInt()}%',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.blue.shade700,
              ),
            )
                .animate(onPlay: (controller) => controller.repeat())
                .fadeIn(duration: 800.ms)
                .then()
                .fadeOut(duration: 800.ms),

            const SizedBox(height: 24),

            // 단계 인디케이터
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(_steps.length, (index) {
                final isActive = index == _currentStepIndex;
                final isCompleted = index < _currentStepIndex;

                return Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  width: isActive ? 24 : 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? Colors.blue.shade600
                        : isActive
                            ? Colors.blue.shade400
                            : Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
                    .animate(target: isActive ? 1 : 0)
                    .scaleX(duration: 300.ms, begin: 0.5, end: 1);
              }),
            ),

            const SizedBox(height: 16),

            // 안내 문구
            Text(
              '잠시만 기다려주세요. 멋진 시나리오를 만들고 있어요!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ).animate().fadeIn(delay: 500.ms, duration: 800.ms),
          ],
        ),
      ),
    );
  }
}
