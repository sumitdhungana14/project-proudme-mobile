import 'package:flutter/material.dart';
import 'package:project_proud_me/constant.dart';
import 'package:url_launcher/url_launcher.dart' show launchUrl;

class IntroductionFooterWidget extends StatelessWidget {
  final String regularText;

  const IntroductionFooterWidget({
    Key? key,
    required this.regularText,
    }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              regularText,
              style: const TextStyle(
                fontSize: 25.0,
                fontFamily: fontFamily,
              ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Center(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    String mailUrl = 'mailto:senlinchen@lsu.edu';
                    try {
                      await _launchUrl(Uri.parse(mailUrl));
                    } catch (e) {
                      //Log error
                    }
                  },
                  icon: const Icon(Icons.email),
                  label: const Text('senlinchen@lsu.edu',  style: TextStyle(fontSize: 25),),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

Future<void> _launchUrl(Uri url) async {
  if (!await launchUrl(url)) {
    throw Exception('Could not launch $url');
  }
}
