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

  @override
  void initState() {
    super.initState();
    _game = GameState();
    _game.addListener(_onGameChanged);
  }

  void _onGameChanged() {
    if (!mounted) return;
    setState(() {});
    if (_game.awaitingColorChoice) {
      _askColor();
    }
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
          final isTurn = _game.currentPlayer == p;
          return Column(
            children: [
              CircleAvatar(
                backgroundColor: isTurn ? Colors.amber : Colors.white24,
                child: Text('${p.hand.length}',
                    style: TextStyle(
                        color: isTurn ? Colors.black : Colors.white,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 4),
              Text(p.name, style: const TextStyle(color: Colors.white70, fontSize: 12)),
            ],
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
