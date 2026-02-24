import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'inspector_dashboard.dart';

class InspectionsScreen extends StatelessWidget {
  const InspectionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Today\'s Inspections'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: const InspectorDashboard(),
    );
  }
}
