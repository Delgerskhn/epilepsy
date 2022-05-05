import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:velocity_x/velocity_x.dart';

class RecordForm extends StatefulWidget {
  @override
  State<RecordForm> createState() => _RecordFormState();
}

class _RecordFormState extends State<RecordForm> {
  final _formKey = GlobalKey<FormState>();
  String? symptom;
  List<String> selected = [];
  bool isLoading = false;
  List<String> symptoms = [];
  @override
  void initState() {
    super.initState();
    _initState();
    _syncRemoteSymptoms();
  }

  void _initState() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      symptoms = prefs.getStringList('symptoms') ?? [];
    });
  }

  void _syncRemoteSymptoms() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    var data = await firestore.collection('symptoms').get();
    var symptomLabels = data.docs.map((element) {
      return (element['label'] as String);
    }).toList();
    final prefs = await SharedPreferences.getInstance();
    prefs.setStringList('symptoms', symptomLabels);
    setState(() {
      symptoms = symptomLabels;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: VStack([
        Wrap(children: [
          ...symptoms.map((r) => TextButton(
                onPressed: () {
                  setState(() {
                    if (selected.contains(r)) {
                      selected.remove(r);
                    } else {
                      selected.add(r);
                    }
                  });
                },
                child: Chip(
                  label: Text(
                    r,
                    style: TextStyle(
                        color:
                            selected.contains(r) ? Colors.white : Colors.black),
                  ),
                  backgroundColor: selected.contains(r)
                      ? Theme.of(context).colorScheme.primary
                      : null,
                ),
                style: ButtonStyle(
                    padding: MaterialStateProperty.all<EdgeInsetsGeometry>(
                        EdgeInsets.all(3))),
              ))
        ]),
        ElevatedButton(
          onPressed: () async {
            if (selected.isEmpty) {
              return VxToast.show(context,
                  msg: 'Шинж тэмдэг сонгоно уу?', bgColor: Colors.yellow[800]);
            }
            // Validate returns true if the form is valid, or false otherwise.
            if (_formKey.currentState!.validate()) {
              // If the form is valid, display a snackbar. In the real world,
              // you'd often call a server or save the information in a database.
              FirebaseFirestore firestore = FirebaseFirestore.instance;
              var entity = firestore.collection('data');
              setState(() {
                isLoading = true;
              });
              for (var element in selected) {
                await entity.add({'date': DateTime.now(), 'symptom': element});
              }
              setState(() {
                isLoading = false;
                selected = [];
              });
              VxToast.show(context,
                  msg: 'Амжилттай!',
                  bgColor: Theme.of(context).colorScheme.primary,
                  textColor: Colors.white);
            }
          },
          child: isLoading
              ? CircularProgressIndicator(color: Colors.white)
              : Text('Submit'),
        ),
      ]),
    );
  }
}
