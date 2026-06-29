import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../../core/constants.dart';

/// Evento recebido via WebSocket, originado de um evento publicado no MOM
/// (RabbitMQ) e repassado pelo backend em tempo real — ver
/// Backend/src/realtime/ws.js e Backend/src/messaging/consumer.js.
class RealtimeEvent {
  final String event;
  final Map<String, dynamic> payload;
  RealtimeEvent(this.event, this.payload);
}

class RealtimeRepository {
  final String token;
  WebSocketChannel? _channel;
  StreamController<RealtimeEvent>? _controller;
  Timer? _reconnectTimer;
  bool _disposed = false;

  RealtimeRepository({required this.token});

  Stream<RealtimeEvent> connect() {
    _controller ??= StreamController<RealtimeEvent>.broadcast();
    _open();
    return _controller!.stream;
  }

  void _open() {
    if (_disposed) return;
    try {
      _channel = WebSocketChannel.connect(
        Uri.parse('${AppConstants.wsUrl}?token=$token'),
      );
      _channel!.stream.listen(
        (message) {
          try {
            final decoded = jsonDecode(message as String) as Map<String, dynamic>;
            _controller?.add(RealtimeEvent(
              decoded['event'] as String,
              decoded['payload'] as Map<String, dynamic>,
            ));
          } catch (_) {
            // mensagem em formato inesperado — ignora
          }
        },
        onDone: _scheduleReconnect,
        onError: (_) => _scheduleReconnect(),
      );
    } catch (_) {
      _scheduleReconnect();
    }
  }

  void _scheduleReconnect() {
    if (_disposed) return;
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), _open);
  }

  void dispose() {
    _disposed = true;
    _reconnectTimer?.cancel();
    _channel?.sink.close();
    _controller?.close();
  }
}
