import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'conversation_service.dart';

class ConversationController extends ChangeNotifier {
  final ConversationService _service = ConversationService();

  List<ConversationItem> conversations = [];
  bool isLoading = false;

  Future<void> loadConversations() async {
    isLoading = true;
    notifyListeners();
    try {
      conversations = await _service.getConversations();
      debugPrint('✅ Loaded ${conversations.length} conversations');
      for (final c in conversations) {
        debugPrint('  - ${c.id}: ${c.title}');
      }
    } catch (e) {
      debugPrint('❌ Error loading conversations: $e');
      conversations = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteConversation(String id) async {
    await _service.deleteConversation(id);
    conversations.removeWhere((c) => c.id == id);
    notifyListeners();
  }

  Future<void> renameConversation(String id, String title) async {
    await _service.renameConversation(id, title);
    final index = conversations.indexWhere((c) => c.id == id);
    if (index != -1) {
      conversations[index] = ConversationItem(
        id: id,
        title: title,
        updatedAt: conversations[index].updatedAt,
      );
      notifyListeners();
    }
  }
}