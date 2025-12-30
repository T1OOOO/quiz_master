import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

class SocketService extends ChangeNotifier {
  WebSocketChannel? _channel;
  Map<String, dynamic>? roomState;
  List<dynamic> chatHistory = [];
  bool isConnected = false;

  void connect(String url) {
    _channel = WebSocketChannel.connect(Uri.parse(url));
    isConnected = true;
    notifyListeners();

    _channel!.stream.listen((message) {
      final data = jsonDecode(message);
      if (data['type'] == 'room_state') {
        roomState = data['room'];
        if (data['room']['chat_history'] != null) {
          chatHistory = data['room']['chat_history'];
        }
        notifyListeners();
      } else if (data['type'] == 'chat_message') {
        chatHistory.add(data['message']);
        notifyListeners();
      }
    }, onDone: () {
      isConnected = false;
      notifyListeners();
    });
  }

  void sendMessage(String type, dynamic payload) {
    if (_channel != null) {
      _channel!.sink.add(jsonEncode({
        'type': type,
        'payload': payload,
      }));
    }
  }

  @override
  void dispose() {
    _channel?.sink.close();
    super.dispose();
  }
}
