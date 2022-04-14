import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(HomeScreen());
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _ProjectListState createState() => _ProjectListState();
}

class FormScreen extends StatefulWidget {
  final QueryDocumentSnapshot project;

  const FormScreen(this.project, {Key? key}) : super(key: key);

  @override
  _ProjectFormState createState() => _ProjectFormState();
}

class _ProjectListState extends State<HomeScreen> {
  final textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    CollectionReference projects =
        FirebaseFirestore.instance.collection('projects');

    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: TextField(
            controller: textController,
            decoration: const InputDecoration(
              labelText: 'Insira um nome de projeto...',
            ),
          ),
        ),
        body: Center(
          child: StreamBuilder(
              stream: projects.orderBy('name').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: Text('Carregando...'));
                }
                var i = 0;
                return ListView(
                  padding: const EdgeInsets.all(8),
                  children: snapshot.data!.docs.map((project) {
                    i += 1;
                    return Container(
                      height: 50,
                      margin: const EdgeInsets.all(1.0),
                      color: i % 2 == 0 ? Colors.black26 : Colors.black38,
                      child: ListTile(
                        title: Text("$i - " + project['name'],
                            style: Theme.of(context)
                                .textTheme
                                .headline6!
                                .copyWith(color: Colors.white)),
                        onTap: () {
                          _navigateAndDisplaySelection(context, project);
                        },
                        onLongPress: () {
                          showAlertDialog(context, project);
                        },
                      ),
                    );
                  }).toList(),
                );
              }),
        ),
        floatingActionButton: FloatingActionButton(
          child: const Icon(Icons.save),
          onPressed: () {
            projects.add({'name': textController.text, 'description': ''});
            textController.clear();
          },
        ),
      ),
    );
  }

  showAlertDialog(BuildContext context, QueryDocumentSnapshot project) {
    // set up the buttons
    Widget cancelButton = TextButton(
      child: const Text("Cancelar"),
      onPressed: () {
        Navigator.of(context).pop();
      },
    );

    Widget continueButton = TextButton(
      child: const Text("Continuar"),
      onPressed: () {
        project.reference.delete();
        Navigator.of(context).pop();
      },
    );

    // set up the AlertDialog
    AlertDialog alert = AlertDialog(
      title: const Text("Confirme a exclusão"),
      content: const Text("Deseja realmente excluir o projeto?"),
      actions: [
        cancelButton,
        continueButton,
      ],
    );

    // show the dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return alert;
      },
    );
  }

  // A method that launches the SelectionScreen and awaits the result from
  // Navigator.pop.
  void _navigateAndDisplaySelection(
      BuildContext context, QueryDocumentSnapshot project) async {
    // Navigator.push returns a Future that completes after calling
    // Navigator.pop on the Selection Screen.
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => FormScreen(project)),
    );

    // After the Selection Screen returns a result, hide any previous snackbars
    // and show the new result.
    ScaffoldMessenger.of(context)
      ..removeCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('$result')));
  }
}

// Create a corresponding State class.
// This class holds data related to the form.
class _ProjectFormState extends State<FormScreen> {
  // Create a global key that uniquely identifies the Form widget
  // and allows validation of the form.
  //
  // Note: This is a GlobalKey<FormState>,
  // not a GlobalKey<MyCustomFormState>.
  final _formKey = GlobalKey<FormState>();

  final Map<String, String?> formData = {'name': '', 'description': ''};

  @override
  Widget build(BuildContext context) {
    // Build a Form widget using the _formKey created above.
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.project['name']),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Nome do projeto *',
                  hintText: 'Informe o nome do projeto',
                ),
                controller: TextEditingController(text: widget.project['name']),
                // The validator receives the text that the user has entered.
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Você deve informar o nome.';
                  }
                  formData['name'] = value;
                  return null;
                },
              ),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Descrição',
                ),
                controller:
                    TextEditingController(text: widget.project['description']),
                validator: (value) {
                  formData['description'] = value;
                  return null;
                },
              ),
              Center(
                child: ElevatedButton(
                  onPressed: () {
                    // Validate returns true if the form is valid, or false otherwise.
                    if (_formKey.currentState!.validate()) {
                      // If the form is valid, display a snackbar. In the real world,
                      // you'd often call a server or save the information in a database.
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Processando...')),
                      );

                      widget.project.reference.update(formData);
                      Navigator.of(context).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Dados salvos com sucesso!')),
                      );
                    }
                  },
                  child: const Text('Enviar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
