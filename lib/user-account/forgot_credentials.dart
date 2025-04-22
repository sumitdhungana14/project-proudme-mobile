import 'package:flutter/material.dart';
import 'dart:convert' show jsonEncode;

import 'package:project_proud_me/language.dart';

class ForgetCredentialsScreen extends StatefulWidget {
  @override
  _ForgetCredentialsScreenState createState() =>
      _ForgetCredentialsScreenState();
}

class _ForgetCredentialsScreenState extends State<ForgetCredentialsScreen> {
  bool _resetPassword = true;
  final GlobalKey<FormState> _formKey = GlobalKey();

  Map<String, dynamic> formData = {
    'email': '',
  };

  void updateFormData(String field, dynamic value) {
    setState(() {
      formData[field] = value;
    });
  }

  void handleAction() {
    if (!_formKey.currentState!.validate()) {
      // Invalid!
      return;
    }
    _formKey.currentState!.save();

    String jsonData = jsonEncode(formData);
    print(jsonData);

    if (_resetPassword) {
      resetPassword();
    } else {
      recoverUsername();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: const Text(
          projectTitle,
          style: TextStyle(
            color: Color(0xfff5b342),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Form(
          key: _formKey,
          child: Column(
            // mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              const SizedBox(height: 20),
              const Text(
                'Forgot Your Username or Password?',
                style: TextStyle(
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              TextFormField(
                decoration: const InputDecoration(
                  labelText: 'Enter Email',
                ),
                onSaved: (value) => updateFormData('email', value),
                validator: (value) {
                  if (value == null || value.isEmpty || !value.contains('@')) {
                    return invalidorEmptyEmail;
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              Row(
                children: <Widget>[
                  Switch(
                    value: _resetPassword,
                    onChanged: (bool value) {
                      setState(() {
                        _resetPassword = value;
                      });
                    },
                  ),
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => const AlertDialog(
                          title: Text(recoverResetTitle),
                          content: Text(recoverDialogMessage),
                        ),
                      );
                    },
                    child: const Icon(Icons.info),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color>(
                    const Color(0xfff5b342),
                  ),
                ),
                onPressed: handleAction,
                child: _resetPassword
                    ? const Text('Reset Password',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        ))
                    : const Text('Recover Username',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                        )),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void resetPassword() {
    print('Reset Password');
  }

  void recoverUsername() {
    print('Recover Username');
  }
}
