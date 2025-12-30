import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/socket_service.dart';
import '../services/api_service.dart';

class MultiplayerScreen extends StatefulWidget {
  const MultiplayerScreen({super.key});

  @override
  State<MultiplayerScreen> createState() => _MultiplayerScreenState();
}

class _MultiplayerScreenState extends State<MultiplayerScreen> {
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _chatController = TextEditingController();

  @override
  void initState() {
    super.initState();
    final socket = context.read<SocketService>();
    if (!socket.isConnected) {
       // Adapt for web/android
       final url = kIsWeb ? "ws://localhost:8080/ws" : "ws://10.0.2.2:8080/ws";
       socket.connect(url);
    }
  }

  @override
  Widget build(BuildContext context) {
    final socket = context.watch<SocketService>();

    if (socket.roomState == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Multiplayer Lobby")),
        body: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              TextField(controller: _nameController, decoration: const InputDecoration(labelText: "Nickname")),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => socket.sendMessage("create_room", {"username": _nameController.text, "avatar": "#FF0000"}),
                child: const Text("Create Room"),
              ),
              const Divider(height: 48),
              TextField(controller: _codeController, decoration: const InputDecoration(labelText: "Room Code")),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => socket.sendMessage("join_room", {"code": _codeController.text.toUpperCase(), "username": _nameController.text, "avatar": "#00FF00"}),
                child: const Text("Join Room"),
              ),
            ],
          ),
        ),
      );
    }

    final room = socket.roomState!;
    return Scaffold(
      appBar: AppBar(
        title: Text("Room: ${room['code']}"),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat),
            onPressed: () => _showChat(context),
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: room['players'].length,
              itemBuilder: (context, index) {
                final player = room['players'][index];
                return ListTile(
                  leading: CircleAvatar(backgroundColor: Colors.blue),
                  title: Text(player['username']),
                  trailing: Text("${player['score']} pts"),
                );
              },
            ),
          ),
          if (room['host'] == _nameController.text)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => socket.sendMessage("start_game", {"quiz_id": "lotr"}),
                child: const Text("Start Game"),
              ),
            )
        ],
      ),
    );
  }

  void _showChat(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return DraggableScrollableSheet(
          expand: false,
          builder: (context, scrollController) {
            final socket = context.watch<SocketService>();
            return Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    itemCount: socket.chatHistory.length,
                    itemBuilder: (context, index) {
                      final msg = socket.chatHistory[index];
                      return ListTile(
                        title: Text(msg['user'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        subtitle: Text(msg['text']),
                      );
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      Expanded(child: TextField(controller: _chatController)),
                      IconButton(
                        icon: const Icon(Icons.send),
                        onPressed: () {
                          socket.sendMessage("chat", {"text": _chatController.text, "image": ""});
                          _chatController.clear();
                        },
                      )
                    ],
                  ),
                )
              ],
            );
          },
        );
      },
    );
  }
}
