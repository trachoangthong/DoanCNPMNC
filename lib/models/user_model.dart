class UserModel {
  final String fullName;
  final String email;
  final String phone;
  final String password;
  final String avatar;
  final String gender;
  final String city;
  final String address;
  final String role;

  UserModel({
    required this.fullName,
    required this.email,
    required this.phone,
    required this.password,
    required this.avatar,
    required this.gender,
    required this.city,
    this.address = '',
    this.role = 'user',
  });

  Map<String, dynamic> toJson() {
    return {
      "fullName": fullName,
      "email": email,
      "phone": phone,
      "password": password,
      "avatar": avatar,
      "gender": gender,
      "city": city,
      "address": address,
      "role": role,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      fullName: json["fullName"] ?? "",
      email: json["email"] ?? "",
      phone: json["phone"] ?? "",
      password: json["password"] ?? "",
      avatar: json["avatar"] ?? "",
      gender: json["gender"] ?? "",
      city: json["city"] ?? "",
      address: json["address"] ?? "",
      role: json["role"] ?? "user",
    );
  }

  @override
  String toString() {
    return '''
UserModel(
  fullName: $fullName,
  email: $email,
  phone: $phone,
  password: $password,
  avatar: $avatar,
  gender: $gender,
  city: $city,
  address: $address,
  role: $role
)
''';
  }
}
