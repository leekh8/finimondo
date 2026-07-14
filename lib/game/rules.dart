import '../models/card.dart';

/// 게임 규칙(순수 함수 — UI/상태와 분리해 테스트 가능하게 유지).
class Rules {
  /// 지금 이 카드를 낼 수 있는가?
  ///
  /// [currentColor]는 와일드로 지정된 색을 포함한 '현재 유효 색'.
  /// [pendingDraw]가 0보다 크면 드로우 중첩 대기 상태 — 드로우 카드로만 받아칠 수 있다.
  static bool canPlay(
    UnoCard card,
    UnoCard topCard,
    CardColor currentColor, {
    int pendingDraw = 0,
  }) {
    // 드로우 중첩 대기 중: 같은 종류의 드로우 카드로만 넘길 수 있다.
    if (pendingDraw > 0) {
      return card.isDrawCard && card.type == topCard.type;
    }

    // 와일드 계열은 언제나 낼 수 있다.
    if (card.isWild) return true;

    // 같은 색.
    if (card.color == currentColor) return true;

    // 액션 카드(숫자 아님)는 같은 타입끼리 매치(스킵↔스킵 등).
    // 숫자를 여기서 걸러내지 않으면 '둘 다 숫자'라는 이유로 아무 숫자나 낼 수 있게 된다.
    if (card.type != CardType.number && card.type == topCard.type) return true;

    // 숫자 카드는 값이 같을 때만 매치.
    if (card.type == CardType.number &&
        topCard.type == CardType.number &&
        card.value == topCard.value) {
      return true;
    }

    return false;
  }

  /// 손패에서 낼 수 있는 카드가 하나라도 있는가?
  static bool hasPlayable(
    List<UnoCard> hand,
    UnoCard topCard,
    CardColor currentColor, {
    int pendingDraw = 0,
  }) {
    return hand.any((c) =>
        canPlay(c, topCard, currentColor, pendingDraw: pendingDraw));
  }

  /// 카드를 냈을 때 다음 차례로 몇 칸 이동하는지.
  /// 스킵은 한 명 건너뛴다. 2인 게임에서는 리버스도 스킵처럼 동작한다(표준 규칙).
  static int turnStep(UnoCard card, int playerCount) {
    if (card.type == CardType.skip) return 2;
    if (card.type == CardType.reverse && playerCount == 2) return 2;
    return 1;
  }

  /// 방향이 뒤집히는가?
  static bool flipsDirection(UnoCard card) => card.type == CardType.reverse;

  /// 색 선택이 필요한가?
  static bool needsColorChoice(UnoCard card) => card.isWild;
}
