import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../models/diary_model.dart';

class TtsProvider extends ChangeNotifier {
  final FlutterTts _flutterTts = FlutterTts();

  // 상태 변수들
  bool _isPlaying = false;
  bool _isPaused = false;
  bool _isLoading = false;
  double _speechRate = 1.0;
  double _pitch = 1.0;
  String? _currentText;
  DiaryModel? _currentDiary;

  // Getters
  bool get isPlaying => _isPlaying;
  bool get isPaused => _isPaused;
  bool get isLoading => _isLoading;
  double get speechRate => _speechRate;
  double get pitch => _pitch;
  bool get isSpeaking => _isPlaying && !_isPaused;

  TtsProvider() {
    _initializeTts();
  }

  /// TTS 초기화
  Future<void> _initializeTts() async {
    try {
      // 한국어 설정
      await _flutterTts.setLanguage("ko-KR");

      // 음성 속도 및 피치 설정
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setPitch(_pitch);

      // 이벤트 리스너 설정
      _flutterTts.setStartHandler(() {
        _isPlaying = true;
        _isPaused = false;
        _isLoading = false;
        notifyListeners();
      });

      _flutterTts.setCompletionHandler(() {
        _isPlaying = false;
        _isPaused = false;
        _isLoading = false;
        notifyListeners();
      });

      _flutterTts.setErrorHandler((msg) {
        debugPrint('TTS 에러: $msg');
        _isPlaying = false;
        _isPaused = false;
        _isLoading = false;
        notifyListeners();
      });

      _flutterTts.setPauseHandler(() {
        _isPaused = true;
        notifyListeners();
      });

      _flutterTts.setContinueHandler(() {
        _isPaused = false;
        notifyListeners();
      });
    } catch (e) {
      debugPrint('TTS 초기화 실패: $e');
    }
  }

  /// 소설 읽기 시작
  Future<void> speakNovel(DiaryModel diary) async {
    try {
      _isLoading = true;
      _currentDiary = diary;
      notifyListeners();

      // 소설 텍스트 구성
      final textToSpeak = _buildNovelText(diary);
      _currentText = textToSpeak;

      await _flutterTts.speak(textToSpeak);
    } catch (e) {
      debugPrint('TTS 재생 실패: $e');
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 소설 텍스트 구성
  String _buildNovelText(DiaryModel diary) {
    final buffer = StringBuffer();

    // 1. 내가 쓴 글 읽기
    buffer.writeln('내가 쓴 글.');
    buffer.writeln(diary.diary);
    buffer.writeln(''); // 잠깐 멈춤을 위한 빈 줄

    // 2. 소설 내용 읽기
    final novelContent = diary.novel;

    // ** 마크다운 제거 및 정리
    String cleanContent = novelContent
        .replaceAll('**', '') // 볼드 마크다운 제거
        .replaceAll('「', '') // 특수 괄호 제거
        .replaceAll('」', '')
        .replaceAll('#', '') // 헤딩 마크다운 제거
        .trim();

    buffer.writeln(cleanContent);

    return buffer.toString();
  }

  /// 재생/일시정지 토글
  Future<void> togglePlayPause() async {
    try {
      if (_isPlaying && !_isPaused) {
        // 재생 중 → 일시정지
        await _flutterTts.pause();
      } else if (_isPaused) {
        // 일시정지 중 → 재생 재개 (iOS에서는 지원 안 될 수 있음)
        // 대신 현재 텍스트를 다시 재생
        if (_currentText != null) {
          await _flutterTts.speak(_currentText!);
        }
      } else if (_currentDiary != null) {
        // 정지 상태 → 재생 시작
        await speakNovel(_currentDiary!);
      }
    } catch (e) {
      debugPrint('TTS 토글 실패: $e');
    }
  }

  /// 정지
  Future<void> stop() async {
    try {
      await _flutterTts.stop();
      _isPlaying = false;
      _isPaused = false;
      _isLoading = false;
      _currentText = null;
      _currentDiary = null;
      notifyListeners();
    } catch (e) {
      debugPrint('TTS 정지 실패: $e');
    }
  }

  /// 음성 속도 조절
  Future<void> setSpeechRate(double rate) async {
    try {
      _speechRate = rate.clamp(0.1, 2.0); // 0.1배 ~ 2.0배 제한
      await _flutterTts.setSpeechRate(_speechRate);
      notifyListeners();
    } catch (e) {
      debugPrint('TTS 속도 설정 실패: $e');
    }
  }

  /// 음성 피치 조절
  Future<void> setPitch(double pitch) async {
    try {
      _pitch = pitch.clamp(0.5, 2.0); // 0.5배 ~ 2.0배 제한
      await _flutterTts.setPitch(_pitch);
      notifyListeners();
    } catch (e) {
      debugPrint('TTS 피치 설정 실패: $e');
    }
  }

  /// 사용 가능한 언어 목록 가져오기
  Future<List<String>> getLanguages() async {
    try {
      final languages = await _flutterTts.getLanguages;
      return List<String>.from(languages);
    } catch (e) {
      debugPrint('언어 목록 가져오기 실패: $e');
      return ['ko-KR']; // 기본값
    }
  }

  /// 언어 설정
  Future<void> setLanguage(String language) async {
    try {
      await _flutterTts.setLanguage(language);
    } catch (e) {
      debugPrint('언어 설정 실패: $e');
    }
  }

  /// 현재 재생 중인 소설이 같은지 확인
  bool isCurrentNovel(DiaryModel diary) {
    if (_currentDiary == null) return false;
    return _currentDiary!.date == diary.date &&
        _currentDiary!.diary == diary.diary;
  }

  @override
  void dispose() {
    _flutterTts.stop();
    super.dispose();
  }
}
