import 'package:flutter/material.dart';
import 'chat_service.dart';
import 'conversation_service.dart';

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime time;
  final String? toolUsed;

  ChatMessage({
    required this.text,
    required this.isUser,
    DateTime? time,
    this.toolUsed,
  }) : time = time ?? DateTime.now();
}

class ChatController extends ChangeNotifier {
  final ChatService _service = ChatService();
  final ConversationService _convService = ConversationService();

  List<ChatMessage> messages = [];
  bool isLoading = false;
  String? activeConversationId;
  String activeTitle = 'Jarvis';
  String loadingText = 'Jarvis sedang berpikir...';

  void startNewChat() {
    messages = [];
    activeConversationId = null;
    activeTitle = 'Jarvis';
    loadingText = 'Jarvis sedang berpikir...';
    notifyListeners();
  }

  Future<void> loadConversation(String conversationId, String title) async {
    isLoading = true;
    activeConversationId = conversationId;
    activeTitle = title;
    messages = [];
    notifyListeners();

    try {
      final detail = await _convService.getConversationDetail(conversationId);
      final rawMessages = detail['messages'] as List;
      messages = rawMessages
          .map((m) => ChatMessage(
                text: m['content'],
                isUser: m['role'] == 'user',
              ))
          .toList();
    } catch (e) {
      messages = [];
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;

    messages.add(ChatMessage(text: text, isUser: true));
    isLoading = true;
    loadingText = 'Jarvis sedang berpikir...';
    notifyListeners();

    try {
      final result = await _service.sendMessage(
        text,
        conversationId: activeConversationId,
      );

      activeConversationId = result['conversation_id'];
      activeTitle = result['title'] ?? activeTitle;

      final toolUsed = result['tool_used'] as String?;

      messages.add(ChatMessage(
        text: result['response'],
        isUser: false,
        toolUsed: toolUsed,
      ));
    } catch (e) {
      messages.add(ChatMessage(
        text: 'Error: ${e.toString()}',
        isUser: false,
      ));
    } finally {
      isLoading = false;
      loadingText = 'Jarvis sedang berpikir...';
      notifyListeners();
    }
  }
}