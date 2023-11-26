import 'package:flutter/material.dart';
import 'package:iam_douaa/screens/login.dart'; // Utilisez la même casse que dans votre fichier

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Activity',
      theme: ThemeData(
        primarySwatch: Colors.cyan,
      ),
      home: const Login(),
      debugShowCheckedModeBanner: false,
    );
  }
}
