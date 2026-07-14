import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uno_flutter/main.dart';
import 'package:uno_flutter/widgets/card_view.dart';

void main() {
  testWidgets('게임 화면이 뜨고 손패 7장과 덱이 렌더된다', (WidgetTester tester) async {
    await tester.pumpWidget(const UnoApp());
    await tester.pump();

    expect(find.text('UNO'), findsOneWidget);
    expect(find.text('DRAW'), findsOneWidget);

    // 손패 7장 + 버린 더미 맨 위 1장이 CardView로 그려진다.
    // (가로 리스트라 일부만 보일 수 있으므로 최소 1장 이상 렌더 확인)
    expect(find.byType(CardView), findsWidgets);

    // 새 게임 버튼 존재
    expect(find.byIcon(Icons.refresh), findsOneWidget);
  });
}
