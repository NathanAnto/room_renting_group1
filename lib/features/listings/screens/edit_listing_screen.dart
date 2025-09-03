import 'package:flutter/material.dart';
import 'package:room_renting_group1/core/models/listing.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class EditListingScreen extends StatefulWidget {
  final Listing listing;

  const EditListingScreen({
    super.key,
    required this.listing,
  });

  @override
  State<EditListingScreen> createState() => _EditListingScreenState();
}

class _EditListingScreenState extends State<EditListingScreen> {
  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        title: const Text('Edit Listing'),
        backgroundColor: theme.colorScheme.background,
        elevation: 0,
        centerTitle: true,
      ),
      body: Center(
        child: Text('Editing: ${widget.listing.title}'),
      ),
    );
  }
}
