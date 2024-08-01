import 'dart:io';

class Contact {
  final int? id;
  final String name;
  final String phoneNumber;
  final String email;
  final String? photoPath;

  Contact({this.id, required this.name, required this.phoneNumber, required this.email, this.photoPath});

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phoneNumber': phoneNumber,
      'email': email,
      'photoPath': photoPath,
    };
  }

  factory Contact.fromMap(Map<String, dynamic> map) {
    return Contact(
      id: map['id'],
      name: map['name'],
      phoneNumber: map['phoneNumber'],
      email: map['email'],
      photoPath: map['photoPath'],
    );
  }
}
