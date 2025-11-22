import 'package:hive/hive.dart';

class ChatStorage {
  static const String boxName = 'chat_messages';

  static Box<dynamic> get _box => Hive.box<dynamic>(boxName);

  static Future<List<Map<String, dynamic>>> loadMessages(String chatId) async {
    final dynamic raw = _box.get(chatId);
    if (raw is List) {
      return raw
          .whereType<Map>()
          .map((e) => e.map((key, value) => MapEntry(key.toString(), value)))
          .toList();
    }
    return <Map<String, dynamic>>[];
  }

  static bool hasMessages(String chatId) {
    return _box.containsKey(chatId);
  }

  static Future<void> saveMessages(
    String chatId,
    List<Map<String, dynamic>> messages,
  ) async {
    await _box.put(chatId, messages);
  }
}
