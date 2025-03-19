import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart' show SvgPicture;
import 'package:flutter/services.dart'
    show TextInputFormatter, FilteringTextInputFormatter;
import 'package:http/http.dart' show get, post;
import 'package:project_proud_me/constant.dart';
import 'package:project_proud_me/endpoints.dart';
import 'package:project_proud_me/language.dart';
import 'package:project_proud_me/utils/helpers.dart';
import 'package:project_proud_me/widgets/toast.dart';

class FruitsVegetablesCard extends StatefulWidget {
  final String userId;
  final Function swipeLeft;
  final Function swipeRight;

  const FruitsVegetablesCard({required this.userId, required this.swipeLeft, required this.swipeRight});

  @override
  _FruitsVegetablesCardState createState() => _FruitsVegetablesCardState();
}

class _FruitsVegetablesCardState extends State<FruitsVegetablesCard>
    with SingleTickerProviderStateMixin {
    
    String _selectedEatType = '';
    List<String> _dependentItems = [];
    String _selectedEatCategory = '';

  late Map<String, TextEditingController> _goalControllers;
  late Map<String, TextEditingController> _behaviorControllers;

  TextEditingController _goalController = TextEditingController();
  TextEditingController _behaviorController = TextEditingController();
  final TextEditingController _reflectionController = TextEditingController();
  bool _isLoading = false;
  String _feedback = '';

  late Map<String, List<String>> eatMap;
  late Map<String, dynamic> _eats;
  List<String> _selectedValues = [];

  String calculateTotalGoal() {
    int total = 0;
    _goalControllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) {
        int value = int.tryParse(controller.text)!;
        total += value;
      }
    });

    return total.toString();
  }

  String calculateTotalBehavior() {
    int total = 0;

    _behaviorControllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) {
        int value = int.tryParse(controller.text)!;
        total += value;
      }
    });

    return total.toString();
  }

    void addNewEat(String? newActivity) {
    if (_selectedEatCategory != '' && !eatMap[_selectedEatCategory]!.contains(newActivity)) {
      _selectedEatType = newActivity!;
      eatMap[_selectedEatCategory]!.add(_selectedEatType);
      showCustomToast(context, 'New Activity has been added.', Theme.of(context).primaryColor);
      if (!_goalControllers.keys.contains(_selectedEatType)) {
        _goalControllers[newActivity] = TextEditingController();
        _goalControllers[newActivity]!.text = 0.toString();
        _goalControllers[newActivity] = TextEditingController();
        _goalControllers[newActivity]!.text = 0.toString();
        _behaviorControllers[newActivity] = TextEditingController();
        _behaviorControllers[newActivity]!.text = 0.toString();
        _behaviorControllers[newActivity] = TextEditingController();
        _behaviorControllers[newActivity]!.text = 0.toString();
      }
      setState(() {
        _goalController =_goalControllers[_selectedEatType]!;
        _goalController =_goalControllers[_selectedEatType]!;
        _behaviorController =_behaviorControllers[_selectedEatType]!;
        _behaviorController =_behaviorControllers[_selectedEatType]!;
        });
    }
  }

    void _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String queryString =
          getQueryParamsForGoalEndpoints(widget.userId, 'eating');

      final response = await get(Uri.parse('$getGoal?$queryString'));

      if (response.statusCode == 200) {
        List<dynamic> responseBody = json.decode(response.body);
        if (responseBody.isNotEmpty) {
          var activityData = responseBody.first as Map<String, dynamic>;
          _reflectionController.text = activityData['reflection'];      
          setState(() {
            _eats = activityData['servings'];
            _feedback = activityData['feedback'];
          });

          for (var category in _eats.entries) {
              if (category.value is Map<String, dynamic>) {
                for (var foodEntry in (category.value as Map<String, dynamic>).entries) {
                  var foodData = foodEntry.value;
                  if (foodData is Map<String, dynamic>) {
                    int goalValue = foodData["goal"] is int ? foodData["goal"] : 0;
                    int behaviorValue = foodData["behavior"] is int ? foodData["behavior"] : 0;

                    if (goalValue > 0 || behaviorValue > 0) {
                      setState(() {
                        _selectedValues.add(foodEntry.key);
                      });
                    }
                  }
                }
              }
            }
        } else {
          _eats = {};
          _feedback = '';
        }
      }
    } catch (e) {
      showCustomToast(context, e.toString(), errorColor);
      print(e);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    _initEatMap();
    _initGoalControllers();
    _initBehaviorControllers();
    _setControllers();
  }

  void save() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String totalGoal = calculateTotalGoal();
      String totalBehavior = calculateTotalBehavior();
      String chatPayload = getChatbotPayloadForEating(
          int.parse(totalGoal), int.parse(totalBehavior), _reflectionController.text);
      var chatResponse = await post(
        Uri.parse(getChatReply),
        body: chatPayload,
        headers: baseHttpHeader,
      );
      if (chatResponse.statusCode == 200) {
        String feedback = jsonDecode(chatResponse.body)['chat_reply'];
        setState(() {
          _feedback = feedback;
        });
        String jsonData = getEatingBehaviorPayload(
            _goalControllers,
            _behaviorControllers,
            widget.userId,
            _feedback,
            _reflectionController.text,
            totalGoal,
            totalBehavior,
            eatMap);
        var response = await post(
          Uri.parse(saveGoal),
          body: jsonData,
          headers: baseHttpHeader,
        );

        if (response.statusCode == 200 || response.statusCode == 201) {
          await post(
            Uri.parse(saveGoal),
            body: jsonData,
            headers: baseHttpHeader,
          );

          _fetchData();

          setState(() {
            _selectedEatType = '';
            _dependentItems = [];
          });

          showCustomToast(context, eatingSaved,
              Theme.of(context).primaryColor);
        } else if (response.statusCode == 400) {
          showCustomToast(
              context, eatingNotSaved, errorColor);
        }
      }
    } catch (e) {
      showCustomToast(context, e.toString(), errorColor);
    } finally {
      setState(() {
        _isLoading = false;
        _selectedEatType = '';
      });
    }
  }

  void _initGoalControllers() {
    _goalControllers = {};
    eatMap.values.forEach((eats) {
      eats.forEach((eat) {
        if (eat != addNewKey) {
          _goalControllers[eat] = TextEditingController();
          _goalControllers[eat]!.text = 0.toString();
        }
      });
    });
  }

  void _initBehaviorControllers() {
    _behaviorControllers = {};
    eatMap.values.forEach((eats) {
      eats.forEach((eat) {
        if (eat != addNewKey) {
          _behaviorControllers[eat] = TextEditingController();
          _behaviorControllers[eat]!.text = 0.toString();
        }
      });
    });
  }

  void incrementGoalServing() {
    setState(() {
      if (_selectedEatType != '') {
        if (_goalController.text.isEmpty) {
          _goalController.text = 1.toString();
        } else {
          _goalController.text =
              (int.parse(_goalController.text) + 1).toString();
        }
      }
    });
  }

  void incrementBehaviorServing() {
    setState(() {
      if (_selectedEatType != '') {
        if (_behaviorController.text.isEmpty) {
          _behaviorController.text = 1.toString();
        } else {
          _behaviorController.text =
              (int.parse(_behaviorController.text) + 1).toString();
        }
      }
    });
  }

  void decrementGoalServing() {
    setState(() {
      if (_selectedEatType != '') {
        if (_goalController.text.isNotEmpty &&
            int.parse(_goalController.text) > 0) {
          _goalController.text =
              (int.parse(_goalController.text) - 1).toString();
        }
      }
    });
  }

  void decrementBehaviorServing() {
    setState(() {
      if (_selectedEatType != '') {
        if (_behaviorController.text.isNotEmpty &&
            int.parse(_behaviorController.text) > 0) {
          _behaviorController.text =
              (int.parse(_behaviorController.text) - 1).toString();
        }
      }
    });
  }

    void _initEatMap() {
    eatMap =  Map<String, List<String>>.from(eatTypes);

    _eats.keys.forEach((key) {
      Map<String, dynamic> savedActivitiesForCurCategory = _eats[key];

      List<String> typesSavedToServer = savedActivitiesForCurCategory.keys.toList();
      List<String> locallySavedTypes = eatMap[key]!;

      for (var type in typesSavedToServer) {
        if (!locallySavedTypes.contains(type)) {
          locallySavedTypes.add(type);
        }
      }
    });
  }

    void _setControllers() {
    for (String key in eatMap.keys) {
      List<String> types = eatMap[key]!;

      for (String item in types) {
       if (_eats[key] != null && item != addNewKey) {
          _goalControllers[item]!.text = _eats[key][item]['goal'].toString();
          _behaviorControllers[item]!.text = _eats[key][item]!['behavior'].toString();
       }
      }
    }
  }

   void _showAddNewDialog() {
    TextEditingController newItemController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add New Item"),
          content: SizedBox(
            width: MediaQuery.of(context).size.width * 0.5,
            height: 100,
            child: Column(
              children: [
                TextField(
                  controller: newItemController,
                  decoration: const InputDecoration(hintText: "Enter new fruits or vegetables."),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                   _selectedEatType = eatMap[_selectedEatCategory]!.last;
                });
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                String newItem = newItemController.text.trim();
                if (newItem.isNotEmpty) {
                  addNewEat(newItem);
                  Navigator.pop(context);
                }
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.all<Color>(
                const Color(0xfff5b342)),
              ),
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isTablet = screenWidth > 600; 
    
    return _isLoading
        ? const Center(
            child: CircularProgressIndicator(),
          )
        : Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.5),
                  spreadRadius: 5,
                  blurRadius: 7,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Card(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                      flex: 10,
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Form(
                            child: Column(
                              children: [
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Visibility(
                                      visible: isTablet,
                                      child:
                                        TextButton.icon(
                                          onPressed: () {
                                            widget.swipeLeft();
                                          },
                                          icon: const Icon(Icons.arrow_left),
                                          label: Text(
                                            "Screen Time",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: Theme.of(context).primaryColor.withOpacity(0.9),
                                            ),
                                          ),
                                        )
                                      ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.05,
                                    ),
                                    SvgPicture.asset(
                                      appleIconPath,
                                      width: 20,
                                      height: 20,
                                      color: secondaryColor,
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      myJournalItems[2],
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        fontSize: 24,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: fontFamily,
                                        color: Theme.of(context).primaryColor,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    InkWell(
                                      onTap: () {
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: Text(
                                              myJournalItems[2],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            content: const Text(
                                              fruitsVegetablesInfo,
                                              style: TextStyle(
                                                fontSize: 20,
                                              ),
                                            ),
                                          ),
                                        );
                                      },
                                      child: const Icon(Icons.info),
                                    ),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.05,
                                    ),
                                     Visibility(
                                      visible: isTablet,
                                      child:
                                        TextButton(
                                          onPressed: () {
                                            widget.swipeRight();
                                          },
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                "Sleep",
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.w400,
                                                  color: Theme.of(context).primaryColor.withOpacity(0.9),
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              const Icon(Icons.arrow_right),
                                            ],
                                          ),
                                        )
                                      )
                                  ],
                                ),
                                const Divider(),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                      labelText: 'Select eating category.'),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedEatCategory = value!;
                                      _selectedEatType =
                                          eatMap[value]!.last;
                                      _dependentItems =
                                          eatMap[value] ?? [];
                                      _goalController = _goalControllers[_selectedEatType]!;
                                      _behaviorController = _behaviorControllers[_selectedEatType]!;
                                    });
                                  },
                                  items: eatMap.keys
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                ),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                      labelText: 'Select eating type.'),
                                  onChanged: (value) {
                                    _selectedEatType = value!;
                                    setState(() {
                                      if (_selectedEatType != addNewKey) {
                                        _goalController =
                                          _goalControllers[
                                              _selectedEatType]!;
                                      _behaviorController =
                                          _behaviorControllers[
                                              _selectedEatType]!;

                                      } else {
                                        _showAddNewDialog();
                                      }
                                    });
                                  },
                                  value: _selectedEatType,
                                  items: _dependentItems
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value,
                                      style: TextStyle(
                                        color: _selectedValues.contains(value) ? Colors.green : Colors.black,
                                        fontWeight: _selectedValues.contains(value) ? FontWeight.bold : FontWeight.normal,
                                      ),),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                 Visibility(
                                  visible: _selectedEatType.isEmpty,
                                  child: Text(
                                    'Select fruits/vegetables to set goals and track behavior.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: fontFamily,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                ),
                                Visibility(
                                  visible: _selectedEatType.isNotEmpty || _feedback.isNotEmpty,
                                  child: Container(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.center,
                                      children: [
                                        Text(
                                  'Set My Goal',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: fontFamily,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                Center(
                                    child: Container(
                                      width: MediaQuery.of(context).size.width * 0.5,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).primaryColor,
                                              borderRadius: BorderRadius.circular(24),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.remove),
                                              color: Colors.white,
                                              onPressed: () {
                                                decrementGoalServing();
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _goalController,
                                              decoration: const InputDecoration(
                                                  labelText: 'Servings/day'),
                                              keyboardType: TextInputType.number,
                                              inputFormatters: <TextInputFormatter>[
                                                FilteringTextInputFormatter.digitsOnly
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).primaryColor,
                                              borderRadius: BorderRadius.circular(24),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.add),
                                              color: Colors.white,
                                              onPressed: () {
                                                incrementGoalServing();
                                              },
                                            ),
                                          ),
                                        ],
                                      )
                                    )
                                  ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  'Total Goal: ${calculateTotalGoal()} Servings',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: fontFamily,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const Divider(),
                                const SizedBox(
                                  height: 15,
                                ),
                                Text(
                                  'Track My Behaviour',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: fontFamily,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                Center(
                                    child: Container(
                                      width: MediaQuery.of(context).size.width * 0.5,
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).primaryColor,
                                              borderRadius: BorderRadius.circular(24),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.remove),
                                              color: Colors.white,
                                              onPressed: () {
                                                decrementBehaviorServing();
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: TextFormField(
                                              controller: _behaviorController,
                                              decoration: const InputDecoration(
                                                  labelText: 'Servings/day'),
                                              keyboardType: TextInputType.number,
                                              inputFormatters: <TextInputFormatter>[
                                                FilteringTextInputFormatter.digitsOnly
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Container(
                                            decoration: BoxDecoration(
                                              color: Theme.of(context).primaryColor,
                                              borderRadius: BorderRadius.circular(24),
                                            ),
                                            child: IconButton(
                                              icon: const Icon(Icons.add),
                                              color: Colors.white,
                                              onPressed: () {
                                                incrementBehaviorServing();
                                              },
                                            ),
                                          ),
                                        ],
                                      )
                                    )
                                  ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  'Total Behavior: ${calculateTotalBehavior()} Servings',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: fontFamily,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const Divider(),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  'Reflect',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: fontFamily,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                TextFormField(
                                  controller: _reflectionController,
                                  keyboardType: TextInputType.multiline,
                                  maxLines: null,
                                  decoration: const InputDecoration(
                                      labelText: 'Type my thoughts'),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                Text(
                                  'AI-Generated Feedback',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: fontFamily,
                                    color: Theme.of(context).primaryColor,
                                  ),
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  _feedback,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontFamily: fontFamily,
                                  ),
                                ),
                                      ]))),
                              ],
                            ),
                          ),
                        ),
                      )),
                  Visibility(
                        visible: _selectedEatType.isNotEmpty || _feedback.isNotEmpty,
                        child: Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                const Divider(
                                  thickness: 1,
                                  color: Colors.black,
                                ),
                                const SizedBox(
                                  height: 5,
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    save();
                                  },
                                  style: ButtonStyle(
                                    backgroundColor: WidgetStateProperty.all<Color>(
                                        const Color(0xfff5b342)),
                                  ),
                                  child: const Text(
                                    'Save',
                                    style: TextStyle(
                                        fontFamily: fontFamily,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 18),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ),
                ],
              ),
            ));
  }
}
