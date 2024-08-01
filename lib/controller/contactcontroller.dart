import 'package:contact_book/model/contact.dart';
import 'package:contact_book/model/databasehelper.dart';



class ContactController {
  static final ContactController instance = ContactController._privateConstructor();
  ContactController._privateConstructor();

  Future<List<Contact>> getContacts() async {
    return await DatabaseHelper.instance.getContacts();
  }

  Future<void> addContact(Contact contact) async {
    await DatabaseHelper.instance.insertContact(contact);
  }

  Future<void> deleteContact(int id) async {
    await DatabaseHelper.instance.deleteContact(id);
  }
}
