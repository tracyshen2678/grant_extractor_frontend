import 'package:flutter/material.dart';
import 'pages/landing_page.dart';

void main() {
  runApp(const GrantReviewApp());
}

class GrantReviewApp extends StatelessWidget {
  const GrantReviewApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Grant Review App',
      theme: ThemeData(primarySwatch: Colors.blue),
      debugShowCheckedModeBanner: false,
      home: const LandingPage(),
    );
  }
}
