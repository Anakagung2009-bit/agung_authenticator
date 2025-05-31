class PasswordModel {
  final String id;
  final String accountType;
  final String accountName;
  final String username;
  final String password;
  final DateTime createdAt;

  PasswordModel({
    required this.id,
    required this.accountType,
    this.accountName = '',
    required this.username,
    required this.password,
    required this.createdAt,
  });

  factory PasswordModel.fromMap(Map<String, dynamic> map, String id) {
    return PasswordModel(
      id: id,
      accountType: map['accountType'] ?? 'Custom Account',
      accountName: map['accountName'] ?? '',
      username: map['username'] ?? '',
      password: map['password'] ?? '',
      createdAt: map['createdAt']?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'accountType': accountType,
      'accountName': accountName,
      'username': username,
      'password': password,
      'createdAt': createdAt,
    };
  }
}
