import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import '../services/android_usage_service.dart';
import '../providers/app_goal_provider.dart';

/// 사용자의 실제 사용 앱 리스트를 보여주고 선택할 수 있는 Bottom Sheet
class AppSelectorBottomSheet extends StatefulWidget {
  const AppSelectorBottomSheet({super.key});

  @override
  State<AppSelectorBottomSheet> createState() => _AppSelectorBottomSheetState();
}

class _AppSelectorBottomSheetState extends State<AppSelectorBottomSheet> {
  final AndroidUsageService _usageService = AndroidUsageService();
  List<AppUsageInfo> _apps = [];
  final Set<String> _selectedPackageNames = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadApps();
  }

  Future<void> _loadApps() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // 권한 확인
      final hasPermission = await _usageService.checkUsagePermission();

      if (!hasPermission) {
        setState(() {
          _errorMessage = '앱 사용 통계 권한이 필요합니다';
          _isLoading = false;
        });
        return;
      }

      // 오늘 사용한 앱 리스트 가져오기 (최소 1분 이상 사용한 앱)
      final apps = await _usageService.getTodayUsedApps(minUsageMinutes: 1);

      setState(() {
        _apps = apps;
        _isLoading = false;
      });

      if (_apps.isEmpty) {
        setState(() {
          _errorMessage = '오늘 사용한 앱이 없습니다';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = '앱 목록을 불러오는데 실패했습니다: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _requestPermission() async {
    await _usageService.requestUsagePermission();

    // 설정 화면에서 돌아온 후 다시 확인
    await Future.delayed(const Duration(milliseconds: 500));
    await _loadApps();
  }

  void _toggleSelection(String packageName) {
    setState(() {
      if (_selectedPackageNames.contains(packageName)) {
        _selectedPackageNames.remove(packageName);
      } else {
        _selectedPackageNames.add(packageName);
      }
    });
  }

  Future<void> _confirmSelection() async {
    if (_selectedPackageNames.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('앱을 선택해주세요')),
      );
      return;
    }

    final appGoalProvider = Provider.of<AppGoalProvider>(context, listen: false);

    try {
      // 선택한 앱들을 목표에 추가
      for (var packageName in _selectedPackageNames) {
        final app = _apps.firstWhere((a) => a.packageName == packageName);

        // 이미 추가된 앱인지 확인
        final exists = appGoalProvider.goals.any((g) => g.packageName == packageName);

        if (!exists) {
          await appGoalProvider.addAppWithPackageName(
            appName: app.appName,
            packageName: app.packageName,
          );
        }
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${_selectedPackageNames.length}개 앱이 추가되었습니다')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('앱 추가 실패: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // 헤더
          _buildHeader(),

          // 내용
          Expanded(
            child: _isLoading
                ? _buildLoading()
                : _errorMessage != null
                    ? _buildError()
                    : _buildAppList(),
          ),

          // 하단 버튼
          if (!_isLoading && _errorMessage == null) _buildBottomButtons(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const SizedBox(width: 60),
          const Text(
            '앱 선택',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
          ),
          CupertinoButton(
            padding: EdgeInsets.zero,
            child: const Text('닫기'),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text(
            '앱 목록을 불러오는 중...',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.orange),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? '오류가 발생했습니다',
              style: const TextStyle(fontSize: 16, color: Colors.black87),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _requestPermission,
              icon: const Icon(Icons.settings),
              label: const Text('권한 설정하기'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _loadApps,
              child: const Text('다시 시도'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppList() {
    if (_apps.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.apps, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              '오늘 사용한 앱이 없습니다',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _apps.length,
      itemBuilder: (context, index) {
        final app = _apps[index];
        final isSelected = _selectedPackageNames.contains(app.packageName);

        return _buildAppItem(app, isSelected);
      },
    );
  }

  Widget _buildAppItem(AppUsageInfo app, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleSelection(app.packageName),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.withValues(alpha: 0.1) : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? Colors.blue : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            // 체크박스
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: isSelected ? Colors.blue : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? Colors.blue : Colors.grey.shade400,
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(Icons.check, size: 16, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: 16),

            // 앱 아이콘 (기본 아이콘 사용)
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.blue.shade100,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.apps, color: Colors.blue, size: 28),
            ),
            const SizedBox(width: 16),

            // 앱 정보
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    app.appName,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '오늘 ${app.formattedUsageTime}',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),

            // 사용 시간 (분)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${app.usageTimeMinutes}분',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 선택된 개수 표시
          if (_selectedPackageNames.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                '${_selectedPackageNames.length}개 앱 선택됨',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

          // 확인 버튼
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: _selectedPackageNames.isNotEmpty ? _confirmSelection : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                disabledBackgroundColor: Colors.grey.shade300,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: const Text(
                '선택 완료',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
