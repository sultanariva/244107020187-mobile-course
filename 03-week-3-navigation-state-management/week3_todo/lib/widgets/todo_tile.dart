import 'package:flutter/material.dart';
import '../models/todo.dart';

class TodoTile extends StatelessWidget {
  const TodoTile({
    required this.todo,
    required this.onChanged,
    required this.onDeleted,
    super.key,
  });

  final Todo todo;
  final ValueChanged<bool?> onChanged;
  final VoidCallback onDeleted;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Checkbox(
        value: todo.done,
        onChanged: onChanged,
      ),
      title: Text(
        todo.title,
        style: TextStyle(
          decoration: todo.done ? TextDecoration.lineThrough : null,
        ),
      ),
      trailing: IconButton(
        icon: const Icon(Icons.delete),
        onPressed: onDeleted,
      ),
    );
  }
}