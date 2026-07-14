import 'package:flutter/material.dart';

/// 카드 색상. wild는 색이 없는 와일드 계열.
enum CardColor { red, yellow, green, blue, wild }

/// 카드 종류.
enum CardType { number, skip, reverse, drawTwo, wild, wildDrawFour }

/// UNO 카드 한 장(불변).
@immutable
class UnoCard {
  final CardColor color;
  final CardType type;

  /// 숫자 카드(0~9)일 때만 값이 있다. 그 외에는 null.
  final int? value;

  const UnoCard(this.color, this.type, [this.value]);

  bool get isWild => color == CardColor.wild;

  bool get isDrawCard =>
      type == CardType.drawTwo || type == CardType.wildDrawFour;

  /// 이 카드가 상대에게 뽑게 하는 장수(0이면 드로우 아님).
  int get drawCount {
    switch (type) {
      case CardType.drawTwo:
        return 2;
      case CardType.wildDrawFour:
        return 4;
      default:
        return 0;
    }
  }

  /// 화면 표시용 라벨.
  String get label {
    switch (type) {
      case CardType.number:
        return '$value';
      case CardType.skip:
        return '⊘';
      case CardType.reverse:
        return '⇄';
      case CardType.drawTwo:
        return '+2';
      case CardType.wild:
        return '★';
      case CardType.wildDrawFour:
        return '+4';
    }
  }

  @override
  String toString() => '${color.name}:${type.name}${value ?? ''}';
}
