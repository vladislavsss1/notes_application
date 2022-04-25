import 'package:flutter/material.dart';
import 'sql_helper.dart';

void main() {
  runApp(const MyApp());
}
class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        debugShowCheckedModeBanner: false,
        title: "Заметки",
        theme: ThemeData(
          primarySwatch: Colors.deepPurple,
        ),
        home: const HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  var checkDelete=0;
  // All notes
  List<Map<String, dynamic>> _notes = [];

  bool _isLoading = true;
  // This function is used to fetch all data from the database
  void _refreshNotes() async {
    final data = await SQLHelper.getItems();
    setState(() {
      _notes = data;
      _isLoading = false;
    });
    if(_notes.isEmpty&&checkDelete==0){
      await SQLHelper.createItem(
        "Test", "Test Note. Delete this, if you want.");
      _refreshNotes();
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshNotes(); // Loading the diary when the app starts
  }

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update an item
  void _showForm(int? id) async {
    if (id != null) {
      // id == null -> create new item
      // id != null -> update an existing item
      final existingNotes =
          _notes.firstWhere((element) => element['id'] == id);
      _titleController.text = existingNotes['title'];
      _descriptionController.text = existingNotes['description'];
    } else {
      _titleController.text = '';
      _descriptionController.text = '';
    }

    showModalBottomSheet(
        context: context,
        elevation: 5,
        isScrollControlled: true,
        builder: (_) => Container(
              padding: EdgeInsets.only(
                top: 15,
                left: 15,
                right: 15,
                // this will prevent the soft keyboard from covering the text fields
                bottom: MediaQuery.of(context).viewInsets.bottom + 120,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  TextField(
                    controller: _titleController,
                    decoration: const InputDecoration(hintText: 'Название'),
                  ),
                  const SizedBox(
                    height: 10,
                  ),
                  TextField(
                    controller: _descriptionController,
                    decoration: const InputDecoration(hintText: 'Текст'),
                  ),
                  const SizedBox(
                    height: 20,
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      // Save new note
                      if (id == null) {
                        await _addItem();
                      }

                      if (id != null) {
                        await _updateItem(id);
                      }

                      // Clear the text fields
                      _titleController.text = '';
                      _descriptionController.text = '';

                      // Close the bottom sheet
                      Navigator.of(context).pop();
                    },
                    child: Text(id == null ? 'Создать' : 'Обновить'),
                  )
                ],
              ),
            ));
  }

// Insert a new note to the database
  Future<void> _addItem() async {
    if(_titleController.text.isEmpty) {
      await SQLHelper.createItem(
        "Без названия", _descriptionController.text);
    } else {
      await SQLHelper.createItem(
          _titleController.text, _descriptionController.text);
    }
    _refreshNotes();
  }

  // Update an existing note
  Future<void> _updateItem(int id) async {
    if(_titleController.text.isEmpty) {
      await SQLHelper.updateItem(
        id, "Без названия", _descriptionController.text);
    } else {
      await SQLHelper.updateItem(
          id, _titleController.text, _descriptionController.text);
    }
    _refreshNotes();
  }

  // Delete an item
  void _deleteItem(int id) async {
    await SQLHelper.deleteItem(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Успешно удалено!'),
    ));
    checkDelete=1;
    _refreshNotes();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Заметки'),
        centerTitle: true,
        backgroundColor: Colors.black,
        actions: [
          IconButton(
              onPressed: () => _showForm(null), icon: Icon(Icons.add), alignment: Alignment.centerRight,padding: EdgeInsets.all(18.0),color: Colors.deepPurpleAccent,)
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(),
            )
          : ListView.builder(
              itemCount: _notes.length,
              itemBuilder: (context, index) => Card(
                color: Colors.purple[200],
                margin: const EdgeInsets.all(15),
                child: ListTile(
                    title: Text(_notes[index]['title']),
                    subtitle: Text(_notes[index]['description']),
                    trailing: SizedBox(
                      width: 176,
                      child: Row(
                        children: [
                          SizedBox(
                              child: Text((DateTime.parse(_notes[index]['createdAt']).day.toString().length==2?
                              DateTime.parse(_notes[index]['createdAt']).day.toString():
                              '0'+DateTime.parse(_notes[index]['createdAt']).day.toString()) +'.'
                                  + (DateTime.parse(_notes[index]['createdAt']).month.toString().length==2?
                              DateTime.parse(_notes[index]['createdAt']).month.toString():
                              '0'+DateTime.parse(_notes[index]['createdAt']).month.toString())),
                              width: 80,
                          ),
                          IconButton(
                            icon: const Icon(Icons.edit),
                            onPressed: () => _showForm(_notes[index]['id']),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            onPressed: () =>
                                _deleteItem(_notes[index]['id']),
                          ),
                        ],
                      ),
                    ),)
              ),
            ),
    );
  }
}