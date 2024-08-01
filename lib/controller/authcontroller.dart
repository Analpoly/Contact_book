import 'package:contact_book/model/authservice.dart';



class AuthController {
  static final AuthController instance = AuthController._privateConstructor();
  AuthController._privateConstructor();

  Future<bool> login(String email, String password) async {
    return await AuthService.instance.login(email, password);
  }

  Future<bool> register(String name, String email, String password, String phoneNumber) async {
    return await AuthService.instance.register(name, email, password, phoneNumber);
  }
}
