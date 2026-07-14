import 'package:flutter/material.dart';

import '../models/card.dart';

/// 카드 한 장 렌더링. [playable]이 false면 흐리게 표시해 낼 수 없음을 알린다.
class CardView extends StatelessWidget {
  final UnoCard card;
  final bool playable;
  final VoidCallback? onTap;
  final double width;

  const CardView({
    super.key,
    required this.card,
    this.playable = true,
    this.onTap,
    this.width = 64,
  });

  static Color colorOf(CardColor c) {
    switch (c) {
      case CardColor.red:
        return const Color(0xFFD32F2F);
      case CardColor.yellow:
        return const Color(0xFFF9A825);
      case CardColor.green:
        return const Color(0xFF388E3C);
      case CardColor.blue:
        return const Color(0xFF1976D2);
      case CardColor.wild:
        return const Color(0xFF212121);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = colorOf(card.color);
    return Opacity(
      opacity: playable ? 1.0 : 0.42, // 낼 수 없는 카드는 흐리게
      child: GestureDetector(
        onTap: playable ? onTap : null,
        child: Container(
          width: width,
          height: width * 1.5,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white, width: 2),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 4, offset: Offset(0, 2)),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            card.label,
            style: TextStyle(
              color: Colors.white,
              fontSize: width * 0.42,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }
}
