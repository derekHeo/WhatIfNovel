// claude_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';

class ClaudeService {
  /// <think> 태그 내용을 제거하고 실제 스토리 내용만 추출
  static String _removeThinkTags(String text) {
    // </think> 태그의 위치를 찾음
    final thinkEndIndex = text.indexOf('</think>');

    if (thinkEndIndex != -1) {
      // </think> 태그 이후의 내용만 추출
      final cleanedText = text.substring(thinkEndIndex + '</think>'.length).trim();
      print('Think 태그 제거 완료. 원본 길이: ${text.length}, 정제 후 길이: ${cleanedText.length}');
      return cleanedText;
    }

    // think 태그가 없으면 전체 반환 (하위 호환성)
    print('Think 태그 없음. 전체 내용 반환');
    return text;
  }

  static Future<String> generateNovel(String finalPrompt) async {
    try {
      print('Cloud Functions HTTP 요청 시작...');

      final url = Uri.parse(
        'https://asia-northeast3-whatif-project.cloudfunctions.net/generateNovelHttp',
      );

      print('HTTP POST 요청 전송 중...');

      // UTF-8 인코딩 명시
      final response = await http
          .post(
        url,
        headers: {
          'Content-Type': 'application/json; charset=utf-8',
          'Accept': 'application/json; charset=utf-8',
        },
        body: utf8.encode(jsonEncode({
          'prompt': finalPrompt,
        })),
      )
          .timeout(
        const Duration(seconds: 90),
        onTimeout: () {
          throw Exception('요청 시간이 초과되었습니다.');
        },
      );

      print('HTTP 응답 상태 코드: ${response.statusCode}');

      if (response.statusCode != 200) {
        // UTF-8로 디코딩
        final errorBody = utf8.decode(response.bodyBytes);
        final errorData = jsonDecode(errorBody);
        throw Exception('서버 오류: ${errorData['error'] ?? '알 수 없는 오류'}');
      }

      // UTF-8로 명시적 디코딩
      final decodedBody = utf8.decode(response.bodyBytes);
      print(
          '디코딩된 응답 미리보기: ${decodedBody.substring(0, decodedBody.length > 200 ? 200 : decodedBody.length)}');

      final responseData = jsonDecode(decodedBody) as Map<String, dynamic>;
      final result = responseData['result'];

      if (result == null || result.toString().isEmpty) {
        throw Exception('서버로부터 유효한 응답을 받지 못했습니다.');
      }

      // <think> 태그 제거 후 반환
      final cleanedResult = _removeThinkTags(result.toString());

      if (cleanedResult.isEmpty) {
        throw Exception('Think 태그 제거 후 내용이 비어있습니다.');
      }

      print('최종 반환 문자열 길이: ${cleanedResult.length}');
      return cleanedResult;
    } catch (e) {
      print('HTTP 요청 중 오류 발생: $e');
      print('오류 타입: ${e.runtimeType}');
      if (e is Exception) {
        rethrow;
      }
      throw Exception('시나리오 생성에 실패했습니다: $e');
    }
  }
}
