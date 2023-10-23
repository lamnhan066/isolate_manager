import 'dart:convert';

class ComplexModelParam {
  final String name;
  final int age;
  final List<String> hobbies;

  ComplexModelParam({
    required this.name,
    required this.age,
    required this.hobbies,
  });

  String toJson() => jsonEncode(toMap());

  factory ComplexModelParam.fromJson(String json) =>
      ComplexModelParam.fromMap(jsonDecode(json));

  factory ComplexModelParam.fromMap(Map<String, dynamic> json) {
    return ComplexModelParam(
      name: json['name'],
      age: json['age'],
      hobbies: List<String>.from(json['hobbies']),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'age': age,
      'hobbies': hobbies,
    };
  }
}

class ComplexModelResult {
  final List<String> messages;

  ComplexModelResult(this.messages);

  Map<String, dynamic> toMap() {
    return {
      'messages': messages,
    };
  }

  factory ComplexModelResult.fromMap(Map<String, dynamic> map) {
    return ComplexModelResult(
      List<String>.from(map['messages']),
    );
  }

  String toJson() => json.encode(toMap());

  factory ComplexModelResult.fromJson(String source) =>
      ComplexModelResult.fromMap(json.decode(source));
}
