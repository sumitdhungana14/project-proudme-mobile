import 'package:flutter/material.dart';
import 'dart:convert' show jsonEncode;
import 'package:http/http.dart' show post, get;
import 'package:project_proud_me/constant.dart';
import 'package:project_proud_me/endpoints.dart';
import 'package:project_proud_me/introduction/introduction.dart';
import 'package:project_proud_me/journal/my_journal.dart';
import 'package:project_proud_me/language.dart';
import 'package:project_proud_me/user-account/forgot_credentials.dart';
import 'package:project_proud_me/user-account/sign_up.dart';
import 'package:project_proud_me/user-account/sign_up_verification.dart';
import 'package:project_proud_me/utils/secure_storage.dart';
import 'package:project_proud_me/widgets/toast.dart';
import 'package:shared_preferences/shared_preferences.dart' show SharedPreferences;

class SignInScreen extends StatefulWidget {
  final bool redirectionFromVerificationScreen;

  SignInScreen({
    Key? key,
    required this.redirectionFromVerificationScreen,
  }) : super(key: key);

  @override
  _SignInScreenState createState() => _SignInScreenState();
}

class _SignInScreenState extends State<SignInScreen> {
  final Map<String, dynamic> _formData = {
    'email': '',
    'password': '',
  };

  bool _allFieldsFilled = false;
  bool _isLoading = false;
  bool _rememberMe = false;

  void updateFormData(String field, dynamic value) {
    setState(() {
      _formData[field] = value;

      _allFieldsFilled = _formData.values.every((element) => element != '');
    });
  }

  void resetForm() {
    String value = '';
    _formData.keys.forEach((element) => updateFormData(element, value));
  }

  void handleLogin() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String jsonData = jsonEncode(_formData);
      var response = await post(
        Uri.parse(login),
        body: jsonData,
        headers: baseHttpHeader,
      );

      if (response.statusCode == 200) {
        if (_rememberMe) {
          await SecureStorageUtil.storeNewKey(_formData['email'], _formData['password']);
        }

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(authTokenKey, response.body);
        
        var userResponse = await get(
            Uri.parse(users),
            headers: {
              'Authorization': 'Bearer ${response.body}',
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
      } else if (response.statusCode == 403) {
        String email = _formData['email'];
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => SignUpVerificationScreen(email: email)),
        );
      } else if (response.statusCode == 401) {
        showCustomToast(context, invalidCredentials, errorColor);
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.redirectionFromVerificationScreen) {
      showCustomToast(
        context, 
        userRegistrationSuccessful, 
        Theme.of(context).primaryColor
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: _isLoading ?
        const Center(
          child: CircularProgressIndicator(),
        ) :
        Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).primaryColor,
          title:const Text(
            projectTitle,
            style: TextStyle(
              color: Color(0xfff5b342),
              fontWeight: FontWeight.bold,
              fontFamily: fontFamily,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 20),
              Image.asset(mainLogoPath),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextFormField(
                  onTapOutside: (event) => {FocusManager.instance.primaryFocus?.unfocus()},
                  decoration: const InputDecoration(
                    labelText: 'Username/Email',
                  ),
                  onChanged: (value) => updateFormData('email', value),
                ),
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextFormField(
                  onTapOutside: (event) => {FocusManager.instance.primaryFocus?.unfocus()},
                  obscureText: true,
                  onChanged: (value) => updateFormData('password', value),
                  decoration: const InputDecoration(
                    labelText: 'Password',
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  children: [
                    Checkbox(
                      value: _rememberMe,
                      onChanged: (bool? value) {
                        setState(() {
                          _rememberMe = value!;
                        });
                      },
                    ),
                    const Text('Remember Me',
                      style: TextStyle(
                        fontFamily: fontFamily,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: _allFieldsFilled ? handleLogin : null,
                style: ButtonStyle(
                  backgroundColor: WidgetStateProperty.all<Color>(
                    const Color(0xfff5b342)
                  ),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(
                      fontFamily: fontFamily,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ),
              const SizedBox(height: 10),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => ForgetCredentialsScreen()),
                  );
                },
                child: const Text(
                    'Forgot your Username or Password?',
                    style: TextStyle(
                      fontFamily: fontFamily,
                    ),
                  ),
              ),
              const SizedBox(height: 10),
              const Text(
                "Don't have an account?",
                style: TextStyle(
                  fontFamily: fontFamily,
                ),
                ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => SignUpScreen()),
                  );
                },
                child: const Text(
                  'Register Here',
                  style: TextStyle(
                      fontFamily: fontFamily,
                    ),
                  ),
              ),
            ],
          ),
        ),
      ),
      debugShowCheckedModeBanner: false,

    );
  }
}
