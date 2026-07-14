# uno_flutter — UNO 카드게임 (Flutter)

> 오프라인 싱글플레이 UNO. 사람 1명 + AI 3명이 한 기기에서 즉시 플레이한다. 서버·계정 불필요.

## Why

[uno-deathmatch](https://github.com/leekh8/uno-deathmatch)(Node + React 웹, UNO No Mercy 룰)의 게임 규칙을 **모바일 네이티브 앱**으로 옮긴 프로젝트. 웹 버전은 서버(방 생성·소켓)가 필요하지만, 이 앱은 **로컬 AI 대전**이라 설치 즉시 오프라인으로 돌아간다.

규칙 엔진은 UI와 분리된 순수 함수(`lib/game/rules.dart`)로 두어 단위 테스트로 검증한다.

## Status

🟢 플레이 가능 (2026-07-14) — 코어 UNO 룰 + AI 3인 + 색 선택 + 드로우 중첩. `flutter test` 14개 통과, `flutter analyze` 0 issues.

## Features

- **코어 UNO 룰** — 색/숫자 매치, 스킵, 리버스, +2, 와일드, 와일드+4
- **드로우 중첩(스택)** — `+2`에 `+2`로 받아치기(같은 종류만). 누적 장수를 화면 상단에 표시
- **AI 3인** — 공격 카드(드로우·스킵·리버스) 우선, 와일드는 아껴 두는 휴리스틱. 색 선택은 손패에 가장 많은 색
- **낼 수 있는 카드 하이라이트** — 낼 수 없는 카드는 흐리게 표시해 오터치 방지
- **덱 재활용** — 뽑을 카드가 떨어지면 버린 더미(맨 위 제외)를 섞어 다시 사용
- **2인 리버스 = 스킵** (표준 UNO 규칙)

미구현(후속): UNO No Mercy 특수 카드(+6/+10, 색 룰렛, 손패 교환/회전), 온라인 멀티플레이, 점수 누적.

## Stack

- **Flutter / Dart** — 상태관리는 `ChangeNotifier`(외부 상태 라이브러리 없음)
- 외부 의존성 0 — 규칙·덱·AI 전부 순수 Dart
- 플랫폼: Android, Web

## Structure

```
lib/
├── main.dart                # 앱 진입점
├── models/
│   ├── card.dart            # UnoCard (색·타입·값, 불변)
│   └── deck.dart            # 표준 108장 구성·셔플·드로우·재활용
├── game/
│   ├── rules.dart           # 규칙 순수 함수 (canPlay / turnStep / ...)
│   └── game_state.dart      # 진행 엔진 (턴·방향·드로우 중첩·AI)
├── screens/
│   └── game_screen.dart     # 게임 화면 (테이블·손패·색 선택)
└── widgets/
    └── card_view.dart       # 카드 한 장 렌더링
test/
├── rules_test.dart          # 규칙·덱 단위 테스트 13개
└── widget_test.dart         # 화면 스모크 1개
```

## Run

```bash
flutter pub get
flutter run              # 연결된 기기/에뮬레이터
flutter run -d chrome    # 웹으로 바로 확인

flutter test             # 규칙 테스트
flutter analyze
```

## 규칙 메모 — 숫자 카드 매치

숫자 카드는 **값이 같을 때만** 매치된다. "둘 다 숫자면 낼 수 있다"로 구현하면 아무 숫자나 낼 수 있게 되어 게임이 성립하지 않는다(원본 웹 버전에서 실제로 났던 버그). `rules_test.dart`에 회귀 방지 테스트가 있다.

```dart
// 액션 카드는 같은 타입끼리 매치되지만, 숫자는 여기서 제외해야 한다
if (card.type != CardType.number && card.type == topCard.type) return true;
// 숫자는 값이 같을 때만
if (card.type == CardType.number && topCard.type == CardType.number
    && card.value == topCard.value) return true;
```

## License

MIT
