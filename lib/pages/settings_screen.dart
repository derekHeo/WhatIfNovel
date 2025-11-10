import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'profile_edit_page.dart'; // 프로필 수정 페이지 import
import 'start_screen.dart'; // 로그인 화면 import
import '../providers/auth_provider.dart';
import '../services/firestore_service.dart';
import '../models/inquiry_model.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // ✨ 배경색을 디자인에 맞게 변경
      backgroundColor: const Color(0xFFFDFBFA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back, // iOS 스타일보다 Material 기본 아이콘이 더 잘 어울립니다.
            color: Colors.black,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          '설정',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
            child: Column(
              children: [
                // ✨ 새로운 UI를 위한 카드 위젯 호출
                _buildSettingsCard(
                  title: '프로필 수정',
                  description: '요즘 하고 있는 일이나 취미가 바뀌었을 때, 내 소개를 업데이트할 수 있어요.',
                  onTap: () {
                    Navigator.of(context).push(
                      CupertinoPageRoute(
                        builder: (context) => const ProfileEditPage(),
                      ),
                    );
                  },
                ),
                _buildSettingsCard(
                  title: '초기화 시간 설정',
                  description: '휴대폰 사용시간이 초기화 되는 시간대를 변경할 수 있어요.',
                  onTap: () {
                    // TODO: 초기화 시간 설정 화면으로 이동
                  },
                ),
                _buildSettingsCard(
                  title: '문의하기',
                  description: '앱 사용 또는 실험에 관련된 문의 사항을 보낼 수 있어요.',
                  onTap: () => _showInquiryDialog(context),
                ),
                _buildSettingsCard(
                  title: '실험 규칙',
                  description: '앱 사용 방법과 실험 규칙이 정리되어 있어요.',
                  onTap: () {
                    // TODO: 실험 규칙 화면으로 이동
                  },
                ),
                const SizedBox(height: 20),

                // ✨ 로그아웃 버튼을 OutlinedButton으로 변경
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: OutlinedButton(
                    onPressed: () => _showLogoutDialog(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('로그아웃',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ✨ 새로운 카드 UI를 만드는 재사용 위젯
  Widget _buildSettingsCard({
    required String title,
    required String description,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 8,
            )
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 상단 노란색 헤더
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                color: Color(0xFFFFF4B6),
                borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.arrow_forward_ios,
                      size: 16, color: Colors.grey),
                ],
              ),
            ),
            // 하단 흰색 설명 영역
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                description,
                style: TextStyle(color: Colors.grey.shade700, height: 1.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 로그아웃 다이얼로그
  void _showLogoutDialog(BuildContext context) {
    showCupertinoDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return CupertinoAlertDialog(
          title: const Text('로그아웃'),
          content: const Text('정말 로그아웃하시겠습니까?'),
          actions: [
            CupertinoDialogAction(
              child: const Text('취소'),
              onPressed: () => Navigator.of(dialogContext).pop(),
            ),
            CupertinoDialogAction(
              isDestructiveAction: true,
              child: const Text('로그아웃'),
              onPressed: () async {
                Navigator.of(dialogContext).pop(); // 다이얼로그 닫기

                // AuthProvider를 통해 로그아웃
                final authProvider = Provider.of<AuthProvider>(context, listen: false);
                await authProvider.signOut();

                // 로그인 화면으로 이동 (모든 스택 제거)
                if (context.mounted) {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const StartScreen()),
                    (route) => false, // 모든 이전 화면 제거
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  // 문의하기 다이얼로그
  void _showInquiryDialog(BuildContext context) {
    final TextEditingController titleController = TextEditingController();
    final TextEditingController contentController = TextEditingController();
    final FirestoreService firestoreService = FirestoreService();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('문의하기'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: '제목',
                    hintText: '문의 제목을 입력하세요',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: contentController,
                  decoration: const InputDecoration(
                    labelText: '내용',
                    hintText: '문의 내용을 입력하세요',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 5,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              child: const Text('취소'),
              onPressed: () {
                titleController.dispose();
                contentController.dispose();
                Navigator.of(dialogContext).pop();
              },
            ),
            ElevatedButton(
              child: const Text('전송'),
              onPressed: () async {
                final title = titleController.text.trim();
                final content = contentController.text.trim();

                if (title.isEmpty || content.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('제목과 내용을 모두 입력해주세요')),
                  );
                  return;
                }

                try {
                  // 현재 사용자 ID 가져오기
                  final authProvider = Provider.of<AuthProvider>(context, listen: false);
                  final userId = authProvider.userId ?? 'unknown';

                  // 문의 모델 생성
                  final inquiry = InquiryModel(
                    id: DateTime.now().toIso8601String(),
                    title: title,
                    content: content,
                    userId: userId,
                    createdAt: DateTime.now(),
                  );

                  // Firestore에 저장
                  await firestoreService.createInquiry(inquiry);

                  titleController.dispose();
                  contentController.dispose();

                  if (dialogContext.mounted) {
                    Navigator.of(dialogContext).pop();
                  }

                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('문의가 성공적으로 전송되었습니다')),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('문의 전송 실패: $e')),
                    );
                  }
                }
              },
            ),
          ],
        );
      },
    );
  }
}
