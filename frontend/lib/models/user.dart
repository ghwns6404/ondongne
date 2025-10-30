import 'package:cloud_firestore/cloud_firestore.dart';

class UserModel {
  final String uid;
  final String name;
  final String email;
  final bool isAdmin;

  UserModel({
    required this.uid,
    required this.name,
    required this.email,
    required this.isAdmin,
  });

  factory UserModel.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      name: data['name'] ?? '이름 없음',
      email: data['email'] ?? '이메일 없음',
      isAdmin: data['isAdmin'] ?? false,
    );
  }
}
