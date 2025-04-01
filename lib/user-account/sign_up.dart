import 'dart:async' show Timer;
import 'dart:convert' show json, jsonEncode;
import 'dart:math' show Random;
import 'package:flutter/material.dart';
import 'package:http/http.dart' show post, get;
import 'package:project_proud_me/constant.dart';
import 'package:project_proud_me/endpoints.dart';
import 'package:project_proud_me/introduction/introduction.dart';
import 'package:project_proud_me/journal/my_journal.dart';
import 'package:project_proud_me/language.dart';
import 'package:project_proud_me/user-account/sign_up_verification.dart';
import 'package:project_proud_me/widgets/toast.dart';
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;


class SignUpScreen extends StatefulWidget {
  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
final Map<String, dynamic> _formData = {
    'email': '',
    'password': '',
    'confirmPassword': '',
    'name': '',
    'firstName': '',
    'lastName': '',
    'schoolName': '',
    'birthMonth': '',
    'birthYear': '',
    'gradeLevel': '',
    'gender': '',
    'agreeToTerms': false,
    'agreeToAdUpdates': false,
  };

  bool _allFieldsFilled = false;
  bool _emailAlreadyExists = false;
  bool _usernameAlreadyExists = false;
  bool _isLoading = false;

  final GlobalKey<FormState> _formKey = GlobalKey();

  Timer? _debounce;

  String generateRandomString(int length) {
    final random = Random();
    return String.fromCharCodes(
      Iterable.generate(
        length, (_) => charSets.codeUnitAt(random.nextInt(charSets.length))
      )
    );
  }

  Future<void> updateFormData(String field, dynamic value) async {
    setState(() {
      _formData[field] = value;

      _allFieldsFilled = _formData.values.every((element) => element != '');
    });

    if (field == 'email' || field == 'name') {
      if (_debounce?.isActive ?? false) _debounce?.cancel();
        _debounce = Timer(const Duration(milliseconds: 500), () {
            checkForExistingEmailOrUsername(field, value);
        });
      }
  }

  void updateValidators(String field, bool value) {
    if (field == 'email') {
      setState(() {
        _emailAlreadyExists = value;
      });
    } else {
      setState(() {
        _usernameAlreadyExists = value;
      });
    }
  }

  Future<void> checkForExistingEmailOrUsername(String field, dynamic value) async {
    try {
        final response = await get(
          Uri.parse(
            '$user?email=$value'
          )
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);

          if (responseData != null) {
            updateValidators(field, true);
          } else {
            updateValidators(field, false);
          }
        } else {
          updateValidators(field, false);
        }
      } catch (e) {
        updateValidators(field, false);
      }
  }

  String getEmailParameters(String code) {
    Map<String, dynamic> emailParameters = {
      'subject': 'Project ProudMe Registration Confirmation.',
      'to': _formData['email'],
      'text': 'Hi ${_formData['name']},\n\nYou are receiving this email because you recently registered a new account on the Project ProudMe webpage. \n\nEnter the confirmation code listed to confirm your email account: ${code}\n\nBest Regards, \nProject ProudMe Team \nLouisiana State University \nPedagogical Kinesiology Lab\n\n---\nThis email was sent from an account associated with Louisiana State University.',
    };

    return jsonEncode(emailParameters);
  }

  void resetForm() {
    String value = '';
    for (var element in _formData.keys) {
      if (element != 'agreeToTerms' && element != 'agreeToAdUpdates') {
        setState(() {
          _formData[element] = value;

          _allFieldsFilled = false;
        });
      }
    }
  }

  void handleRegister(BuildContext context) {
    if (!_formKey.currentState!.validate()) {
      showCustomToast(context, fixErrorToastMessage, errorColor);

      return;
    }

    String jsonData = jsonEncode(_formData);

    registerUser(jsonData);
  }

  Future<void> registerUser(String jsonData) async {
    setState(() {
      _isLoading = true;
    });

    try {
      var response = await post(
        Uri.parse(register),
        body: jsonData,
        headers: baseHttpHeader,
      );

      if (response.statusCode == 200) {

        var loginResponse = await post(
        Uri.parse(login),
        body: jsonData,
        headers: baseHttpHeader,
      );

      if (loginResponse.statusCode == 200) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(authTokenKey, loginResponse.body);
        
        var userResponse = await get(
            Uri.parse(users),
            headers: {
              'Authorization': 'Bearer ${loginResponse.body}',
            },
          );

          if (userResponse.statusCode == 200) {
              await prefs.setString(userDataKey, userResponse.body);
            } else if (userResponse.statusCode == 401) {
              await prefs.remove(authTokenKey);
              await prefs.remove(userDataKey);
            }
          
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyJournalScreen()),
        );
      }
        
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => MyJournalScreen()),
        );
      } 
    } catch (e) {
      showCustomToast(context, e.toString(), errorColor);
    } finally {
      resetForm();
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading ?
      const Center(
        child: CircularProgressIndicator(),
      ) :
      Scaffold(
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
        body: SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Form(
              key: _formKey,
              child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                const SizedBox(height: 20),
                Image.asset(mainLogoPath),
                const SizedBox(height: 20),
                const Text(
                  thankYouMessage,
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 20.0),
                TextFormField(
                  onTapOutside: (event) => {FocusManager.instance.primaryFocus?.unfocus()},
                  decoration: const InputDecoration(labelText: 'Username'),
                  onChanged: (value) async => await updateFormData('name', value),
                  validator: (value) {
                        if (_usernameAlreadyExists) {
                          return usernameAlreadyExists;
                        }
                        return null;
                      },
                ),
                TextFormField(
                  onTapOutside: (event) => {FocusManager.instance.primaryFocus?.unfocus()},
                  decoration: const InputDecoration(labelText: 'Password'),
                  onChanged: (value) => updateFormData('password', value),
                  obscureText: true,
                ),
                TextFormField(
                  onTapOutside: (event) => {FocusManager.instance.primaryFocus?.unfocus()},
                  decoration: const InputDecoration(labelText: 'Confirm Password'),
                  onChanged: (value) => updateFormData('confirmPassword', value),
                  obscureText: true,
                  validator: (value) {
                        if (_formData['password'] != value) {
                          return passwordUnmatched;
                        }
                        return null;
                      },
                ),
                TextFormField(
                  onTapOutside: (event) => {FocusManager.instance.primaryFocus?.unfocus()},
                  decoration: const InputDecoration(labelText: 'First Name'),
                  onChanged: (value) => updateFormData('firstName', value),
                ),
                TextFormField(
                  onTapOutside: (event) => {FocusManager.instance.primaryFocus?.unfocus()},
                  decoration: const InputDecoration(labelText: 'Last Name'),
                  onChanged: (value) => updateFormData('lastName', value),
                ),
                TextFormField(
                  onTapOutside: (event) => {FocusManager.instance.primaryFocus?.unfocus()},
                  decoration: const InputDecoration(labelText: 'School Attending'),
                  onChanged: (value) => updateFormData('schoolName', value),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Birth Month'),
                  onChanged: (value) => updateFormData('birthMonth', value),
                  items: months.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                DropdownButtonFormField<int>(
                  decoration: const InputDecoration(labelText: 'Birth Year'),
                  onChanged: (value) => updateFormData('birthYear', value),
                  items: List.generate(
                    11,
                    (index) => DropdownMenuItem<int>(
                      value: 2008 + index,
                      child: Text((2008 + index).toString()),
                    ),
                  ),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Grade Level'),
                  onChanged: (value) => updateFormData('gradeLevel', value),
                  items: grades.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(labelText: 'Gender'),
                  onChanged: (value) => updateFormData('gender', value),
                  items: genders.map<DropdownMenuItem<String>>((String value) {
                    return DropdownMenuItem<String>(
                      value: value,
                      child: Text(value),
                    );
                  }).toList(),
                ),
                TextFormField(
                  onTapOutside: (event) => {FocusManager.instance.primaryFocus?.unfocus()},
                  decoration: const InputDecoration(labelText: 'Email Address'),
                  keyboardType: TextInputType.emailAddress,
                  onChanged: (value) => updateFormData('email', value),
                  validator: (value) {
                        if (!value!.contains('@')) {
                          return invalidEmail;
                        }
                        if (_emailAlreadyExists) {
                          return emailAlreadyExists;
                        }
                        return null;
                      },
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _formData['agreeToTerms'],
                      onChanged: (bool? value) {
                        updateFormData('agreeToTerms', value);
                      },
                    ),
                    const Text(serviceAgreement),
                  ],
                ),
                Row(
                  children: [
                    Checkbox(
                      value: _formData['agreeToAdUpdates'],
                      onChanged: (bool? value) {
                        updateFormData('agreeToAdUpdates', value);
                      },
                    ),
                    const Text(adsAgreement),
                  ],
                ),
                ElevatedButton(
                  onPressed: _allFieldsFilled ? () => handleRegister(context) : null,
                  style: ButtonStyle(
                    backgroundColor: WidgetStateProperty.all<Color>(
                    const Color(0xfff5b342),
                    ),
                  ),
                  child: const Text(
                    'Register',
                    style: TextStyle(
                      fontWeight: FontWeight.bold
                    )
                  ),
                ),
              ],
            ),
          ),
        )
    );
  }
}
