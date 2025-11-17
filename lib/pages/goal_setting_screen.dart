// pages/goal_setting_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../providers/app_goal_provider.dart';
import '../providers/todo_provider.dart';
import '../models/app_goal_model.dart';
import '../widgets/app_selector_bottom_sheet.dart';

class GoalSettingScreen extends StatefulWidget {
  const GoalSettingScreen({super.key});

  @override
  State<GoalSettingScreen> createState() => _GoalSettingScreenState();
}

class _GoalSettingScreenState extends State<GoalSettingScreen> {
  // 각 앱의 목표 시간을 임시로 저장할 맵
  late Map<String, Map<String, TextEditingController>> _controllers;

  // 편집 모드 상태
  bool _isEditMode = false;

  // 삭제할 앱들을 선택하는 Set
  final Set<String> _selectedApps = {};

  @override
  void initState() {
    super.initState();
    // Provider에서 초기 데이터를 가져와 컨트롤러를 설정
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
    // 모든 컨트롤러를 정리
    _controllers.forEach((_, value) {
      value['hours']!.dispose();
      value['minutes']!.dispose();
    });
    super.dispose();
  }

  Future<void> _saveGoals() async {
    final appGoalProvider =
        Provider.of<AppGoalProvider>(context, listen: false);
    final todoProvider =
        Provider.of<TodoProvider>(context, listen: false);

    // forEach는 async/await와 호환되지 않으므로 for문 사용
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

    // Todo만 초기화 (오늘 사용량은 00시부터 누적되므로 초기화하지 않음!)
    await todoProvider.clearAllTodos();

    // 저장 완료 후 홈 화면으로 돌아가기
    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  // 앱 선택 Bottom Sheet 표시
  void _showAppSelector() {
    showCupertinoModalPopup(
      context: context,
      builder: (context) => const AppSelectorBottomSheet(),
    ).then((_) {
      // Bottom Sheet가 닫힌 후 컨트롤러 업데이트
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

  // 편집 모드 토글
  void _toggleEditMode() {
    setState(() {
      _isEditMode = !_isEditMode;
      if (!_isEditMode) {
        _selectedApps.clear(); // 편집 모드 종료 시 선택 초기화
      }
    });
  }

  // 선택된 앱들 삭제
  Future<void> _deleteSelectedApps() async {
    if (_selectedApps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('삭제할 앱을 선택해주세요')),
      );
      return;
    }

    // 삭제 확인 다이얼로그
    final confirm = await showCupertinoDialog<bool>(
      context: context,
      builder: (context) => CupertinoAlertDialog(
        title: const Text('앱 삭제'),
        content: Text('선택한 ${_selectedApps.length}개의 앱을 삭제하시겠습니까?'),
        actions: [
          CupertinoDialogAction(
            child: const Text('취소'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          CupertinoDialogAction(
            isDestructiveAction: true,
            child: const Text('삭제'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final appGoalProvider = Provider.of<AppGoalProvider>(context, listen: false);

      // 선택된 앱들 삭제
      for (var appName in _selectedApps) {
        await appGoalProvider.deleteApp(appName);
        // 컨트롤러도 삭제
        _controllers[appName]?['hours']?.dispose();
        _controllers[appName]?['minutes']?.dispose();
        _controllers.remove(appName);
      }

      setState(() {
        _selectedApps.clear();
        _isEditMode = false;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('선택한 앱이 삭제되었습니다')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // UI 빌드 시 Provider의 데이터를 사용
    final goals = Provider.of<AppGoalProvider>(context).goals;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBFA),
      appBar: AppBar(
          // ... AppBar 설정 ...
          ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            // 성공률 카드
            _buildSuccessRateCard(goals),
            const SizedBox(height: 24),
            // To-do 리스트 카드
            _buildTodoListCard(),
            const SizedBox(height: 32),
            // 저장하기 버튼
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saveGoals,
                child: const Text('저장하기',
                    style:
                        TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSuccessRateCard(List<AppGoal> goals) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              spreadRadius: 2,
              blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 헤더: 제목 + 버튼들
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('목표 사용시간', style: TextStyle(fontWeight: FontWeight.bold)),
              Row(
                children: [
                  // 편집 모드일 때 삭제 버튼 표시
                  if (_isEditMode) ...[
                    OutlinedButton.icon(
                      onPressed: _deleteSelectedApps,
                      icon: const Icon(Icons.delete, size: 18),
                      label: const Text('삭제'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  // 편집 버튼 (앱이 있을 때만 표시)
                  if (goals.isNotEmpty)
                    OutlinedButton(
                      onPressed: _toggleEditMode,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: Text(_isEditMode ? '완료' : '편집'),
                    ),
                  const SizedBox(width: 8),
                  // 앱 추가 버튼 (편집 모드가 아닐 때만 표시)
                  if (!_isEditMode)
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
            ],
          ),
          // ... 성공률 바 ...
          const SizedBox(height: 24),
          // 앱 목록이 없을 때 안내 메시지
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
    );
  }

  Widget _buildGoalInputRow(AppGoal goal) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: Row(
        children: [
          // 편집 모드일 때 체크박스 표시
          if (_isEditMode) ...[
            Checkbox(
              value: _selectedApps.contains(goal.name),
              onChanged: (checked) {
                setState(() {
                  if (checked == true) {
                    _selectedApps.add(goal.name);
                  } else {
                    _selectedApps.remove(goal.name);
                  }
                });
              },
            ),
            const SizedBox(width: 8),
          ],
          // 앱 이름 텍스트로 표시
          SizedBox(
            width: 80,
            child: Text(
              goal.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 12),
          // 편집 모드가 아닐 때만 시간 입력 필드 표시
          if (!_isEditMode) ...[
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
        ],
      ),
    );
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

  Widget _buildTodoListCard() {
    // ... To-do 리스트 UI ...
    return Container();
  }
}
