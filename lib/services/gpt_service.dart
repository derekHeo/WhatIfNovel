import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GptService {
  static Future<String> generateNovelFromDiary(String diary,
      {String? userProfileInfo}) async {
    final apiKey = dotenv.env['API_KEY'];
    final url = Uri.parse('https://api.openai.com/v1/chat/completions');

    // 사용자 프로필 정보가 있으면 프롬프트에 포함
    final profileContext = userProfileInfo != null && userProfileInfo.isNotEmpty
        ? '\n\n$userProfileInfo\n'
        : '\n';

    final prompt = '''
      너는 사용자의 일지 : $diary, $profileContext , 프로필 : ${userProfileInfo != null ? ' (위 프로필 정보 활용)' : ''} 을 바탕으로, 사용자의 특성을 반영한 두 편의 개인화된 단편소설을 쓰는 소설가야. 사용자의 나이, 성격, 직업, 관심사 등을 고려해서 더 현실적이고 몰입감 있는 이야기를 만들어줘. 특히 사용자의 현재 활동에 집중해.
      반드시 지켜야 할 규칙
      1. 입력된 정보(일지·프로필)를 활용하여 사용자가 주인공인 소설을 작성한다.→ 사용자의 이름, 직업, 일상 패턴, 관심사를 소설 속에 구체적으로 언급하고 활용한다.
      2. 실제 소설에 쓰이는 문체로 작성하며, 소설의 내용은 현실적인 미래에 대한 내용을 쓸 것.
      3. 500자 정도의 단편소설 2편을 작성한다. (제목의 대소문자를 절대 지킬 것)
        - 제목 1: What you did  — 스마트폰 사용 충동 조절을 못했을 때의 생길 수 있는 부정적인 결과를 사용자의 실제 상황과 연결지어 현실적으로 묘사
        - 제목 2: What If you didn't — 스마트폰을 쓰지 않았을 때의 생길 수 있는 긍정적 결과를 사용자의 실제 상황과 연결지어 현실적으로 묘사
      4. 두 편은 제목+본문 한 단락씩, 사이에 빈 줄 1줄만 넣는다.
      5. 각 소설마다 사용자 프로필에서 최소 3개의 요소(이름/직업/취미/성격 등등)를 자연스럽게 포함시킨다.
    ''';
    // final prompt = '''
    // 일지 내용: $diary $profileContext 혹시 이 일지 내용을 바탕으로 사용자의 나쁜 스마트폰 중독 습관을 고칠 수 있도록 좀 충격을 줄 수 있을 법한 단편 소설을 써줄 수 있어? 주인공은 나였으면 좋겠어${userProfileInfo != null ? ' (위 프로필 정보 활용)' : ''} 소설은 2편이었으면 해 1편은 충격을 줄만한 부정적인 단편 소설. 2편은 만약 내가 핸드폰을 하지 않았더라면 어떻게 됐을까를 나타낸 재밌는 단편 소설. 모든 생성된 소설의 1편의 제목은 What you did로 할것.(대소문자 절대적으로 지킬 것) 모든 생성된 소설의 2편의 제목은 What If you didn't로 할것.(대소문자 절대적으로 지킬 것) 각 편별로 최대 500자까지.
    // ''';
    final systemMessage = userProfileInfo != null
        ? "너는 사용자의 스마트폰 사용 일지와 프로필 정보를 바탕으로, 사용자ß의 특성을 반영한 두 편의 개인화된 단편소설을 쓰는 소설가야. 사용자의 나이, 성격, 직업, 관심사 등을 고려해서 더 현실적이고 몰입감 있는 이야기를 만들어줘. 특히 사용자의 현재 활동에 집중해줘. 결과는 반드시 2편의 단편소설 형태로 제공해."
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
        "max_tokens": 1200,
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
