import 'package:flutter/material.dart';
import 'package:note/service/sql_helper.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(
          // This is the theme of your application.
          //
          // Try running your application with "flutter run". You'll see the
          // application has a blue toolbar. Then, without quitting the app, try
          // changing the primarySwatch below to Colors.green and then invoke
          // "hot reload" (press "r" in the console where you ran "flutter run",
          // or simply save your changes to "hot reload" in a Flutter IDE).
          // Notice that the counter didn't reset back to zero; the application
          // is not restarted.
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: Colors.white),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // All journals
  List<Map<String, dynamic>> _note = [];

  bool _isLoading = true;
  // This function is used to fetch all data from the database
  void _refreshJournals() async {
    if (_searchController.text.isNotEmpty) {
      final data = await SQLHelper.searchItem(_searchController.text);
      setState(() {
        _note = data;
        _isLoading = false;
      });
    } else {
      final data = await SQLHelper.getItems();
      setState(() {
        _note = data;
        _isLoading = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _refreshJournals(); // Loading the diary when the app starts
  }

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();

  // This function will be triggered when the floating button is pressed
  // It will also be triggered when you want to update an item
  void _showForm(int id) async {
    if (id != null) {
      // id == null -> create new item
      // id != null -> update an existing item
      final existingJournal =
          _note.firstWhere((element) => element['id'] == id);
      _titleController.text = existingJournal['title'];
      _descriptionController.text = existingJournal['description'];
    }

    showModalBottomSheet(
        context: context,
        elevation: 5,
        builder: (_) => Container(
              padding: const EdgeInsets.all(15),
              width: double.infinity,
              height: 300,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    TextField(
                      controller: _titleController,
                      decoration: const InputDecoration(hintText: 'Title'),
                    ),
                    const SizedBox(
                      height: 10,
                    ),
                    TextField(
                      controller: _descriptionController,
                      decoration:
                          const InputDecoration(hintText: 'Description'),
                    ),
                    const SizedBox(
                      height: 20,
                    ),
                    ElevatedButton(
                      onPressed: () async {
                        // Save new journal
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
                      child: Text(id == null ? 'Create New' : 'Update'),
                    )
                  ],
                ),
              ),
            ));
  }

// Insert a new journal to the database
  Future<void> _addItem() async {
    await SQLHelper.createItem(
        _titleController.text, _descriptionController.text);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Save Successcully')));
    _refreshJournals();
  }

// search item
  Future<void> _searchItem() async {
    await SQLHelper.searchItem(_titleController.text);
    _refreshJournals();
  }

  // Update an existing journal
  Future<void> _updateItem(int id) async {
    await SQLHelper.updateItem(
        id, _titleController.text, _descriptionController.text);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Update successfully')));
    _refreshJournals();
  }

  // Delete an item
  void _deleteItem(int id) async {
    await SQLHelper.deleteItem(id);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Successfully deleted a journal!'),
    ));
    _refreshJournals();
  }

  Future<void> _showMyDialog(int id) async {
    return showDialog<void>(
      context: context,
      barrierDismissible: true, // user must tap button!
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Delete'),
          content: SingleChildScrollView(
            child: ListBody(
              children: const <Widget>[
                // Text('This is a demo alert dialog.'),
                Text('Are You Sure to Delete This data'),
              ],
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Yes'),
              onPressed: () {
                _deleteItem(id);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Note'),
        actions: <Widget>[
          IconButton(
              onPressed: () {},
              icon: const Icon(Icons.refresh),
              tooltip: 'Show Snackbar')
        ],
        bottom: TabBar(tabs: [
          Tab(icon: Icon(Icons.directions_car)),
          Tab(icon: Icon(Icons.directions_transit)),
          Tab(icon: Icon(Icons.directions_bike)),
        ]),
      ),
      body: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              onChanged: (text) {
                _refreshJournals();
              },
              controller: _searchController,
              decoration: InputDecoration(
                  hintText: 'Cari catatan...',
                  suffixIcon:
                      IconButton(onPressed: () {}, icon: Icon(Icons.search))),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(),
                  )
                : ListView.builder(
                    itemCount: _note.length,
                    itemBuilder: (context, index) => Card(
                      color: Colors.white,
                      // margin: const EdgeInsets.all(10),
                      child: ListTile(
                        title: Text(_note[index]['title']),
                        subtitle: Text(_note[index]['description']),
                        trailing: SizedBox(
                          width: 100,
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit),
                                onPressed: () => _showForm(_note[index]['id']),
                              ),
                              IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () =>
                                      _showMyDialog(_note[index]['id'])),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: const Icon(Icons.add),
        onPressed: () => _showForm(null),
      ),
    );
  }
}
