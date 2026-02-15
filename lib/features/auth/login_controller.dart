class LoginController {
  Map<String, String> loginData = {
    "admin": "123",
    "budi": "123",
    "mike": "123",
  };

  // Fungsi pengecekan (Logic-Only)
  // Fungsi ini mengembalikan true jika cocok, false jika salah.
  bool login(String username, String password) {
    String? userPass = loginData[username];

    if (userPass == null) {
      return false;
    }
    return userPass == password;
  }
}
