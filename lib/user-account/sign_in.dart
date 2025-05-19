import 'package:flutter/material.dart';
import 'dart:convert' show jsonEncode;
import 'package:http/http.dart' show post, get;
import 'package:project_proud_me/constant.dart';
import 'package:project_proud_me/endpoints.dart';
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
  bool _rememberMe = true;

  final FocusNode _emailFocusNode = FocusNode();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  List<String> _savedEmails = [];
  Map<String, String> _emailPasswordMap = {};
  List<String> _filteredEmails = [];

  void _loadSavedCredentials() async {
    var credentials = await SecureStorageUtil.getAllStoredData();
    setState(() {
      _emailPasswordMap = credentials;
      _savedEmails = credentials.keys.toList();
      _filteredEmails = List.from(_savedEmails);
    });
  }

  void _handleEmailFocusChange() {
    if (_emailFocusNode.hasFocus) {
      _showOverlay();
    } else {
      _removeOverlay();
    }
  }

  void _filterEmailList() {
    String input = _emailController.text.toLowerCase();
    setState(() {
      _filteredEmails = _savedEmails
          .where((email) => email.toLowerCase().contains(input))
          .toList();
    });
    _overlayEntry?.markNeedsBuild();
  }

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
  void initState() {
    super.initState();
    _emailFocusNode.addListener(_handleEmailFocusChange);
    _loadSavedCredentials();
    _emailFocusNode.addListener(() {
      if (!_emailFocusNode.hasFocus) {
        _removeOverlay();
      }
    });
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

  void _showOverlay() {
    if (!_emailFocusNode.hasFocus) return;
    _overlayEntry = _createOverlayEntry();
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _removeOverlay() {
    _overlayEntry!.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {

    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        width: MediaQuery.of(context).size.width - 40,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: const Offset(0.0, 56.0),
          child: Material(
            elevation: 4.0,
            child: ListView.builder(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _filteredEmails.length,
              itemBuilder: (context, index) {
                final username = _filteredEmails[index];
                return ListTile(
                  title: Text(username),
                  onTap: () {
                    _emailController.text = username;
                    _passwordController.text = _emailPasswordMap[username]!;
                    updateFormData('email', username);
                    updateFormData('password', _emailPasswordMap[username]!);
                    _emailFocusNode.unfocus();
                    FocusManager.instance.primaryFocus?.unfocus();
                    _removeOverlay();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );

    return _overlayEntry!;
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocusNode.dispose();
    _removeOverlay();
    super.dispose();
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
                child: CompositedTransformTarget(
                  link: _layerLink,
                  child: TextFormField(
                    controller: _emailController,
                    focusNode: _emailFocusNode,
                    onTap: () {
                      _filterEmailList();
                      _showOverlay();
                    },
                    onTapOutside: (event) => {FocusManager.instance.primaryFocus?.unfocus()},
                    decoration: const InputDecoration(
                      labelText: 'Username/Email',
                    ),
                    onChanged: (value) {
                      updateFormData('email', value);
                      _filterEmailList();
                    },
                  ),
                )
              ),
              const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: TextFormField(
                  controller: _passwordController,
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
