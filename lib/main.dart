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
      theme: ThemeData(colorSchemeSeed: const Color(0xFF1B6A80), useMaterial3: true),
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

  // Checks if a food with the same name already exists (ignores upper/lower case).
  // [excludeId] skips the item being edited so it can keep its own name.
  Future<bool> isDuplicate(String name, {String? excludeId}) async {
    final snapshot = await foods.get();
    return snapshot.docs.any(
      (doc) =>
          doc.id != excludeId &&
          (doc['name'] as String).toLowerCase() == name.toLowerCase(),
    );
  }

  // CREATE: add a new food to Firestore.
  Future<void> addFood() async {
    final name = foodController.text.trim();

    // Validation: do not allow empty input.
    if (name.isEmpty) {
      showMessage('Please enter a food name.');
      return;
    }

    // Validation: do not allow duplicate names.
    if (await isDuplicate(name)) {
      showMessage('"$name" is already in the list.');
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

              // Validation: do not allow renaming to an existing name.
              if (await isDuplicate(newName, excludeId: id)) {
                showMessage('"$newName" is already in the list.');
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
      backgroundColor: const Color(0xFFFCFDFE),
      appBar: AppBar(
        title: const Text(
          'Labexam2_Lao',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w500),
        ),
        centerTitle: false,
        backgroundColor: const Color(0xFFFCFDFE),
        surfaceTintColor: Colors.transparent,
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
                    decoration: InputDecoration(
                      hintText: 'Add a new task...',
                      filled: true,
                      fillColor: const Color(0xFFEEF2F5),
                      hintStyle: const TextStyle(color: Colors.grey),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => addFood(),
                  ),
                ),
                const SizedBox(width: 12),
                // Add button (square, teal, "+" icon).
                SizedBox(
                  width: 52,
                  height: 52,
                  child: FilledButton(
                    onPressed: addFood,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1B6A80),
                      padding: EdgeInsets.zero,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Icon(Icons.add, color: Colors.white, size: 26),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // READ: StreamBuilder listens to Firestore and updates automatically.
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: foods.orderBy('createdAt').snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(child: Text('Something went wrong.'));
                  }
                  if (!snapshot.hasData) {
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

                      // Task card: light, rounded, soft shadow.
                      return Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF7FAFC),
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListTile(
                          title: Text(name, style: const TextStyle(fontSize: 14)),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  size: 20,
                                  color: Colors.grey,
                                ),
                                onPressed: () => editFood(doc.id, name),
                              ),
                              IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  size: 20,
                                  color: Colors.red,
                                ),
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
