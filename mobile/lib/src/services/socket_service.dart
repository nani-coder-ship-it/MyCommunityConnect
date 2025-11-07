import 'package:socket_io_client/socket_io_client.dart' as io;
import 'auth_service.dart';
import 'config_service.dart';

class SocketService {
  final AuthService auth;
  io.Socket? _socket;
  String? userId;
  String? userName;
  bool _isConnecting = false;

  SocketService({required this.auth});

  Future<void> connect() async {
    if (_isConnecting || _socket?.connected == true) return;

    final token = await auth.getToken();
    if (token == null) return;

    _isConnecting = true;

    try {
      final wsBaseUrl = await ConfigService.I.getWsBaseUrl();

      _socket = io.io(
        wsBaseUrl,
        io.OptionBuilder()
            .setTransports(['websocket', 'polling'])
            .enableForceNew()
            .enableReconnection()
            .setReconnectionAttempts(5)
            .setReconnectionDelay(2000)
            .setReconnectionDelayMax(5000)
            .setTimeout(10000)
            .setAuth({'token': token})
            .build(),
      );

      _socket?.onConnect((_) {
        // Silent in production
      });

      _socket?.onDisconnect((_) {
        // Silent in production
      });

      _socket?.onConnectError((data) {
        // Silent in production - no error spam
      });

      _socket?.onError((data) {
        // Silent in production - no error spam
      });
    } catch (e) {
      // Silent error handling
    } finally {
      _isConnecting = false;
    }
  }

  void disconnect() {
    _socket?.disconnect();
    _socket?.dispose();
    _socket = null;
  }

  io.Socket? get socket => _socket;
}
