import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api_service.dart';

class AuthService {
  final FlutterSecureStorage storage = const FlutterSecureStorage();
  final api = ApiService();

  Future<void> init() async {
    final token = await storage.read(key: 'token');
    api.setToken(token);
  }

  Future<bool> hasToken() async {
    final token = await storage.read(key: 'token');
    return token != null;
  }

  Future<String?> getToken() async {
    return storage.read(key: 'token');
  }

  Future<bool> login(String email, String password) async {
    final res = await api.dio
        .post('/api/auth/login', data: {'email': email, 'password': password});
    final token = res.data['token'] as String;
    await storage.write(key: 'token', value: token);
    api.setToken(token);
    return true;
  }

  Future<bool> register(Map<String, dynamic> data) async {
    final res = await api.dio.post('/api/auth/register', data: data);
    final token = res.data['token'] as String;
    await storage.write(key: 'token', value: token);
    api.setToken(token);
    return true;
  }

  Future<void> logout() async {
    await storage.delete(key: 'token');
    api.setToken(null);
  }
}
