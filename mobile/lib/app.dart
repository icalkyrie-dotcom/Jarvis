import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'features/chat/chat_controller.dart';
import 'features/chat/voice_controller.dart';
import 'features/chat/conversation_controller.dart';
import 'features/chat/chat_screen.dart';

class JarvisApp extends StatelessWidget {
  const JarvisApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ChatController()),
        ChangeNotifierProvider(create: (_) => VoiceController()),
        ChangeNotifierProvider(create: (_) => ConversationController()),
      ],
      child: MaterialApp(
        title: 'Jarvis',
        debugShowCheckedModeBanner: false,
        theme: ThemeData.dark(),
        home: const ChatScreen(),
      ),
    );
  }
}