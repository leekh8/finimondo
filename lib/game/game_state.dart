import 'dart:math';

import 'package:flutter/foundation.dart';

import '../models/card.dart';
import '../models/deck.dart';
import 'rules.dart';

/// 플레이어 한 명(사람 또는 AI).
class Player {
  final String name;
  final bool isHuman;
  final List<UnoCard> hand = [];

  Player(this.name, {this.isHuman = false});
}

/// 게임 진행 엔진. UI는 이 상태를 구독만 한다(로직은 여기 + Rules에 모은다).
class GameState extends ChangeNotifier {
  static const int initialHandSize = 7;

  final Random _random;
  late Deck _deck;
  final List<Player> players = [];

  int _current = 0;
  int _direction = 1; // 1 정방향, -1 역방향
  int _pendingDraw = 0; // 중첩된 드로우 장수
  late CardColor _currentColor;
  String _message = '';
  Player? _winner;
  bool _awaitingColorChoice = false;

  GameState({Random? random, int aiCount = 3})
      : _random = random ?? Random() {
    players.add(Player('나', isHuman: true));
    for (var i = 1; i <= aiCount; i++) {
      players.add(Player('AI $i'));
    }
    _start();
  }

  // ── 조회 ────────────────────────────────────────────────────────────
  Player get currentPlayer => players[_current];
  Player get human => players.first;
  UnoCard get topCard => _deck.topCard!;
  CardColor get currentColor => _currentColor;
  int get pendingDraw => _pendingDraw;
  int get direction => _direction;
  String get message => _message;
  Player? get winner => _winner;
  bool get awaitingColorChoice => _awaitingColorChoice;
  bool get isHumanTurn => currentPlayer.isHuman && _winner == null;
  int get deckRemaining => _deck.remaining;

  bool canPlayCard(UnoCard card) =>
      Rules.canPlay(card, topCard, _currentColor, pendingDraw: _pendingDraw);

  // ── 시작 ────────────────────────────────────────────────────────────
  void _start() {
    _deck = Deck(random: _random);
    for (final p in players) {
      p.hand
        ..clear()
        ..addAll(_deck.drawMany(initialHandSize));
    }
    final first = _deck.flipFirstCard();
    _currentColor = first.color;
    _current = 0;
    _direction = 1;
    _pendingDraw = 0;
    _winner = null;
    _awaitingColorChoice = false;
    _message = '게임 시작! 카드를 내세요.';
  }

  void restart() {
    _start();
    notifyListeners();
  }

  // ── 사람 액션 ────────────────────────────────────────────────────────
  /// 사람이 카드를 낸다. 와일드면 색 선택 대기 상태가 된다.
  void playHuman(UnoCard card) {
    if (!isHumanTurn || _awaitingColorChoice) return;
    if (!canPlayCard(card)) {
      _message = '낼 수 없는 카드입니다.';
      notifyListeners();
      return;
    }
    _playCard(human, card);
    if (_awaitingColorChoice) {
      notifyListeners(); // 색 선택 다이얼로그를 띄우고 대기
      return;
    }
    _afterTurn();
  }

  /// 사람이 와일드 색을 선택한다.
  void chooseColor(CardColor color) {
    if (!_awaitingColorChoice) return;
    _currentColor = color;
    _awaitingColorChoice = false;
    _message = '색을 ${_colorName(color)}(으)로 바꿨습니다.';
    _afterTurn();
  }

  /// 사람이 카드를 뽑는다(중첩 드로우가 있으면 그만큼 받고 턴을 넘긴다).
  void drawHuman() {
    if (!isHumanTurn || _awaitingColorChoice) return;
    _resolveDraw(human);
    _afterTurn();
  }

  // ── 내부 진행 ────────────────────────────────────────────────────────
  void _playCard(Player player, UnoCard card) {
    player.hand.remove(card);
    _deck.discard(card);

    if (card.isDrawCard) {
      _pendingDraw += card.drawCount; // 같은 종류로 중첩 가능
    }
    if (Rules.flipsDirection(card)) {
      _direction = -_direction;
    }
    _advance(Rules.turnStep(card, players.length));

    if (player.hand.isEmpty) {
      _winner = player;
      _message = '${player.name} 승리! 🎉';
      return;
    }
    if (player.hand.length == 1) {
      _message = '${player.name}: UNO!';
    }

    if (Rules.needsColorChoice(card)) {
      if (player.isHuman) {
        _awaitingColorChoice = true; // 사람은 직접 고른다
      } else {
        _currentColor = _aiPickColor(player);
        _message = '${player.name}이(가) 색을 ${_colorName(_currentColor)}(으)로 바꿨습니다.';
      }
    } else {
      _currentColor = card.color;
    }
  }

  /// 중첩된 드로우를 받거나(없으면 1장) 뽑는다. 뽑은 카드가 낼 수 있으면 바로 낼 기회는 주지 않고
  /// 턴을 넘긴다(규칙 단순화 — 대신 UI에서 뽑기 버튼이 명시적이다).
  void _resolveDraw(Player player) {
    final count = _pendingDraw > 0 ? _pendingDraw : 1;
    final drawn = _deck.drawMany(count);
    player.hand.addAll(drawn);
    _message = _pendingDraw > 0
        ? '${player.name}이(가) $count장 받았습니다.'
        : '${player.name}이(가) 카드를 뽑았습니다.';
    _pendingDraw = 0;
    _advance(1);
  }

  void _advance(int step) {
    _current = (_current + _direction * step) % players.length;
    if (_current < 0) _current += players.length;
  }

  /// 턴 종료 후 AI들이 연쇄적으로 진행한다.
  void _afterTurn() {
    notifyListeners();
    if (_winner != null) return;
    _runAiTurns();
  }

  void _runAiTurns() {
    // 사람 차례가 돌아올 때까지 AI들이 순서대로 진행
    while (_winner == null && !currentPlayer.isHuman) {
      final ai = currentPlayer;
      final playable = ai.hand
          .where((c) => canPlayCard(c))
          .toList(growable: false);
      if (playable.isEmpty) {
        _resolveDraw(ai);
      } else {
        _playCard(ai, _aiChoose(playable));
      }
      notifyListeners();
    }
  }

  /// AI 카드 선택: 공격 카드(드로우/스킵/리버스) 우선, 그다음 색 맞춤, 마지막에 와일드 아끼기.
  UnoCard _aiChoose(List<UnoCard> playable) {
    int score(UnoCard c) {
      if (c.type == CardType.wildDrawFour) return 1; // 가장 강하지만 아껴 둔다
      if (c.type == CardType.wild) return 2;
      if (c.isDrawCard) return 5;
      if (c.type == CardType.skip || c.type == CardType.reverse) return 4;
      return 3;
    }

    final sorted = [...playable]..sort((a, b) => score(b).compareTo(score(a)));
    return sorted.first;
  }

  /// AI 색 선택: 손에 가장 많은 색.
  CardColor _aiPickColor(Player ai) {
    final counts = <CardColor, int>{};
    for (final c in ai.hand) {
      if (c.isWild) continue;
      counts[c.color] = (counts[c.color] ?? 0) + 1;
    }
    if (counts.isEmpty) {
      const colors = [
        CardColor.red,
        CardColor.yellow,
        CardColor.green,
        CardColor.blue,
      ];
      return colors[_random.nextInt(colors.length)];
    }
    return counts.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  static String _colorName(CardColor c) {
    switch (c) {
      case CardColor.red:
        return '빨강';
      case CardColor.yellow:
        return '노랑';
      case CardColor.green:
        return '초록';
      case CardColor.blue:
        return '파랑';
      case CardColor.wild:
        return '와일드';
    }
  }
}
