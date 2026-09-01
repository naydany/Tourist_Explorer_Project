import 'package:flutter_test/flutter_test.dart';
import 'package:tourist_explorer_project/core/app.dart';

void main() {
  testWidgets('app boots to the explore screen', (tester) async {
    await tester.pumpWidget(const TouristExplorerApp());

    expect(find.text('Explore'), findsOneWidget);
  });
}
