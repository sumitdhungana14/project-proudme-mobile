import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' show post;
import 'package:project_proud_me/constant.dart';
import 'package:project_proud_me/endpoints.dart';
import 'package:project_proud_me/language.dart';
import 'package:project_proud_me/user-account/sign_in.dart';
import 'package:project_proud_me/widgets/toast.dart';

class SignUpVerificationScreen extends StatefulWidget {
  final String email;

  SignUpVerificationScreen({
    Key? key,
    required this.email,
  }) : super(key: key);

  @override
  _SignUpVerificationScreenState createState() =>
      _SignUpVerificationScreenState();
}

class _SignUpVerificationScreenState extends State<SignUpVerificationScreen> {
  final Map<String, dynamic> _formData = {
    'code': '',
  };

  bool _allFieldsFilled = false;
  bool _isLoading = false;

  void updateFormData(String field, dynamic value) {
    setState(() {
      _formData[field] = value;
      _allFieldsFilled = _formData.values.every((element) => element != '');
    });
  }

  void sendCode() async {
    setState(() {
      _isLoading = true;
    });

    Map<String, dynamic> payload = {
      'email': widget.email,
    };

    String jsonData = jsonEncode(payload);

    try {
      var response = await post(
        Uri.parse(sendVerificationCode),
        body: jsonData,
        headers: baseHttpHeader,
      );

      int code = response.statusCode;

      if (code == 200) {
        showCustomToast(context, emailSentMessage, Theme.of(context).primaryColor);
      } else if (code == 400 || code == 500) {
        showCustomToast(context, verificationCodeNotSent, errorColor);
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

  void handleVerify() async {
    setState(() {
      _isLoading = true;
      _formData['email'] = widget.email;
    });

    String jsonData = jsonEncode(_formData);

    try {
      var response = await post(
        Uri.parse(verifyUser),
        body: jsonData,
        headers: baseHttpHeader,
      );

      int code = response.statusCode;
      print(code);

      if (code == 200) {
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => SignInScreen(
                    redirectionFromVerificationScreen: true,
                  )),
        );
      } else if (code == 400 || code == 500) {
        showCustomToast(context, userRegistrationUnsuccessful, errorColor);
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

  void resetForm() {
    String value = '';
    _formData.keys.forEach((element) => updateFormData(element, value));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    showCustomToast(context, emailSentMessage, Theme.of(context).primaryColor);
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Scaffold(
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
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    confirmationPromptMessage,
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    decoration: const InputDecoration(
                      labelText: 'Confirmation Code',
                    ),
                    onChanged: (value) => updateFormData('code', value),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _allFieldsFilled ? handleVerify : null,
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(
                          const Color(0xfff5b342)),
                    ),
                    child: const Text('Verify',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () {
                      sendCode();
                    },
                    child: const Text(
                      resendCodeButtonText,
                      style: TextStyle(
                        fontFamily: fontFamily,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
  }
}
