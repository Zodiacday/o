import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/session_item.dart';

class HistoryService {
  static const _key = 'flutter_go_history_v2';

  static Future<List<SessionItem>> getHistory() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((e) {
          try {
            return SessionItem.fromJson(jsonDecode(e) as Map<String, dynamic>);
          } catch (_) {
            return null;
          }
        })
        .whereType<SessionItem>()
        .toList();
  }

  static Future<void> saveSession(String url, {String? title}) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getHistory();

    // Check if entry already exists to preserve favorite status
    final existingIndex = list.indexWhere((e) => e.url == url);
    bool isFav = false;
    String cleanTitle = title ?? _deriveTitle(url);

    if (existingIndex != -1) {
      isFav = list[existingIndex].isFavorite;
      if (title == null) {
        cleanTitle = list[existingIndex].title;
      }
      list.removeAt(existingIndex);
    }

    list.insert(
      0,
      SessionItem(
        id: 'session_${DateTime.now().millisecondsSinceEpoch}',
        url: url,
        title: cleanTitle,
        timestamp: DateTime.now(),
        isFavorite: isFav,
      ),
    );

    // Keep max 25 recent items
    if (list.length > 25) {
      list.removeRange(25, list.length);
    }

    final encoded = list.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, encoded);
  }

  static Future<void> toggleFavorite(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getHistory();
    final index = list.indexWhere((e) => e.id == id);
    if (index != -1) {
      list[index] = list[index].copyWith(isFavorite: !list[index].isFavorite);
      final encoded = list.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_key, encoded);
    }
  }

  static Future<void> updateTitle(String id, String newTitle) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getHistory();
    final index = list.indexWhere((e) => e.id == id);
    if (index != -1) {
      list[index] = list[index].copyWith(title: newTitle);
      final encoded = list.map((e) => jsonEncode(e.toJson())).toList();
      await prefs.setStringList(_key, encoded);
    }
  }

  static Future<void> removeSession(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getHistory();
    list.removeWhere((e) => e.id == id);
    final encoded = list.map((e) => jsonEncode(e.toJson())).toList();
    await prefs.setStringList(_key, encoded);
  }

  static Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }

  static String _deriveTitle(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.pathSegments.isNotEmpty && uri.pathSegments.first.isNotEmpty) {
        return uri.pathSegments.first.replaceAll('-', ' ').toUpperCase();
      }
      return '${uri.host}:${uri.port}';
    } catch (_) {
      return url;
    }
  }
}
