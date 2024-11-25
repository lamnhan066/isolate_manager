import 'dart:convert';

class User {
  User({
    required this.name,
    required this.email,
  });

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      name: map['name'] as String,
      email: map['email'] as String,
    );
  }

  factory User.fromJson(String source) =>
      User.fromMap(json.decode(source) as Map<String, dynamic>);

  final String name;
  final String email;

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'email': email,
    };
  }

  String toJson() => json.encode(toMap());
}
