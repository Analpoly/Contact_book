import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();
  static Database? _database;

  DatabaseHelper._privateConstructor();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final databasePath = await getDatabasesPath();
    final path = join(databasePath, 'contacts_database.db');

    return await openDatabase(path, version: 1, onCreate: _createDatabase);
  }

  Future<void> _createDatabase(Database db, int version) async {
    await db.execute('''
      CREATE TABLE contacts(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT,
        phoneNumber TEXT,
        email TEXT,
        photoPath TEXT
      )
    ''');
  }

  Future<int> insertContact(Contact contact) async {
    final db = await instance.database;
    return await db.insert('contacts', contact.toMap());
  }

  Future<int> updateContact(Contact contact) async {
    final db = await instance.database;
    return await db.update(
      'contacts',
      contact.toMap(),
      where: 'id = ?',
      whereArgs: [contact.id],
    );
  }

  Future<int> deleteContact(int id) async {
    final db = await instance.database;
    return await db.delete(
      'contacts',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<Contact>> getContacts() async {
    final db = await instance.database;
    final List<Map<String, dynamic>> maps = await db.query('contacts');
    return List.generate(maps.length, (i) {
      return Contact.fromMap(maps[i]);
    });
  }
}


class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Homepage(),
    );
  }
}

class Homepage extends StatefulWidget {
  const Homepage({Key? key}) : super(key: key);

  @override
  State<Homepage> createState() => _HomepageState();
}

class _HomepageState extends State<Homepage> {
  List<Contact> contacts = [];
  TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  _loadContacts() async {
    final loadedContacts = await DatabaseHelper.instance.getContacts();
    setState(() {
      contacts = loadedContacts;
    });
  }
 _addContact(BuildContext context, Contact contact) async {
    if (contact.name.isNotEmpty && contact.phoneNumber.isNotEmpty && contact.email.isNotEmpty) {
      await DatabaseHelper.instance.insertContact(contact);
      setState(() {
        contacts.add(contact);
      });
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Name, phone number, and email are required.'),
        ),
      );
    }
  }
_updateContact(Contact updatedContact) async {
    if (updatedContact.name.isNotEmpty && updatedContact.phoneNumber.isNotEmpty && updatedContact.email.isNotEmpty) {
      await DatabaseHelper.instance.updateContact(updatedContact);
      setState(() {
        int index = contacts.indexWhere((contact) => contact.id == updatedContact.id);
        if (index != -1) {
          contacts[index] = updatedContact;
        }
      });
    } else {
      ScaffoldMessenger.of(context as BuildContext).showSnackBar(
        const SnackBar(
          content: Text('Name, phone number, and email are required.'),
        ),
      );
    }
  }

 _searchContacts(String query) async {
    final loadedContacts = await DatabaseHelper.instance.getContacts();
    setState(() {
      contacts = loadedContacts.where((contact) {
        return contact.name.toLowerCase().contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color.fromARGB(243, 148, 188, 208),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 59, 121, 152),
        title: Text('Contacts',style: TextStyle(color: Color.fromARGB(232, 140, 242, 244)),),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.search,color:  Color.fromARGB(232, 140, 242, 244),),
            onPressed: () {
              showSearch(context: context, delegate: ContactSearch(contacts, _searchContacts));
            },
          ),
        ],
      ),
      body: ListView.builder(
        itemCount: contacts.length,
        itemBuilder: (BuildContext context, int index) {
          return ListTile(
            leading: contacts[index].photoPath != null
                ? CircleAvatar(
                    backgroundImage: FileImage(File(contacts[index].photoPath!)),
                  )
                : CircleAvatar(
                    child: Text(_getInitials(contacts[index].name)),
                  ),
            title: Text(contacts[index].name,style: TextStyle(color: Color.fromARGB(221, 0, 1, 7)),),
            subtitle: Text(contacts[index].phoneNumber,style: TextStyle(color: Color.fromARGB(221, 0, 1, 7))),
           onTap: () async {
  final deleted = await Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => ContactDetailPage(contact: contacts[index], updateContact: _updateContact,)),
  );

  if (deleted == true) {
    _loadContacts();
  }
}

          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddContactPage()),
          );
       if (result != null && result is Contact) {
  _addContact(context, result);
}

        },
        child: Icon(Icons.add),
      ),
    );
  }

  String _getInitials(String name) {
    List<String> nameSplit = name.split(' ');
    String initials = '';
    int numWords = nameSplit.length > 2 ? 2 : nameSplit.length;
    for (int i = 0; i < numWords; i++) {
      initials += nameSplit[i][0].toUpperCase();
    }
    return initials;
  }
}
class ContactSearch extends SearchDelegate<String> {
  final List<Contact> contacts;
  final Function(String) searchContacts;

  ContactSearch(this.contacts, this.searchContacts);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
          searchContacts('');
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    searchContacts(query);
    return Container(); // Return the actual search results here if you have a specific UI for it
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestionList = query.isEmpty
        ? []
        : contacts.where((contact) => contact.name.toLowerCase().contains(query.toLowerCase())).toList();
    
    return ListView.builder(
      itemCount: suggestionList.length,
      itemBuilder: (BuildContext context, int index) {
        final contact = suggestionList[index];
        return ListTile(
          title: Text(contact.name),
          onTap: () {
            close(context, contact.name);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => ContactDetailPage(contact: contact, updateContact: (Contact ) {  },)),
            );
          },
        );
      },
    );
  }
}
class AddContactPage extends StatefulWidget {
  @override
  _AddContactPageState createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _emailController;
  File? _image;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneNumberController = TextEditingController();
    _emailController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedImage != null) {
        _image = File(pickedImage.path);
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Contact'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _getImage,
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.grey[300],
                backgroundImage: _image != null ? FileImage(_image!) : null,
                child: _image == null
                    ? Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.blueGrey,
                      )
                    : null,
              ),
            ),
            SizedBox(height: 20),
          
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _phoneNumberController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final contact = Contact(
                  name: _nameController.text,
                  phoneNumber: _phoneNumberController.text,
                  email: _emailController.text,
                  photoPath: _image?.path,
                );
                Navigator.pop(context, contact);
              },
              child: Text('Save Contact'),
            ),
          ],
        ),
      ),
    );
  }
}

class ContactDetailPage extends StatelessWidget {
  final Contact contact;
  final Function(Contact) updateContact;

  const ContactDetailPage({required this.contact, required this.updateContact});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color.fromARGB(255, 59, 121, 152),
        title: Text(
          'Contact Details',
          style: TextStyle(
            color: Colors.white,
          ),
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.edit),
            color: Colors.white,
            onPressed: () => _editContact(context),
          ),
          IconButton(
            icon: Icon(Icons.delete),
            color: Colors.white,
            onPressed: () => _deleteContact(context),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: GestureDetector(
                onTap: () {
                  // Action when profile picture is tapped
                },
                child: CircleAvatar(
                  radius: 70,
                  backgroundColor: Colors.grey[300],
                  backgroundImage: contact.photoPath != null ? FileImage(File(contact.photoPath!)) : null,
                  child: contact.photoPath == null
                      ? Text(
                          _getInitials(contact.name),
                          style: TextStyle(fontSize: 40, color: Colors.blueGrey),
                        )
                      : null,
                ),
              ),
            ),
            SizedBox(height: 20),
            Divider(
              color: Colors.grey[400],
              thickness: 2,
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                // Action when name is tapped
              },
              child: Text(
                'Name:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            SizedBox(height: 5),
            GestureDetector(
              onTap: () {
                // Action when name is tapped
              },
              child: Text(
                contact.name,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[800],
                ),
              ),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                // Action when phone number is tapped
              },
              child: Text(
                'Phone Number:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            SizedBox(height: 5),
            GestureDetector(
              onTap: () {
                // Action when phone number is tapped
              },
              child: Text(
                contact.phoneNumber,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[800],
                ),
              ),
            ),
            SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                // Action when email is tapped
              },
              child: Text(
                'Email:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            SizedBox(height: 5),
            GestureDetector(
              onTap: () {
                // Action when email is tapped
              },
              child: Text(
                contact.email,
                style: TextStyle(
                  fontSize: 20,
                  color: Colors.grey[800],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
 String _getInitials(String name) {
    List<String> nameSplit = name.split(' ');
    String initials = '';
    int numWords = nameSplit.length > 2 ? 2 : nameSplit.length;
    for (int i = 0; i < numWords; i++) {
      initials += nameSplit[i][0].toUpperCase();
    }
    return initials;
  }
  void _editContact(BuildContext context) async {
    final updatedContact = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => EditContactPage(contact: contact)),
    );

    if (updatedContact != null && updatedContact is Contact) {
      updateContact(updatedContact);
    }
  }
void _deleteContact(BuildContext context) async {
  bool confirmDelete = await showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        title: Text('Delete Contact'),
        content: Text('Are you sure you want to delete this contact?'),
        actions: <Widget>[
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text('CANCEL'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text('DELETE'),
          ),
        ],
      );
    },
  );

  if (confirmDelete) {
    await DatabaseHelper.instance.deleteContact(contact.id!);
    Navigator.pop(context, true);  // Notify the previous screen to update the UI
  }
}

}

class EditContactPage extends StatefulWidget {
  final Contact contact;

  const EditContactPage({required this.contact});

  @override
  _EditContactPageState createState() => _EditContactPageState();
}

class _EditContactPageState extends State<EditContactPage> {
  late TextEditingController _nameController;
  late TextEditingController _phoneNumberController;
  late TextEditingController _emailController;
  File? _image;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.contact.name);
    _phoneNumberController = TextEditingController(text: widget.contact.phoneNumber);
    _emailController = TextEditingController(text: widget.contact.email);
    _image = widget.contact.photoPath != null ? File(widget.contact.photoPath!) : null;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _getImage() async {
    final picker = ImagePicker();
    final pickedImage = await picker.pickImage(source: ImageSource.gallery);
    setState(() {
      if (pickedImage != null) {
        _image = File(pickedImage.path);
      } else {
        print('No image selected.');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Edit Contact'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            GestureDetector(
              onTap: _getImage,
              child: CircleAvatar(
                radius: 70,
                backgroundColor: Colors.grey[300],
                backgroundImage: _image != null ? FileImage(_image!) : null,
                child: _image == null
                    ? Icon(
                        Icons.person,
                        size: 50,
                        color: Colors.blueGrey,
                      )
                    : null,
              ),
            ),
            SizedBox(height: 20),
           
            TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Name',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _phoneNumberController,
              decoration: InputDecoration(
                labelText: 'Phone Number',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
            TextFormField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 20),
           ElevatedButton(
  onPressed: () {
    final updatedContact = Contact(
      id: widget.contact.id,
      name: _nameController.text,
      phoneNumber: _phoneNumberController.text,
      email: _emailController.text,
      photoPath: _image?.path ?? widget.contact.photoPath,
    );
    Navigator.pop(context, updatedContact);
  },
  child: Text('Save Changes'),
)

          ],
        ),
      ),
    );
  }

  // void _updateContact(Contact updatedContact) async {
  //   await DatabaseHelper.instance.updateContact(updatedContact);
  // }


 



 
//   _updateContact(Contact updatedContact) async {
//     if (updatedContact.name.isNotEmpty &&
//         updatedContact.phoneNumber.isNotEmpty &&
//         updatedContact.email.isNotEmpty) {
//       await DatabaseHelper.instance.updateContact(updatedContact);
//       setState(() {
//         int index = contacts.indexWhere((contact) => contact.id == updatedContact.id);
//         if (index != -1) {
//           contacts[index] = updatedContact;
//         }
//       });
//     } else {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Name, phone number, and email are required.'),
//         ),
//       );
//     }
//   }
// }

  String _getInitials(String name) {
    List<String> nameSplit = name.split(' ');
    String initials = '';
    int numWords = nameSplit.length > 2 ? 2 : nameSplit.length;
    for (int i = 0; i < numWords; i++) {
      initials += nameSplit[i][0].toUpperCase();
    }
    return initials;
  }


}