import 'package:flutter/material.dart';

import '../../../../core/format.dart';
import '../../domain/entities/note.dart';

class NoteTile extends StatelessWidget {
  const NoteTile({super.key, required this.note, this.onDelete, this.onTap});

  final Note note;
  final VoidCallback? onDelete;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      title: Text(note.title),
      subtitle: Text(formatUpdatedAt(note.updatedAt)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (note.dirty) const Chip(label: Text('belum tersinkron')),
          if (onDelete != null)
            IconButton(icon: const Icon(Icons.delete), onPressed: onDelete),
        ],
      ),
    );
  }
}
