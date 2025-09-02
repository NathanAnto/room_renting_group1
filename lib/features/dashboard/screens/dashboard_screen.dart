import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Dashboard', style: TextStyle(fontSize: 20)),
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: const Center(
        child: Text(''),
      ),
    );
  }
}