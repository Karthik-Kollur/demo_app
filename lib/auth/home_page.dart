import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import '../helper/helper_function.dart';
import '../service/auth_service.dart';
import '../service/database_service.dart';
import 'login_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String userName = "";
  String email = "";
  AuthService authService = AuthService();

  @override
  void initState() {
    super.initState();
    gettingUserData();
  }

  gettingUserData() async {
    await HelperFunctions.getUserEmailFromSF().then((value) {
      setState(() {
        email = value!;
      });
    });
    await HelperFunctions.getUserNameFromSF().then((val) {
      setState(() {
        userName = val!;
      });
    });
    // getting the list of snapshots in our stream
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text("Pharmacy"),
        actions: [
          GestureDetector(
              onTap: () async {
                await authService.signOut();
                Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const LoginPage()),
                    (route) => false);
              },
              child: Icon(Icons.logout_outlined))
        ],
      ),
      body: Center(child: Text("home")),
    );
  }
}
