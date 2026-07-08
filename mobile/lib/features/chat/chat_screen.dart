import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';
import 'chat_controller.dart';
import 'voice_controller.dart';
import 'conversation_controller.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _hasAutoStartedMic = false;
  int? _pressedQuickActionIndex;

  @override
  void initState() {
    super.initState();
    _autoStartMic();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ConversationController>().loadConversations();
    });
  }

  void _autoStartMic() {
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      if (_hasAutoStartedMic) return;
      _hasAutoStartedMic = true;
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      final voice = context.read<VoiceController>();
      final chat = context.read<ChatController>();
      await voice.startListening(
        onResult: (words) => _handleSend(chat, voice, words),
      );
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleSend(ChatController chat, VoiceController voice, String text) async {
    if (text.trim().isEmpty) return;

    _textController.clear();

    await chat.sendMessage(text);

    if (!mounted) return;

    final lastMsg = chat.messages.last;

    if (!lastMsg.isUser) {
      voice.speak(lastMsg.text);
    }

    context.read<ConversationController>().loadConversations();

    _scrollToBottom();
  }

  void _handleVoice(ChatController chat, VoiceController voice) async {
    if (voice.isListening) {
      await voice.stopListening();
      return;
    }
    await voice.startListening(
      onResult: (words) => _handleSend(chat, voice, words),
    );
  }

  void _showRenameDialog(BuildContext context, String id, String currentTitle) {
    final controller = TextEditingController(text: currentTitle);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        title: const Text('Rename Chat',
            style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Nama baru...',
            hintStyle: TextStyle(color: Colors.grey),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () {
              context
                  .read<ConversationController>()
                  .renameConversation(id, controller.text);
              Navigator.pop(context);
            },
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ChatController, VoiceController, ConversationController>(
      builder: (context, chat, voice, convCtrl, _) {
        _scrollToBottom();
        return Scaffold(
          backgroundColor: const Color(0xFF05080D),
          appBar: AppBar(
            backgroundColor: const Color(0xFF05080D),
            title: Text(
              chat.activeTitle,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                fontSize: 16,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            centerTitle: true,
            actions: [
              IconButton(
                icon: const Icon(Icons.add, color: Colors.white),
                onPressed: () {
                  chat.startNewChat();
                  // Tidak perlu Navigator.pop — tidak ada yang di-pop
                },
                tooltip: 'New Chat',
              ),
            ],
          ),
          drawer: _buildDrawer(context, chat, convCtrl),
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  "assets/images/jarvis_background.png",
                  fit: BoxFit.cover,
                ),
              ),
              Positioned.fill(
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color.fromARGB(170, 0, 0, 0),
                        Color.fromARGB(130, 0, 0, 0),
                        Color(0xFF090909),
                      ],
                    ),
                  ),
                ),
              ),
              SafeArea(
                child: Column(
                  children: [
                    if (voice.isListening)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        color: const Color(0xFF1A1A2E),
                        child: Text(
                          voice.lastWords.isEmpty
                              ? 'Mendengarkan...'
                              : voice.lastWords,
                          style: const TextStyle(
                              color: Colors.lightBlueAccent, fontSize: 13),
                        ),
                      ),
                    Expanded(
                      child: chat.messages.isEmpty
                          ? _buildWelcome()
                          : ListView.builder(
                              controller: _scrollController,
                              padding: const EdgeInsets.all(16),
                              itemCount: chat.messages.length,
                              itemBuilder: (context, index) =>
                                  _buildMessage(chat.messages[index]),
                            ),
                    ),
                    if (chat.isLoading)
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Text(
                          chat.loadingText,
                          style: const TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                      ),
                    _buildInputBar(chat, voice),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDrawer(BuildContext context, ChatController chat,
      ConversationController convCtrl) {
    return Drawer(
      backgroundColor: const Color(0xFF111111),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  const Text(
                    'JARVIS',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 4,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.add, color: Colors.white),
                    onPressed: () {
                      chat.startNewChat();
                      Navigator.pop(context);
                    },
                    tooltip: 'New Chat',
                  ),
                ],
              ),
            ),

            const Divider(color: Colors.white12),

            // Conversation list
            Expanded(
              child: convCtrl.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                          color: Colors.white24))
                  : convCtrl.conversations.isEmpty
                      ? const Center(
                          child: Text(
                            'Belum ada percakapan.',
                            style: TextStyle(
                                color: Colors.grey, fontSize: 13),
                          ),
                        )
                      : ListView.builder(
                          itemCount: convCtrl.conversations.length,
                          itemBuilder: (context, index) {
                            final conv = convCtrl.conversations[index];
                            final isActive =
                                conv.id == chat.activeConversationId;
                            return ListTile(
                              selected: isActive,
                              selectedTileColor:
                                  Colors.white.withValues(alpha: 0.08),
                              title: Text(
                                conv.title,
                                style: TextStyle(
                                  color: isActive
                                      ? Colors.white
                                      : Colors.white70,
                                  fontSize: 14,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              onTap: () {
                                chat.loadConversation(
                                    conv.id, conv.title);
                                Navigator.pop(context);
                              },
                              trailing: PopupMenuButton<String>(
                                color: const Color(0xFF1A1A1A),
                                icon: const Icon(Icons.more_vert,
                                    color: Colors.white38, size: 18),
                                onSelected: (value) {
                                  if (value == 'rename') {
                                    _showRenameDialog(
                                        context, conv.id, conv.title);
                                  } else if (value == 'delete') {
                                    convCtrl
                                        .deleteConversation(conv.id);
                                    if (chat.activeConversationId ==
                                        conv.id) {
                                      chat.startNewChat();
                                    }
                                  }
                                },
                                itemBuilder: (_) => [
                                  const PopupMenuItem(
                                    value: 'rename',
                                    child: Text('Rename',
                                        style: TextStyle(
                                            color: Colors.white)),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Delete',
                                        style: TextStyle(
                                            color: Colors.redAccent)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcome() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 20),
            const Text(
              'Hallo Bos Ical,',
              style: TextStyle(
                color: Colors.white,
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Butuh apa bos?',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 40),
            _buildQuickActions(),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      ('Butuh Advice?', Icons.chat, 'Saya butuh advice mengenai'),
      ('Reminder Project', Icons.schedule, 'Ingatkan saya mengenai project saya'),
      ('Project / Troubleshoot', Icons.build, 'Bantu saya menyelesaikan project berikut'),
      ('Analisis Dokumen', Icons.description, 'Tolong analisis dokumen ini'),
    ];

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.35,
        physics: const NeverScrollableScrollPhysics(),
        children: actions.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;
          final isPressed = _pressedQuickActionIndex == index;

          return GestureDetector(
            onTapDown: (_) {
              setState(() {
                _pressedQuickActionIndex = index;
              });
            },
            onTapUp: (_) {
              setState(() {
                _pressedQuickActionIndex = null;
              });
            },
            onTapCancel: () {
              setState(() {
                _pressedQuickActionIndex = null;
              });
            },
            onTap: () {
              _applyQuickPrompt(action.$3);
              setState(() {
                _pressedQuickActionIndex = null;
              });
            },
            child: _buildCard(action.$2, action.$1, isPressed: isPressed),
          );
        }).toList(),
      ),
    );
  }

  void _applyQuickPrompt(String prompt) {
    setState(() {
      _textController.text = prompt;
      _textController.selection = TextSelection.collapsed(
        offset: _textController.text.length,
      );
    });
  }

  Widget _buildCard(IconData icon, String title, {required bool isPressed}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      height: 125,
      transform: Matrix4.identity()
        ..scale(isPressed ? 0.96 : 1.0),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isPressed
              ? Colors.lightBlueAccent.withValues(alpha: 0.5)
              : Colors.white10,
        ),
        boxShadow: isPressed
            ? [
                BoxShadow(
                  color: Colors.lightBlueAccent.withValues(alpha: 0.18),
                  blurRadius: 18,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 34,
            color: Colors.lightBlueAccent,
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessage(ChatMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        crossAxisAlignment: msg.isUser
            ? CrossAxisAlignment.end
            : CrossAxisAlignment.start,
        children: [
          // Tool indicator
          if (!msg.isUser && msg.toolUsed != null)
            Padding(
              padding: const EdgeInsets.only(left: 8, bottom: 2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    msg.toolUsed == 'web_search' ? Icons.search : Icons.link,
                    size: 12,
                    color: Colors.white38,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    msg.toolUsed == 'web_search' ? 'Web Search' : 'URL Reader',
                    style: const TextStyle(
                      color: Colors.white38,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          Container(
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 4),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.78),
            decoration: BoxDecoration(
              color: msg.isUser ? const Color(0xFF1E88E5) : const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(18),
                topRight: const Radius.circular(18),
                bottomLeft: msg.isUser
                    ? const Radius.circular(18)
                    : const Radius.circular(4),
                bottomRight: msg.isUser
                    ? const Radius.circular(4)
                    : const Radius.circular(18),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  msg.text,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14, height: 1.4),
                ),
                const SizedBox(height: 4),
                Text(
                  '${msg.time.hour.toString().padLeft(2, '0')}:'
                  '${msg.time.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.white38, fontSize: 10),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputBar(ChatController chat, VoiceController voice) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      color: const Color(0xFF0A0A0A),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _textController,
              style: const TextStyle(color: Colors.white),
              maxLines: null,
              minLines: 1,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.newline,
              decoration: InputDecoration(
                hintText: 'Ketik atau tekan mic...',
                hintStyle: const TextStyle(color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFF1A1A1A),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _handleVoice(chat, voice),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: voice.isListening
                    ? Colors.redAccent
                    : const Color(0xFF2A2A2A),
                shape: BoxShape.circle,
              ),
              child: Icon(
                voice.isListening ? Icons.mic : Icons.mic_none,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: () => _handleSend(chat, voice, _textController.text),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF1E88E5),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}