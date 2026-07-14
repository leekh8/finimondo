import 'package:flutter_test/flutter_test.dart';
import 'package:uno_flutter/game/rules.dart';
import 'package:uno_flutter/models/card.dart';
import 'package:uno_flutter/models/deck.dart';

void main() {
  group('canPlay', () {
    const redFive = UnoCard(CardColor.red, CardType.number, 5);

    test('같은 색이면 낼 수 있다', () {
      const redNine = UnoCard(CardColor.red, CardType.number, 9);
      expect(Rules.canPlay(redNine, redFive, CardColor.red), isTrue);
    });

    test('색이 달라도 숫자 값이 같으면 낼 수 있다', () {
      const blueFive = UnoCard(CardColor.blue, CardType.number, 5);
      expect(Rules.canPlay(blueFive, redFive, CardColor.red), isTrue);
    });

    test('색·값 모두 다른 숫자는 낼 수 없다 (숫자끼리 무조건 매치 버그 방지)', () {
      // 회귀 방지: '둘 다 숫자'라는 이유로 매치시키면 아무 숫자나 낼 수 있게 된다.
      const blueNine = UnoCard(CardColor.blue, CardType.number, 9);
      expect(Rules.canPlay(blueNine, redFive, CardColor.red), isFalse);
    });

    test('액션 카드는 색이 달라도 같은 타입이면 낼 수 있다', () {
      const redSkip = UnoCard(CardColor.red, CardType.skip);
      const blueSkip = UnoCard(CardColor.blue, CardType.skip);
      expect(Rules.canPlay(blueSkip, redSkip, CardColor.red), isTrue);
    });

    test('와일드는 언제나 낼 수 있다', () {
      const wild = UnoCard(CardColor.wild, CardType.wild);
      expect(Rules.canPlay(wild, redFive, CardColor.red), isTrue);
    });

    test('현재 색(와일드로 지정된 색) 기준으로 판정한다', () {
      const blueThree = UnoCard(CardColor.blue, CardType.number, 3);
      const wildTop = UnoCard(CardColor.wild, CardType.wild);
      // 와일드가 맨 위이고 지정색이 파랑이면 파란 카드는 낼 수 있다
      expect(Rules.canPlay(blueThree, wildTop, CardColor.blue), isTrue);
      // 지정색이 빨강이면 못 낸다
      expect(Rules.canPlay(blueThree, wildTop, CardColor.red), isFalse);
    });
  });

  group('드로우 중첩', () {
    const redDrawTwo = UnoCard(CardColor.red, CardType.drawTwo);

    test('+2 대기 중엔 +2로만 받아칠 수 있다', () {
      const blueDrawTwo = UnoCard(CardColor.blue, CardType.drawTwo);
      const redFive = UnoCard(CardColor.red, CardType.number, 5);
      expect(
        Rules.canPlay(blueDrawTwo, redDrawTwo, CardColor.red, pendingDraw: 2),
        isTrue,
      );
      expect(
        Rules.canPlay(redFive, redDrawTwo, CardColor.red, pendingDraw: 2),
        isFalse,
        reason: '같은 색 숫자라도 드로우 대기 중엔 못 낸다',
      );
    });

    test('+2 대기 중에 와일드는 받아칠 수 없다', () {
      const wild = UnoCard(CardColor.wild, CardType.wild);
      expect(
        Rules.canPlay(wild, redDrawTwo, CardColor.red, pendingDraw: 2),
        isFalse,
      );
    });
  });

  group('턴 이동', () {
    test('스킵은 한 명 건너뛴다', () {
      const skip = UnoCard(CardColor.red, CardType.skip);
      expect(Rules.turnStep(skip, 4), 2);
    });

    test('2인 게임에서 리버스는 스킵처럼 동작한다', () {
      const reverse = UnoCard(CardColor.red, CardType.reverse);
      expect(Rules.turnStep(reverse, 2), 2);
      expect(Rules.turnStep(reverse, 4), 1);
    });
  });

  group('덱', () {
    test('표준 덱은 108장이다', () {
      expect(Deck.buildStandardDeck().length, 108);
    });

    test('첫 카드는 와일드가 아니다 (유효 색이 필요)', () {
      final deck = Deck();
      final first = deck.flipFirstCard();
      expect(first.isWild, isFalse);
    });

    test('드로우 카드 장수', () {
      expect(const UnoCard(CardColor.red, CardType.drawTwo).drawCount, 2);
      expect(const UnoCard(CardColor.wild, CardType.wildDrawFour).drawCount, 4);
      expect(const UnoCard(CardColor.red, CardType.number, 5).drawCount, 0);
    });
  });
}
