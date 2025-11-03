import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class AuthProvider with ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? _user;
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  User? get user => _user;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isLoggedIn => _user != null;
  String? get userId => _user?.uid;
  String? get userEmail => _user?.email;
  String? get userName => _user?.displayName;
  String? get userPhotoUrl => _user?.photoURL;

  AuthProvider() {
    // 앱 시작 시 현재 사용자 상태 확인
    _auth.authStateChanges().listen((User? user) {
      _user = user;
      notifyListeners();
    });
  }

  /// 구글 로그인
  Future<bool> signInWithGoogle() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Google 로그인 플로우 시작
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        // 사용자가 로그인을 취소함
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Google 인증 정보 가져오기
      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      // Firebase 인증 자격증명 생성
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Firebase에 로그인
      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      _user = userCredential.user;
      _isLoading = false;
      notifyListeners();

      debugPrint('구글 로그인 성공: ${_user?.email}');
      return true;
    } catch (e) {
      _errorMessage = '로그인 실패: $e';
      _isLoading = false;
      notifyListeners();
      debugPrint(_errorMessage);
      return false;
    }
  }

  /// 로그아웃
  Future<void> signOut() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _googleSignIn.signOut();
      await _auth.signOut();
      _user = null;
      _errorMessage = null;
      debugPrint('로그아웃 성공');
    } catch (e) {
      _errorMessage = '로그아웃 실패: $e';
      debugPrint(_errorMessage);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 현재 사용자 정보 새로고침
  Future<void> refreshUser() async {
    try {
      await _user?.reload();
      _user = _auth.currentUser;
      notifyListeners();
    } catch (e) {
      debugPrint('사용자 정보 새로고침 실패: $e');
    }
  }

  /// 에러 메시지 초기화
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
