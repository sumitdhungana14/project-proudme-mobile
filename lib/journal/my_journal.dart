import 'package:appinio_swiper/appinio_swiper.dart'
    show AppinioSwiper, SwipeOptions, AppinioSwiperController;
import 'package:flutter/material.dart';
import 'package:project_proud_me/constant.dart';
import 'package:project_proud_me/introduction/introduction.dart';
import 'package:project_proud_me/journal/activity.dart';
import 'package:project_proud_me/journal/fruits_vegetables.dart';
import 'package:project_proud_me/journal/screen_time.dart';
import 'package:project_proud_me/journal/sleep.dart';
import 'package:project_proud_me/language.dart';
import 'package:project_proud_me/utils/helpers.dart';
import 'package:project_proud_me/widgets/app_drawer.dart';

class MyJournalScreen extends StatefulWidget {
  @override
  _MyJournalScreenState createState() => _MyJournalScreenState();
}

class _MyJournalScreenState extends State<MyJournalScreen> {
  final AppinioSwiperController swiperController = AppinioSwiperController();

  bool _isLoading = false;
  late String _userId;

  Future<void> _setUserId() async {
    setState(() {
      _isLoading = true;
    });
    var userId = await getUserId();
    setState(() {
      _userId = userId;
      _isLoading = false;
    });
  }

  @override
  void initState() {
    super.initState();
    _setUserId();
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Scaffold(
            appBar: AppBar(
              iconTheme: const IconThemeData(color: Color(0xfff5b342)),
              backgroundColor: Theme.of(context).primaryColor,
              title: const Text(
                projectTitle,
                style: TextStyle(
                  color: Color(0xfff5b342),
                  fontWeight: FontWeight.bold,
                  fontFamily: fontFamily,
                ),
              ),
              centerTitle: true,
              actions: [
                IconButton(
                  onPressed: () async {
                    setState(() {
                      _isLoading = true;
                    });

                    logout();

                    setState(() {
                      _isLoading = false;
                    });

                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Introduction()),
                    );
                  },
                  icon: const Icon(
                    Icons.logout,
                    color: Color(0xfff5b342),
                  ),
                ),
              ],
            ),
            drawer: MyDrawer(),
            body: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SizedBox(
                    height: MediaQuery.of(context).size.height * 0.90,
                    child: AppinioSwiper(
                      controller: swiperController,
                      backgroundCardCount: -1,
                      swipeOptions: const SwipeOptions.only(
                          up: false, down: false, right: true, left: true),
                      loop: true,
                      cardCount: 4,
                      cardBuilder: (BuildContext context, int index) {
                        switch (index) {
                          case 0:
                            return ActivityCard(userId: _userId, swipeLeft: () {
                              swiperController.setCardIndex(3);
                            },
                            swipeRight: () {
                              swiperController.setCardIndex(1);
                            },);
                          case 1:
                            return ScreenTimeCard(userId: _userId, swipeLeft: () {
                              swiperController.setCardIndex(0);
                            },
                            swipeRight: () {
                              swiperController.setCardIndex(2);
                            });
                          case 2:
                            return FruitsVegetablesCard(
                              userId: _userId,
                            );
                          case 3:
                            return SleepCard(
                              userId: _userId,
                            );
                          default:
                            throw Exception();
                        }
                      },
                    ),
                  ),
                ],
              ),
            ));
  }
}
