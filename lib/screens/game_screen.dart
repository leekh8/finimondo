import 'dart:math';

import 'package:flutter/material.dart';

import '../game/game_state.dart';
import '../models/card.dart';
import '../widgets/card_view.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  late final GameState _game;
  final Random _rng = Random();

  /// AI 한 수를 딜레이 후 실행하도록 예약해 두면 true(중복 예약 방지).
  bool _aiPending = false;

  /// 지금 "생각 중"인 AI 이름(없으면 null). 상대 아바타에 표시.
  String? _thinkingName;

  @override
  void initState() {
    super.initState();
    _game = GameState();
    _game.addListener(_onGameChanged);
    // 첫 카드가 우연히 AI 차례를 만들지는 않지만(사람이 0번), 방어적으로 한 번 확인.
    WidgetsBinding.instance.addPostFrameCallback((_) => _maybeScheduleAi());
  }

  void _onGameChanged() {
    if (!mounted) return;
    setState(() {});
    if (_game.awaitingColorChoice) {
      _askColor();
      return;
    }
    _maybeScheduleAi();
  }

  /// AI 차례면 0.8~1.5초 뒤 한 수를 두도록 예약한다. stepAi가 notify → 이 콜백을
  /// 다시 부르므로, 사람 차례가 돌아올 때까지 딜레이를 두고 자연스레 이어진다.
  void _maybeScheduleAi() {
    if (_aiPending || !_game.isAiTurn) return;
    _aiPending = true;
    setState(() => _thinkingName = _game.currentPlayer.name);
    final ms = 800 + _rng.nextInt(701); // 0.8s ~ 1.5s "생각 중"
    Future.delayed(Duration(milliseconds: ms), () {
      if (!mounted) return;
      _aiPending = false;
      _thinkingName = null;
      _game.stepAi(); // → notifyListeners → _onGameChanged → 다음 수 예약
    });
  }

  @override
  void dispose() {
    _game.removeListener(_onGameChanged);
    _game.dispose();
    super.dispose();
  }

  Future<void> _askColor() async {
    final color = await showDialog<CardColor>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('색을 선택하세요'),
        content: Wrap(
          spacing: 12,
          children: [
            CardColor.red,
            CardColor.yellow,
            CardColor.green,
            CardColor.blue,
          ]
              .map((c) => GestureDetector(
                    onTap: () => Navigator.pop(context, c),
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: CardView.colorOf(c),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
    if (color != null) {
      _game.chooseColor(color);
    }
  }

  @override
  Widget build(BuildContext context) {
    final human = _game.human;
    return Scaffold(
      backgroundColor: const Color(0xFF1B5E20),
      appBar: AppBar(
        title: const Text('UNO'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: '새 게임',
            onPressed: _game.restart,
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildOpponents(),
            const Spacer(),
            _buildTable(),
            const SizedBox(height: 10),
            _buildLastAction(),
            const Spacer(),
            _buildStatus(),
            _buildHand(human),
          ],
        ),
      ),
    );
  }

  Widget _buildOpponents() {
    final ais = _game.players.where((p) => !p.isHuman).toList();
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: ais.map((p) {
          final isTurn = _game.currentPlayer == p && _game.winner == null;
          final isThinking = _thinkingName == p.name;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            decoration: BoxDecoration(
              color: isTurn ? Colors.amber.withValues(alpha: 0.18) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isTurn ? Colors.amber : Colors.transparent,
                width: 2,
              ),
            ),
            child: Column(
              children: [
                CircleAvatar(
                  backgroundColor: isTurn ? Colors.amber : Colors.white24,
                  child: Text('${p.hand.length}',
                      style: TextStyle(
                          color: isTurn ? Colors.black : Colors.white,
                          fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 4),
                Text(p.name,
                    style: const TextStyle(color: Colors.white70, fontSize: 12)),
                SizedBox(
                  height: 16,
                  child: isThinking
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            SizedBox(
                              width: 10,
                              height: 10,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.amberAccent),
                            ),
                            SizedBox(width: 4),
                            Text('생각 중',
                                style: TextStyle(
                                    color: Colors.amberAccent, fontSize: 10)),
                          ],
                        )
                      : null,
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTable() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // 덱(뽑기)
        Column(
          children: [
            GestureDetector(
              onTap: _game.isHumanTurn ? _game.drawHuman : null,
              child: Container(
                width: 72,
                height: 108,
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                alignment: Alignment.center,
                child: const Text('DRAW',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 4),
            Text('${_game.deckRemaining}장',
                style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
        const SizedBox(width: 32),
        // 버린 더미 맨 위 + 현재 색
        Column(
          children: [
            CardView(card: _game.topCard, width: 72),
            const SizedBox(height: 6),
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: CardView.colorOf(_game.currentColor),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white70),
              ),
            ),
          ],
        ),
      ],
    );
  }

  /// 방금 AI가 무엇을 했는지(낸 카드 / 뽑기 / 와일드 색) 눈에 보이게 표시.
  /// 새 액션마다 페이드+슬라이드로 갈아끼운다. 사람 액션은 손패로 보이므로 생략.
  Widget _buildLastAction() {
    final a = _game.lastAction;
    final show = a != null && !a.isHuman;
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SizeTransition(
            sizeFactor: anim, axisAlignment: -1, child: child),
      ),
      child: !show
          ? const SizedBox(key: ValueKey('no-action'), height: 0)
          : Container(
              key: ValueKey(_game.lastActionSeq),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.30),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: _lastActionChildren(a),
              ),
            ),
    );
  }

  List<Widget> _lastActionChildren(TurnAction a) {
    final children = <Widget>[
      Text('${a.playerName} ',
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold)),
    ];
    if (a.kind == TurnActionKind.play && a.card != null) {
      children
        ..add(const Text('→ ', style: TextStyle(color: Colors.white70)))
        ..add(CardView(card: a.card!, width: 30));
      if (a.chosenColor != null) {
        children
          ..add(const SizedBox(width: 6))
          ..add(Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: CardView.colorOf(a.chosenColor!),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white70),
            ),
          ))
          ..add(const Text(' 로 변경',
              style: TextStyle(color: Colors.white70, fontSize: 12)));
      }
    } else {
      children.add(Text('→ ${a.drawCount}장 뽑음',
          style: const TextStyle(
              color: Colors.amberAccent, fontWeight: FontWeight.bold)));
    }
    return children;
  }

  Widget _buildStatus() {
    final pending = _game.pendingDraw;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          if (pending > 0)
            Text('누적 +$pending — 같은 종류로 받아치거나 뽑으세요',
                style: const TextStyle(
                    color: Colors.amberAccent, fontWeight: FontWeight.bold)),
          Text(
            _game.winner != null
                ? _game.message
                : (_game.isHumanTurn ? '내 차례 — ${_game.message}' : _game.message),
            style: const TextStyle(color: Colors.white),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildHand(Player human) {
    return Container(
      height: 130,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        itemCount: human.hand.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, i) {
          final card = human.hand[i];
          final playable = _game.isHumanTurn && _game.canPlayCard(card);
          return CardView(
            card: card,
            playable: playable,
            onTap: () => _game.playHuman(card),
          );
        },
      ),
    );
  }
}
