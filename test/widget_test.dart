// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zichat/main.dart';
import 'package:zichat/storage/friend_storage.dart';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    tempDir = await Directory.systemTemp.createTemp('zichat_test_');
    Hive.init(tempDir.path);
    await FriendStorage.initialize();
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      await tempDir.delete(recursive: true);
    } catch (_) {}
  });

  testWidgets('App launches successfully', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ZiChatApp());

    // Wait for splash screen delay to complete.
    await tester.pump(const Duration(seconds: 3));

    // Verify that the app renders without errors
    expect(find.byType(ZiChatApp), findsOneWidget);
  });
}
