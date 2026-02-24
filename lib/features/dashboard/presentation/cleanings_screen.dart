import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'cleaner_dashboard.dart';

class CleaningsScreen extends StatelessWidget {
  const CleaningsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Cleanings'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: const CleanerDashboard(),
    );
  }
}
