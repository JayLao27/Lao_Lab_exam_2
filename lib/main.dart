import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

// Connect to Firebase before the app starts.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Food List',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.orange, useMaterial3: true),
      home: const FoodListPage(),
    );
  }
}

class FoodListPage extends StatefulWidget {
  const FoodListPage({super.key});

  @override
  State<FoodListPage> createState() => _FoodListPageState();
}

class _FoodListPageState extends State<FoodListPage> {
  // Firestore collection that stores every food item.
  final CollectionReference foods =
      FirebaseFirestore.instance.collection('foods');

  final TextEditingController foodController = TextEditingController();

  // Shows a short message at the bottom of the screen.
  void showMessage(String text) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // CREATE: add a new food to Firestore.
  Future<void> addFood() async {
    final name = foodController.text.trim();

    // Validation: do not allow empty input.
    if (name.isEmpty) {
      showMessage('Please enter a food name.');
      return;
    }

    await foods.add({'name': name, 'createdAt': Timestamp.now()});
    foodController.clear();
    showMessage('Food added.');
  }

  // UPDATE: open a dialog to edit a food name.
  Future<void> editFood(String id, String currentName) async {
    final editController = TextEditingController(text: currentName);

    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Food'),
        content: TextField(
          controller: editController,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              final newName = editController.text.trim();

              // Validation: do not allow saving an empty name.
              if (newName.isEmpty) {
                showMessage('Food name cannot be empty.');
                return;
              }

              await foods.doc(id).update({'name': newName});
              if (dialogContext.mounted) Navigator.pop(dialogContext);
              showMessage('Food updated.');
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  // DELETE: remove a food from Firestore.
  Future<void> deleteFood(String id) async {
    await foods.doc(id).delete();
    showMessage('Food deleted.');
  }

  @override
  void dispose() {
    foodController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Food List'),
        centerTitle: true,
        backgroundColor: Colors.orange,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Input row: TextField + Add button.
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: foodController,
                    decoration: const InputDecoration(
                      labelText: 'Enter food',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => addFood(),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(onPressed: addFood, child: const Text('Add')),
              ],
            ),
            const SizedBox(height: 16),

            // READ: StreamBuilder listens to Firestore and updates automatically.
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: foods.orderBy('createdAt').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Something went wrong.'));
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final docs = snapshot.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('No food added yet.'));
                  }

                  return ListView.builder(
                    itemCount: docs.length,
                    itemBuilder: (context, index) {
                      final doc = docs[index];
                      final name = doc['name'] as String;

                      return Card(
                        child: ListTile(
                          title: Text(name),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => editFood(doc.id, name),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () => deleteFood(doc.id),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
