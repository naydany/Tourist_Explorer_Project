import 'package:flutter_test/flutter_test.dart';
import 'package:tourist_explorer_project/app/app.dart';

void main() {
  testWidgets('app boots to the home screen', (tester) async {
    await tester.pumpWidget(const TouristExplorerApp());

    expect(find.text('Tourist Explorer'), findsOneWidget);
    expect(find.text('Discover places worth the trip'), findsOneWidget);
  });
}
