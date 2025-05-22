import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:novel_diary/providers/screen_time_provider.dart';
import 'package:novel_diary/models/screen_time_model.dart';

/// 컴팩트한 iOS 스타일 스크린타임 위젯
class CompactScreenTimeWidget extends StatelessWidget {
  final VoidCallback? onTap;

  const CompactScreenTimeWidget({
    super.key,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Consumer<ScreenTimeProvider>(
      builder: (context, provider, child) {
        return GestureDetector(
          onTap: onTap,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF2C2C2E), // iOS 다크 모드 카드 색상
              borderRadius: BorderRadius.circular(12),
            ),
            child: _buildContent(context, provider),
          ),
        );
      },
    );
  }

  Widget _buildContent(BuildContext context, ScreenTimeProvider provider) {
    // 스크린타임 사용 불가능
    if (!provider.isScreenTimeAvailable) {
      return _buildUnavailableContent();
    }

    // 권한 없음
    if (!provider.hasPermission) {
      return _buildPermissionContent(provider);
    }

    // 에러 상태
    if (provider.hasError) {
      return _buildErrorContent(provider);
    }

    // 로딩 상태
    if (provider.isLoading && !provider.hasData) {
      return _buildLoadingContent();
    }

    // 데이터 표시
    if (provider.hasData) {
      return _buildDataContent(provider);
    }

    // 데이터 없음
    return _buildNoDataContent();
  }

  /// 스크린타임 사용 불가능
  Widget _buildUnavailableContent() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.access_time,
            color: Colors.orange,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '스크린 타임',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '이 기기에서는 사용할 수 없습니다',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 권한 요청
  Widget _buildPermissionContent(ScreenTimeProvider provider) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.access_time,
            color: Colors.blue,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '스크린 타임',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '권한을 허용해주세요',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        if (!provider.isPermissionLoading)
          GestureDetector(
            onTap: () => provider.requestPermission(),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.blue,
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                '허용',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        if (provider.isPermissionLoading)
          const SizedBox(
            width: 16,
            height: 16,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.blue,
            ),
          ),
      ],
    );
  }

  /// 에러 상태
  Widget _buildErrorContent(ScreenTimeProvider provider) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.access_time,
            color: Colors.red,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '스크린 타임',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '오류가 발생했습니다',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 로딩 상태
  Widget _buildLoadingContent() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.grey,
            ),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '스크린 타임',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '데이터 로딩 중...',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 데이터 없음
  Widget _buildNoDataContent() {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Icon(
            Icons.access_time,
            color: Colors.grey,
            size: 20,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '스크린 타임',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 2),
              Text(
                '데이터 없음',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// 데이터 표시
  Widget _buildDataContent(ScreenTimeProvider provider) {
    final todayData = provider.todayData!;
    final topApp =
        todayData.topUsedApps.isNotEmpty ? todayData.topUsedApps.first : null;

    return Column(
      children: [
        // 첫 번째 줄: 아이콘 + 제목 + 새로고침 버튼
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF007AFF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(
                Icons.access_time,
                color: Color(0xFF007AFF),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                '스크린 타임',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            GestureDetector(
              onTap: provider.isRefreshing
                  ? null
                  : () => provider.refreshAllData(),
              child: Container(
                padding: const EdgeInsets.all(6),
                child: provider.isRefreshing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white70,
                        ),
                      )
                    : const Icon(
                        Icons.refresh,
                        color: Colors.white70,
                        size: 16,
                      ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 12),

        // 두 번째 줄: 총 사용시간 + 가장 많이 사용한 앱
        Row(
          children: [
            // 총 사용시간
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '오늘',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    todayData.formattedTotalUsageTime,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),

            // 구분선
            Container(
              width: 1,
              height: 30,
              color: Colors.white24,
              margin: const EdgeInsets.symmetric(horizontal: 12),
            ),

            // 가장 많이 사용한 앱
            Expanded(
              flex: 3,
              child: topApp != null
                  ? Row(
                      children: [
                        _buildAppIcon(topApp.iconData, size: 24),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                topApp.appName,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                topApp.formattedUsageTime,
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                  : Text(
                      '${todayData.totalAppsUsed}개 앱 사용',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                      ),
                    ),
            ),
          ],
        ),
      ],
    );
  }

  /// 앱 아이콘 위젯
  Widget _buildAppIcon(String? iconData, {double size = 24}) {
    if (iconData != null && iconData.isNotEmpty) {
      try {
        final bytes = base64Decode(iconData);
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(size * 0.2),
            image: DecorationImage(
              image: MemoryImage(bytes),
              fit: BoxFit.cover,
            ),
          ),
        );
      } catch (e) {
        // Base64 디코딩 실패시 기본 아이콘 사용
      }
    }

    // 기본 아이콘
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white24,
        borderRadius: BorderRadius.circular(size * 0.2),
      ),
      child: Icon(
        Icons.apps,
        color: Colors.white60,
        size: size * 0.6,
      ),
    );
  }
}
