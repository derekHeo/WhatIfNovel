import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'home_screen.dart';

class StartScreen extends StatelessWidget {
  const StartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5E6A3), // 노란색 배경 (이미지와 정확히 매칭)
      body: GestureDetector(
        onTap: () {
          // 화면 아무곳이나 클릭시 홈화면으로 이동
          Navigator.of(context).pushReplacement(
            CupertinoPageRoute(
              builder: (context) => const HomeScreen(),
            ),
          );
        },
        child: Container(
          width: double.infinity,
          height: double.infinity,
          child: const Center(
            child: Text(
              'what if',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.w600,
                color: Color(0xFF007AFF), // iOS 파란색
                fontStyle: FontStyle.italic,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
