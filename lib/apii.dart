import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

void main() {
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late Future<List<Autogenerated>> futureData;

  @override
  void initState() {
    super.initState();
    futureData = fetchData();
  }

  Future<List<Autogenerated>> fetchData() async {
    final response =
        await http.get(Uri.parse('https://jsonplaceholder.typicode.com/posts'));

    if (response.statusCode == 200) {
      Iterable list = jsonDecode(response.body);
      return List<Autogenerated>.from(
          list.map((model) => Autogenerated.fromJson(model)));
    } else {
      throw Exception('Failed to load data');
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          backgroundColor: Color.fromARGB(255, 31, 177, 218),
          title: Text('API'),
        ),
        body: FutureBuilder<List<Autogenerated>>(
          future: futureData,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            } else {
              return ListView.builder(
                itemCount: 10,
                itemBuilder: (context, index) {
                  return Card(
                    margin: EdgeInsets.all(8.0),
                    child: ListTile(
                      title: Text(
                        snapshot.data![index].title ?? "N/A",
                        style: TextStyle(
                            color: const Color.fromARGB(221, 183, 99, 99),
                            fontStyle: FontStyle.italic,
                            fontSize: 20),
                      ),
                      subtitle: Text(snapshot.data![index].body ?? "N/A"),
                    ),
                  );
                },
              );
            }
          },
        ),
      ),
    );
  }
}

class Autogenerated {
  int? userId;
  int? id;
  String? title;
  String? body;

  Autogenerated({this.userId, this.id, this.title, this.body});

  factory Autogenerated.fromJson(Map<String, dynamic> json) {
    return Autogenerated(
      userId: json['userId'],
      id: json['id'],
      title: json['title'],
      body: json['body'],
    );
  }
}