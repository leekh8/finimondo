import 'dart:math';

import 'card.dart';

/// 표준 UNO 108장 덱 구성/셔플/드로우.
class Deck {
  /// 표준 덱: 색당 0 한 장 + 1~9 두 장 + 스킵/리버스/+2 각 두 장, 와일드·와일드+4 각 4장.
  static List<UnoCard> buildStandardDeck() {
    final cards = <UnoCard>[];
    const colors = [
      CardColor.red,
      CardColor.yellow,
      CardColor.green,
      CardColor.blue,
    ];

    for (final color in colors) {
      cards.add(UnoCard(color, CardType.number, 0));
      for (var n = 1; n <= 9; n++) {
        cards.add(UnoCard(color, CardType.number, n));
        cards.add(UnoCard(color, CardType.number, n));
      }
      for (final type in [CardType.skip, CardType.reverse, CardType.drawTwo]) {
        cards.add(UnoCard(color, type));
        cards.add(UnoCard(color, type));
      }
    }
    for (var i = 0; i < 4; i++) {
      cards.add(const UnoCard(CardColor.wild, CardType.wild));
      cards.add(const UnoCard(CardColor.wild, CardType.wildDrawFour));
    }
    return cards; // 4*(1+18+6) + 8 = 108
  }

  final Random _random;
  final List<UnoCard> _drawPile;
  final List<UnoCard> _discardPile = [];

  Deck({Random? random})
      : _random = random ?? Random(),
        _drawPile = buildStandardDeck() {
    _drawPile.shuffle(_random);
  }

  int get remaining => _drawPile.length;
  List<UnoCard> get discardPile => List.unmodifiable(_discardPile);
  UnoCard? get topCard => _discardPile.isEmpty ? null : _discardPile.last;

  /// 한 장 뽑는다. 덱이 비면 버린 더미(맨 위 제외)를 섞어 재활용한다.
  UnoCard? draw() {
    if (_drawPile.isEmpty) {
      _recycleDiscard();
      if (_drawPile.isEmpty) return null; // 재활용할 카드도 없음
    }
    return _drawPile.removeLast();
  }

  List<UnoCard> drawMany(int count) {
    final drawn = <UnoCard>[];
    for (var i = 0; i < count; i++) {
      final card = draw();
      if (card == null) break;
      drawn.add(card);
    }
    return drawn;
  }

  void discard(UnoCard card) => _discardPile.add(card);

  /// 게임 시작 시 첫 장을 뒤집는다. 와일드가 나오면 덱에 되돌리고 다시 뽑는다
  /// (첫 카드가 색이 없으면 유효 색을 정할 수 없다).
  UnoCard flipFirstCard() {
    while (true) {
      final card = draw();
      if (card == null) {
        throw StateError('덱이 비어 첫 카드를 뒤집을 수 없습니다');
      }
      if (!card.isWild) {
        _discardPile.add(card);
        return card;
      }
      _drawPile.insert(0, card); // 와일드는 맨 아래로 되돌림
    }
  }

  void _recycleDiscard() {
    if (_discardPile.length <= 1) return;
    final top = _discardPile.removeLast();
    _drawPile.addAll(_discardPile);
    _discardPile
      ..clear()
      ..add(top);
    _drawPile.shuffle(_random);
  }
}
