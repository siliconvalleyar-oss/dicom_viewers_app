import 'package:flutter_test/flutter_test.dart';
import 'package:dicom_visual/main.dart';

void main() {
  testWidgets('App launches and shows empty state', (WidgetTester tester) async {
    await tester.pumpWidget(const DicomVisualApp());
    expect(find.text('DICOM Viewer'), findsOneWidget);
    expect(find.text('No DICOM files loaded'), findsOneWidget);
  });
}
