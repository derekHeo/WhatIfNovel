import 'dart:convert';
import 'package:http/http.dart' as http;

class GptService {
  static Future<String> generateNovelFromDiary(String diary,
      {String? userProfileInfo}) async {
    final apiKey = ''; // 실제 자신의 OpenAI API 키로 교체
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    // 사용자 프로필 정보가 있으면 프롬프트에 포함
    final profileContext = userProfileInfo != null && userProfileInfo.isNotEmpty
        ? '\n\n$userProfileInfo\n'
        : '\n';

    final prompt = '''
일지 내용: $diary
$profileContext
혹시 이 일지 내용을 바탕으로 사용자의 나쁜 스마트폰 중독 습관을 고칠 수 있도록 좀 충격을 줄 수 있을 법한 단편 소설을 써줄 수 있어?

주인공은 나였으면 좋겠어${userProfileInfo != null ? ' (위 프로필 정보 활용)' : ''}

소설은 2편이었으면 해

1편은 충격을 줄만한 부정적인 단편 소설.
2편은 만약 내가 핸드폰을 하지 않았더라면 어떻게 됐을까를 나타낸 재밌는 단편 소설.

모든 생성된 소설의 1편의 제목은 What you did로 할것.(대소문자 절대적으로 지킬 것)
모든 생성된 소설의 2편의 제목은 What If you didn't로 할것.(대소문자 절대적으로 지킬 것)
각 편별로 최대 300자까지.
''';

    final systemMessage = userProfileInfo != null
        ? "너는 사용자의 스마트폰 사용 일지와 프로필 정보를 바탕으로, 사용자의 특성을 반영한 두 편의 개인화된 단편소설을 쓰는 소설가야. 사용자의 나이, 성격, 직업, 관심사 등을 고려해서 더 현실적이고 몰입감 있는 이야기를 만들어줘. 특히 사용자의 현재 활동에 집중해줘. 결과는 반드시 2편의 단편소설 형태로 제공해."
        : "너는 사용자의 스마트폰 사용 일지를 바탕으로, 두 편의 단편소설을 쓰는 소설가야. 결과는 반드시 2편의 단편소설 형태로 제공해.";

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
          {"role": "user", "content": prompt},
        ],
        "max_tokens": 1000,
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
