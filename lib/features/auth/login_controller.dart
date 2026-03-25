import 'package:logbook_app_001/features/auth/model/login_data.dart';

class LoginController {
  final List<LoginData> loginData = [
    LoginData(
      id: "1",
      password: "123",
      role: "Ketua",
      username: "admin",
      teamId: "a",
    ),
    LoginData(
      id: "3",
      password: "123",
      role: "Anggota",
      username: "mike",
      teamId: "a",
    ),
    LoginData(
      id: "4",
      password: "123",
      role: "Anggota",
      username: "arthur",
      teamId: "a",
    ),
    LoginData(
      id: "5",
      password: "123",
      role: "Ketua",
      username: "admin2",
      teamId: "b",
    ),
  ];

  LoginData? authenticate(String username, String password) {
    return loginData.cast<LoginData?>().firstWhere(
      (data) => data!.username == username && data.password == password,
      orElse: () => null,
    );
  }

  // Fungsi pengecekan (Logic-Only)
  // Fungsi ini mengembalikan true jika cocok, false jika salah.
  // bool login(String username, String password) {
  //   String? userPass = loginData[username];

  //   if (userPass == null) {
  //     return false;
  //   }
  //   return userPass == password;
  // }
}
