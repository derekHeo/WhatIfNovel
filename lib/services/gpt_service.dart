import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GptService {
  // 💡 함수 이름을 더 명확하게 변경하고, 인자는 최종 프롬프트 하나만 받도록 수정
  static Future<String> generateNovel(String finalPrompt) async {
    final apiKey = dotenv.env['API_KEY'];
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    // 💡 --- 여기서부터가 핵심입니다 --- 💡
    // GptService에서는 더 이상 프롬프트를 만들지 않습니다.
    // 대신, 외부에서 만들어진 완벽한 프롬프트를 그대로 사용합니다.

    // AI의 역할을 정의하는 시스템 메시지
    const systemMessage = """
    당신은 평행우주의 두 가지 하루를 기록하는 반사실적 스토리텔러다. 조건 * 작은 선택 하나가 성공과 실패를 가르는 극적인 차이를 보여줄 것.
    """;

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      },
      body: jsonEncode({
        "model": "gpt-4o-mini",
        "messages": [
          {"role": "system", "content": systemMessage},
          // 💡 user의 content로 전달받은 finalPrompt를 그대로 사용
          {"role": "user", "content": finalPrompt},
        ],
        "max_tokens": 2000,
        "temperature": 0.6,
      }),
    );

    if (response.statusCode == 200) {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      return decoded['choices'][0]['message']['content'].toString();
    } else {
      throw Exception('GPT API 호출 실패: ${response.body}');
    }
  }
}
