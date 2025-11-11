# What If - AI 기반 반사실적 스토리텔링 앱

[![Flutter](https://img.shields.io/badge/Flutter-3.3.4+-02569B?logo=flutter)](https://flutter.dev)
[![Firebase](https://img.shields.io/badge/Firebase-Enabled-FFCA28?logo=firebase)](https://firebase.google.com)

## 프로젝트 개요

**What If**는 사용자의 일상 목표 달성률을 분석해, AI가 **"성공한 하루"**와 **"실패한 하루"** 두 가지 평행 세계의 이야기를 생성하는 동기 부여 애플리케이션입니다.

## 프로토타입 서비스 경험해보기
https://whatif-project.web.app/

1. 로그인
2. 프로필입력
3. 사용 앱/사용시간 작성
4. What If 버튼 클릭

### 핵심 아이디어

반사실적 사고(Counterfactual Thinking)를 활용하여:
- "만약 오늘 목표를 달성했다면?" → 압도적으로 긍정적인 미래 시나리오
- "만약 목표를 지키지 못했다면?" → 삶이 비극적으로 붕괴된 미래 시나리오

작은 선택의 차이가 미래에 미칠 극적인 영향을 **Claude AI가 생성한 1000자 이상의 웹소설 형식**으로 경험하게 합니다.

---

## 주요 기능

### 1. 일상 관리
- **앱 사용 시간 관리**: 인스타그램, 유튜브, 카카오톡 등 목표 설정 및 추적
- **Todo 리스트**: 할 일 작성 및 완료율 자동 계산
- **사용자 프로필**: 단기/장기 목표, 요즘 하는 일, 성격 스타일 설정

### 2. AI 시나리오 생성 ⭐
- 사용자의 목표, 성격, 오늘의 달성률을 분석
- **Claude AI**가 개인 맞춤형 두 가지 평행 세계 스토리 생성
- 1인칭 시점, 완료형 서술로 현실감 극대화
- Firebase Firestore에 자동 저장

### 3. 기록 보기
- 이전에 생성된 시나리오 열람
- 날짜별 목표 달성률 확인

---

## 기술 스택

| 분야 | 기술 |
|------|------|
| **Frontend** | Flutter 3.3.4, Dart, Provider (상태 관리) |
| **Backend** | Firebase (Firestore, Auth, Functions) |
| **AI** | Claude AI (Anthropic) |
| **UI** | Cupertino (iOS 스타일), Material Design, fl_chart |

---

## 사용 흐름

```
1. 프로필 설정 (이름, 목표, 성격 등)
   ↓
2. 앱별 사용 시간 목표 설정 (예: 인스타 1시간, 유튜브 30분)
   ↓
3. 오늘의 실제 사용 시간 입력 + Todo 체크
   ↓
4. "What if ?!" 버튼 클릭
   ↓
5. AI가 두 가지 시나리오 생성 (10~30초 소요)
   ↓
6. 성공/실패 평행 세계 스토리 읽기
```

---

## 차별화 포인트

| 기존 습관 관리 앱 | What If |
|------------------|---------|
| 단순 통계 제공 | AI 스토리텔링으로 감정적 몰입 |
| "조금만 더 노력하세요" | "삶이 붕괴될 수 있다"는 강력한 경각심 |
| 일반적인 조언 | 개인 맞춤형 시나리오 (목표, 성격 반영) |
| 통계 차트 | 1000자 이상의 생생한 웹소설 |

---

## 주요 파일 설명

```
lib/
├── main.dart                          # 앱 진입점, Firebase 초기화
├── pages/home_screen.dart             # 메인 화면, "What if ?!" 버튼
├── providers/diary_provider.dart      # AI 시나리오 생성 핵심 로직
├── services/claude_service.dart       # Claude AI API 통신
└── services/firestore_service.dart    # Firebase 데이터 저장/로드
```

---

## 빠른 시작

### 사전 요구사항
- Flutter SDK 3.3.4+
- Firebase 프로젝트
- Claude API 키

### 실행
```bash
# 의존성 설치
flutter pub get

# .env 파일 생성 (루트)
echo "API_KEY=your_claude_api_key" > .env

# Firebase 설정
flutterfire configure

# 실행
flutter run
```

---

## AI 프롬프트 핵심

사용자 데이터를 기반으로 다음과 같은 프롬프트를 생성합니다:

```
당신은 평행우주의 두 가지 하루를 기록하는 반사실적 스토리텔러다.

[입력]
- 장기/단기 목표
- 오늘의 할 일 (완료/미완료)
- 앱 사용 목표 vs 실제 사용 시간
- 사용자 성격 스타일

[출력]
- 성공한 하루: 500~700자, 압도적으로 긍정적인 미래
- 실패한 하루: 500~700자, 삶이 비극적으로 붕괴된 미래
- 1인칭 완료형, 소제목 구분, 교훈 없이 이야기로만 전달
```

코드: `lib/providers/diary_provider.dart:250`

---

## 스크린샷 예시

- **홈 화면**: 앱 사용 시간 입력, 성공률 프로그레스 바, Todo 리스트
- **시나리오 화면**: 성공/실패 두 가지 이야기 분리 표시
- **기록 목록**: 과거 생성된 시나리오 타임라인

---

## 향후 계획

- [ ] 실제 스크린 타임 API 연동 (자동 추적)
- [ ] 소셜 기능 (시나리오 공유)
- [ ] GPT-4, Gemini 등 다양한 AI 모델 지원
- [ ] 주간/월간 통계 대시보드

---

**What If - 오늘의 선택이 만드는 두 개의 미래**
