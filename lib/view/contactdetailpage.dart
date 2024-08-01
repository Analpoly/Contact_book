import 'dart:io';

import 'package:contact_book/controller/contactcontroller.dart';
import 'package:contact_book/model/contact.dart';
import 'package:flutter/material.dart';


class ContactDetailPage extends StatelessWidget {
  final Contact contact;

  const ContactDetailPage({Key? key, required this.contact}) : super(key: key);

  void _deleteContact(BuildContext context) async {
    await ContactController.instance.deleteContact(contact.id!);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contact Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${contact.name}', style: Theme.of(context).textTheme.titleLarge),
            Text('Phone Number: ${contact.phoneNumber}', style: Theme.of(context).textTheme.titleMedium),
            Text('Email: ${contact.email}', style: Theme.of(context).textTheme.titleMedium),
            SizedBox(height: 16.0),
            if (contact.photoPath != null)
              Image.file(File(contact.photoPath!)),
            SizedBox(height: 16.0),
            ElevatedButton(
              onPressed: () => _deleteContact(context),
              child: Text('Delete Contact'),
            ),
          ],
        ),
      ),
    );
  }
}
