/// Model entitas data pengguna (User) ThinkSpend.
///
/// Menyimpan informasi profil, autentikasi, serta baseline keuangan
/// (penghasilan dan anggaran bulanan) untuk analisis finansial.
class UserModel {
  final int? id;
  final String name;
  final String email;
  final String phone;
  final String password;
  final double income;
  final double monthlyBudget;

  UserModel({
    this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    this.income = 0,
    this.monthlyBudget = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'password': password,
      'income': income,
      'monthly_budget': monthlyBudget,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
  return UserModel(
    id: map['id'],
    name: map['name'],
    email: map['email'],
    phone: map['phone'],
    password: map['password'],
    income: (map['income'] as num?)?.toDouble() ?? 0,
    monthlyBudget: (map['monthly_budget'] as num?)?.toDouble() ?? 0,
  );
}
}