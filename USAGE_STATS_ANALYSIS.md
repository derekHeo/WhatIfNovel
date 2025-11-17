# UsageStats 패키지 분석 및 현재 구현 상태

## 📦 패키지 정보
- **패키지명**: `usage_stats`
- **버전**: `1.3.0`
- **용도**: Android 앱 사용 통계 수집
- **플랫폼**: Android 전용 (iOS 미지원)

---

## 🔍 UsageStats 패키지 주요 API

### 1. 권한 관련 메서드

#### `UsageStats.checkUsagePermission()`
```dart
Future<bool?> checkUsagePermission()
```
- **기능**: 앱 사용 통계 권한이 허용되어 있는지 확인
- **반환값**: `true` (권한 있음), `false` (권한 없음), `null` (확인 불가)
- **사용 위치**: `AndroidUsageService.checkUsagePermission()` (android_usage_service.dart:17)

#### `UsageStats.grantUsagePermission()`
```dart
Future<void> grantUsagePermission()
```
- **기능**: 시스템 설정 화면으로 이동하여 권한 요청
- **동작**: 사용자를 "특별한 앱 액세스 > 사용 접근 권한" 설정 화면으로 이동
- **사용 위치**: `AndroidUsageService.requestUsagePermission()` (android_usage_service.dart:32)

---

### 2. 사용 통계 조회 메서드

#### `UsageStats.queryUsageStats(DateTime startDate, DateTime endDate)`
```dart
Future<List<UsageInfo>> queryUsageStats(DateTime startDate, DateTime endDate)
```
- **기능**: 특정 시간 범위의 앱 사용 통계 조회
- **매개변수**:
  - `startDate`: 조회 시작 시간
  - `endDate`: 조회 종료 시간
- **반환값**: `List<UsageInfo>` - 앱별 사용 정보 리스트
- **중요 버그**: ⚠️ 범위를 무시하고 더 넓은 기간의 누적값을 반환하는 버그 존재
  - 예: 오늘 00:00 ~ 12:00을 요청해도, 실제로는 "앱 설치 이후 ~ 12:00"의 누적 값을 반환할 수 있음
  - 해결 방법: 차이 계산 방식 사용 (android_usage_service.dart:202-277)

---

### 3. UsageInfo 객체 구조

`queryUsageStats()`가 반환하는 `UsageInfo` 객체의 주요 속성:

```dart
class UsageInfo {
  String? packageName;              // 앱 패키지명 (예: "com.instagram.android")
  dynamic totalTimeInForeground;    // 포그라운드 사용 시간 (밀리초, String 타입일 수 있음!)
  dynamic lastTimeUsed;             // 마지막 사용 시간 (Unix 타임스탬프, 밀리초)
}
```

#### 주의사항
- `totalTimeInForeground`와 `lastTimeUsed`는 **dynamic 타입**입니다
- 대부분 String으로 반환되므로 `int.tryParse()`로 변환 필요
- 예: `int.tryParse(usage.totalTimeInForeground?.toString() ?? '0') ?? 0`

---

## 📊 현재 프로젝트 구현 상태

### 파일 구조

```
lib/
├── services/
│   └── android_usage_service.dart     # UsageStats API 래퍼 서비스
├── providers/
│   ├── app_goal_provider.dart         # 앱 목표 및 사용량 관리
│   └── usage_stats_provider.dart      # 사용량 통계 제공
└── pages/
    └── home_screen.dart                # 홈 화면 (사용량 표시)
```

---

### AndroidUsageService 메서드 목록

#### 1. `getTotalUsageForDate(DateTime date)`
- **기능**: 특정 날짜의 총 사용 시간 조회 (모든 앱 합산)
- **반환**: `int` (분 단위)
- **로직**:
  - 오늘이면 현재 시간까지, 과거 날짜면 23:59:59까지 조회
  - 모든 앱의 `totalTimeInForeground` 합산

#### 2. `getTodayUsedApps({int minUsageMinutes = 1})`
- **기능**: 오늘 사용한 앱 리스트 조회 (사용 시간 순 정렬)
- **반환**: `List<AppUsageInfo>`
- **매개변수**: `minUsageMinutes` - 최소 사용 시간 (기본 1분)

#### 3. `getAppUsageTimeToday(String packageName)`
- **기능**: 특정 앱의 오늘 사용 시간 조회
- **반환**: `int` (분 단위)

#### 4. `getMultipleAppsUsageTime(List<String> packageNames)`
- **기능**: 여러 앱의 오늘 사용 시간 일괄 조회
- **반환**: `Map<String, int>` (패키지명 -> 사용시간(분))

#### 5. `getAccurateUsageTime({required DateTime startTime, required DateTime endTime, required List<String> packageNames})`
- **기능**: ⚠️ **정확한 시간 범위**의 사용 시간 계산 (차이 계산 방식)
- **반환**: `Map<String, int>` (패키지명 -> 사용시간(분))
- **로직**:
  1. `startTime - 1초`까지의 누적 사용량 조회 (베이스라인)
  2. `endTime`까지의 누적 사용량 조회 (현재값)
  3. 차이 계산: `현재값 - 베이스라인 = 범위 내 사용량`
- **중요**: UsageStats 버그를 우회하는 유일한 정확한 방법

---

## 🎯 어제/오늘 데이터 처리 로직

### AppGoalProvider의 데이터 구조

각 `AppGoal` 객체는 다음 필드를 가짐:
```dart
class AppGoal {
  // 목표 시간
  int goalHours;
  int goalMinutes;

  // 오늘 사용량 (내부 추적용, UI에 표시 안 함)
  double usageHours;
  int usageMinutes;

  // 어제 사용량 (UI에 표시됨)
  double yesterdayUsageHours;
  int yesterdayUsageMinutes;
}
```

---

### syncAllUsageData() 동작 방식 (app_goal_provider.dart:216-370)

#### 핵심 로직
1. **날짜 변경 감지** (251-274번째 줄)
   - `lastSyncDate`와 오늘 날짜 비교
   - 날짜가 바뀌었으면: **오늘 데이터 → 어제로 이동**
   ```dart
   goal.yesterdayUsageHours = goal.usageHours;
   goal.yesterdayUsageMinutes = goal.usageMinutes;
   ```

2. **오늘 사용량 수집** (276-307번째 줄)
   - 항상 00:00부터 현재까지 수집
   - **내부 추적용**으로 `usageHours`, `usageMinutes`에 저장
   - UI에는 표시되지 않음

3. **어제 사용량 조회** (309-354번째 줄)
   - **조건**: 날짜 변경이 없고 + 어제 데이터가 0일 때만 조회
   - 어제 00:00 ~ 23:59:59 범위로 조회
   - `yesterdayUsageHours`, `yesterdayUsageMinutes`에 저장

#### ⚠️ 잠재적 문제점

**문제 1: 최초 실행 시 어제 데이터 조회 조건**
```dart
final needYesterdayData = !dateChanged &&
                         _goals.any((g) => g.yesterdayUsageHours == 0 && g.yesterdayUsageMinutes == 0);
```
- 모든 앱의 어제 데이터가 0이어야 조회
- 만약 일부 앱만 0이면 조회하지 않음

**문제 2: 날짜 변경 직후**
- 날짜가 바뀌면 오늘 데이터를 어제로 이동
- 그런데 오늘 데이터가 아직 수집되지 않았다면 어제 데이터도 0이 됨
- 이 경우 실제 어제 사용량이 아니라 빈 데이터가 어제로 이동

**문제 3: UsageStats의 범위 버그**
- `queryUsageStats(어제 00:00, 어제 23:59:59)`를 호출해도
- 실제로는 더 넓은 범위의 누적값을 반환할 수 있음
- 하지만 현재는 차이 계산 방식(`getAccurateUsageTime`)을 사용하지 않음

---

### UI 표시 로직 (home_screen.dart)

#### _buildGoalVsUsageBar (240-323번째 줄)
```dart
// 실제 사용 시간 (분, 어제 데이터)
final usageMinutes = (goal.yesterdayUsageHours * 60).toInt() + goal.yesterdayUsageMinutes;
```
- ✅ **올바르게 어제 데이터를 사용**
- 목표 대비 퍼센트 계산
- 초과 시 빨간색, 미달 시 파란색 표시

#### What If 생성 시 (574-578번째 줄)
```dart
// ✨ 어제 실제 사용시간 데이터 (분 단위로 변환)
final Map<String, int> appUsage = {
  for (var goal in goals)
    goal.name: (goal.yesterdayUsageHours * 60).toInt() + goal.yesterdayUsageMinutes
};
```
- ✅ **올바르게 어제 데이터를 전송**

---

## 🐛 발견된 문제 및 원인 분석

### 현상
> "화면에 표시되는 값이 어제의 스마트폰 사용량이어야 하는데, 실제로는 현재 사용량이 들어가는 것 같다"

### 분석 결과

#### ✅ UI는 올바르게 구현됨
- `home_screen.dart`는 `yesterdayUsageHours`, `yesterdayUsageMinutes`를 표시
- 코드 자체는 문제 없음

#### ⚠️ 잠재적 원인

**1. 날짜 변경 로직 타이밍 문제**
- `syncAllUsageData()`가 자정(00:00) 직후에 호출되지 않으면:
  - 오늘 데이터가 계속 누적
  - 어제 데이터로 이동하지 않음
- 현재 호출 시점: `home_screen.dart:47` (앱 실행 시)
- 해결: 자정 타이머 또는 앱 실행 시마다 날짜 체크

**2. 최초 실행 시 어제 데이터가 비어있음**
- 앱 설치 후 첫 실행 시 어제 데이터가 0
- 이 경우 UsageStats로 어제 조회 시도
- 하지만 UsageStats 버그로 부정확한 값 반환 가능

**3. Firestore 동기화 문제**
- `yesterdayUsageHours`, `yesterdayUsageMinutes`가 Firestore에 저장됨
- 저장 전에 앱 종료 시 데이터 유실 가능
- 또는 다른 기기/로그아웃 시 초기화

**4. UsageStats API의 범위 버그**
- 어제 데이터 조회 시 부정확한 누적값 반환
- `getAccurateUsageTime()` 메서드가 구현되어 있지만 사용하지 않음

---

## 💡 권장 해결 방안

### 1. 날짜 변경 감지 개선
```dart
// 앱 실행 시마다 날짜 체크
// 백그라운드에서 포그라운드로 돌아올 때도 체크
@override
void didChangeAppLifecycleState(AppLifecycleState state) {
  if (state == AppLifecycleState.resumed) {
    appGoalProvider.syncAllUsageData(); // 날짜 변경 감지
  }
}
```

### 2. 정확한 어제 사용량 조회
현재 `queryUsageStats(어제 00:00, 어제 23:59:59)` 방식 대신:
```dart
// getAccurateUsageTime 사용
final yesterdayUsage = await usageService.getAccurateUsageTime(
  startTime: DateTime(yesterday.year, yesterday.month, yesterday.day, 0, 0, 0),
  endTime: DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59, 59),
  packageNames: packageNames,
);
```

### 3. 로깅 강화
현재 `print()` 사용 중이지만, 더 상세한 로그 추가:
```dart
print('📅 날짜 변경 감지: lastSyncDate=${_lastSyncDate}, today=${today}');
print('📊 어제 데이터: ${goal.name}=${goal.yesterdayUsageHours}h${goal.yesterdayUsageMinutes}m');
print('📊 오늘 데이터: ${goal.name}=${goal.usageHours}h${goal.usageMinutes}m');
```

### 4. 자정 타이머 추가
```dart
// 자정에 자동으로 날짜 변경 처리
void _scheduleNightlySync() {
  final now = DateTime.now();
  final tomorrow = DateTime(now.year, now.month, now.day + 1, 0, 0, 1);
  final duration = tomorrow.difference(now);

  Timer(duration, () {
    syncAllUsageData(); // 자정 1초 후 동기화
    _scheduleNightlySync(); // 다음 날을 위해 재스케줄
  });
}
```

---

## 📋 UsageStats API 제한사항

1. **Android 전용**: iOS에서는 작동하지 않음
2. **권한 필요**: 사용자가 수동으로 설정에서 권한 허용 필요
3. **범위 버그**: `queryUsageStats`의 시간 범위가 정확하지 않음
4. **타입 불안정**: `totalTimeInForeground`가 dynamic/String 타입
5. **포그라운드만**: 백그라운드 사용 시간은 포함 안 됨
6. **시스템 제약**: Android 5.0 (API 21) 이상 필요

---

## 🔗 참고 정보

### 패키지명 매핑 (android_usage_service.dart:336-351)
```dart
final commonApps = {
  'com.instagram.android': 'Instagram',
  'com.google.android.youtube': 'YouTube',
  'com.kakao.talk': 'KakaoTalk',
  'com.facebook.katana': 'Facebook',
  'com.twitter.android': 'Twitter',
  // ... 등등
};
```

### 시간 단위 변환
- **밀리초 → 분**: `totalTimeMs ~/ 1000 ~/ 60`
- **분 → 시간+분**: `hours = minutes ~/ 60`, `mins = minutes % 60`

---

## 🎯 결론

### 현재 상태
- ✅ UI는 어제 데이터를 올바르게 사용
- ⚠️ 날짜 변경 로직이 타이밍에 민감
- ⚠️ UsageStats API의 범위 버그로 부정확할 수 있음
- ⚠️ 최초 실행 시 어제 데이터가 비어있을 수 있음

### 추천 조치
1. **로깅 추가**: 어제/오늘 데이터가 실제로 무엇인지 확인
2. **정확한 조회**: `getAccurateUsageTime()` 메서드 활용
3. **자정 타이머**: 날짜 변경 자동 처리
4. **앱 라이프사이클**: 포그라운드 복귀 시 날짜 체크

---

**작성일**: 2025-01-18
**분석 파일**:
- `lib/services/android_usage_service.dart`
- `lib/providers/app_goal_provider.dart`
- `lib/providers/usage_stats_provider.dart`
- `lib/pages/home_screen.dart`
