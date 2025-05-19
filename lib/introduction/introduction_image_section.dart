import 'package:flutter/material.dart';
import 'package:project_proud_me/constant.dart';
import 'package:project_proud_me/language.dart';

class IntroductionImageSection extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return 
        AspectRatio(
          aspectRatio: 16 / 9,
          child: Stack(
            fit: StackFit.expand,
            children: [
              Image.asset(
                schoolKidsPicPath,
                fit: BoxFit.cover,
              ),
              const Align(
                alignment: Alignment.center,
                child: Text(
                  welcomeMessage,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    fontFamily: fontFamily,
                  ),
                ),
              ),
            ],
          ),
        );
  }
}
