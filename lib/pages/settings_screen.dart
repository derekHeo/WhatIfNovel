import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'profile_edit_page.dart'; // 프로필 수정 페이지 import

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F2F7), // iOS 설정 화면과 동일한 연한 회색
      appBar: AppBar(
        backgroundColor: const Color(0xFFF2F2F7), // AppBar도 동일한 배경색
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios,
            color: Colors.black,
            size: 20,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text(
          '설정',
          style: TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            // 프로필 수정
            _buildSettingsItem(
              icon: Icons.person_outline,
              title: '프로필 수정',
              subtitle: '모습 학교 있는 일이나 취미가 바뀌었을 때,\n내 소개를 업데이트할 수 있어요.',
              onTap: () {
                Navigator.of(context).push(
                  CupertinoPageRoute(
                    builder: (context) => const ProfileEditPage(),
                  ),
                );
              },
            ),

            const SizedBox(height: 15),

            // 알림 설정
            _buildSettingsItem(
              icon: Icons.notifications_none,
              title: '알림 설정',
              subtitle: '지정한 시간 또는 사용 습관에 따라 알림을\n받을 수 있어요.',
              onTap: () {
                // TODO: 알림 설정 화면으로 이동
              },
            ),

            const SizedBox(height: 15),

            // 앱 정보
            _buildSettingsItem(
              icon: Icons.info_outline,
              title: '앱 정보',
              subtitle: '앱에 대한 소개와 이용 방법이 간단하게\n정리되어 있어요.',
              onTap: () {
                // TODO: 앱 정보 화면으로 이동
              },
            ),

            const Spacer(),

            // 로그아웃 버튼
            TextButton(
              onPressed: () {
                // TODO: 로그아웃 기능 구현
                _showLogoutDialog(context);
              },
              child: const Text(
                '로그아웃',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF5E6A3), // 노란색 배경
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: Colors.black,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.black54,
            ),
          ],
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext context) {
        return CupertinoAlertDialog(
          title: const Text('로그아웃'),
          content: const Text('정말 로그아웃하시겠습니까?'),
          actions: [
            CupertinoDialogAction(
              child: const Text('취소'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('로그아웃'),
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: 실제 로그아웃 로직 구현
              },
            ),
          ],
        );
      },
    );
  }
}
