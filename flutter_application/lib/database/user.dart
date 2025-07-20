class UserModel {
  final String id;
  final String username;
  final String email;
  final String phonenumber;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.phonenumber,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['\$id'],
      username: map['username'],
      email: map['email'],
      phonenumber: map['phonenumber'],
    );
  }
}
