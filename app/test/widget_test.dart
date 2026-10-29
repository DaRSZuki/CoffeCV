import 'package:flutter_test/flutter_test.dart';

import 'package:cvcafe/main.dart';

void main() {
  testWidgets('La pantalla principal muestra las dos secciones', (tester) async {
    await tester.pumpWidget(const CvCafeApp());
    expect(find.text('Guía de enfermedades'), findsOneWidget);
    expect(find.text('Identificar enfermedad'), findsOneWidget);
  });
}
