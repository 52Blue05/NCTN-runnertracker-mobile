class UserModel {
  const UserModel({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
  });

  final String id;
  final String username;
  final String name;
  final String email;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final username = json['username']?.toString() ?? '';

    return UserModel(
      id: json['id']?.toString() ?? '',
      username: username,
      name: json['name']?.toString() ?? username,
      email: json['email']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'username': username, 'name': name, 'email': email};
  }
}
