import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show TextInputFormatter, FilteringTextInputFormatter;
import 'package:http/http.dart';
import 'package:project_proud_me/constant.dart';
import 'package:project_proud_me/endpoints.dart';
import 'package:project_proud_me/language.dart';
import 'package:project_proud_me/utils/helpers.dart';
import 'package:project_proud_me/widgets/toast.dart';
import 'dart:async' show Timer;

class ScreenTimeCard extends StatefulWidget {
  final String userId;

  final Function swipeLeft;
  final Function swipeRight;

  const ScreenTimeCard({required this.userId, required this.swipeRight, required this.swipeLeft});

  @override
  _ScreenTimeCardState createState() => _ScreenTimeCardState();
}

class _ScreenTimeCardState extends State<ScreenTimeCard> {
  /*TODO: Refactor the Goal/Behavior form into a separate widget
    for better performance, use the widget on all journal behavior
    items.
  */
  Timer? _debounce;

  List<String> _dependentItems = [];
  String _selectedScreenTimeCategory = '';
  String _selectedScreenTimeType = '';

  late Map<String, TextEditingController> _goalHourControllers;
  late Map<String, TextEditingController> _goalMinuteControllers;
  TextEditingController _goalHourController = TextEditingController();
  TextEditingController _goalMinuteController = TextEditingController();

  late Map<String, TextEditingController> _behaviorHourControllers;
  late Map<String, TextEditingController> _behaviorMinuteControllers;
  TextEditingController _behaviorHourController = TextEditingController();
  TextEditingController _behaviorMinuteController = TextEditingController();

  TextEditingController _reflectionController = TextEditingController();
  bool _isLoading = false;
  String _feedback = '';

  late Map<String, List<String>> screenTimeMap;
  late Map<String, dynamic> _screentimes;
  List<String> _selectedValues = [];

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String queryString =
          getQueryParamsForGoalEndpoints(widget.userId, 'screentime');

      final response = await get(Uri.parse('$getGoal?$queryString'));

      if (response.statusCode == 200) {
        List<dynamic> responseBody = json.decode(response.body);
        if (responseBody.isNotEmpty) {
          var screenTimeData = responseBody.first as Map<String, dynamic>;
          _reflectionController.text = screenTimeData['reflection'];
          setState(() {
            _screentimes = screenTimeData['screentime'];
            _feedback = screenTimeData['feedback'];
          });

          _selectedValues = [];

          for (var category in _screentimes.entries) { 
            if (category.value is Map<String, dynamic>) {
              for (var screenEntry in (category.value as Map<String, dynamic>).entries) {
                var screenData = screenEntry.value;

                if (screenData is Map<String, dynamic> &&
                    screenData.containsKey("goal") &&
                    screenData.containsKey("behavior")) {

                  int goalHours = (screenData["goal"]["hours"] is int) ? screenData["goal"]["hours"] : 0;
                  int goalMinutes = (screenData["goal"]["minutes"] is int) ? screenData["goal"]["minutes"] : 0;
                  int behaviorHours = (screenData["behavior"]["hours"] is int) ? screenData["behavior"]["hours"] : 0;
                  int behaviorMinutes = (screenData["behavior"]["minutes"] is int) ? screenData["behavior"]["minutes"] : 0;

                  if (goalHours > 0 || goalMinutes > 0 || behaviorHours > 0 || behaviorMinutes > 0) {
                    setState(() {
                      _selectedValues.add(screenEntry.key);
                    });
                  }
                }
              }
            }
          }
        } else {
          setState(() {
            _screentimes = {};
            _feedback = '';
          });
        }
      }
    } catch (e) {
      showCustomToast(context, e.toString(), errorColor);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }

    _initScreenTimeMap();
    _initGoalHourControllers();
    _initGoalMinuteControllers();
    _initBehaviorHourControllers();
    _initBehaviorMinuteControllers();
    _setControllers();
  }

  void onSave(bool autosave) async {
    try {
      if (!autosave) {
        setState(() {
          _isLoading = true;
        });
        String chatPayload = getChatbotPayloadFor(
          int.parse(calculateTotalGoal()),
          int.parse(calculateTotalBehavior()),
          _reflectionController.text,
          'Screen Time',
          recommendedScreenTimeValue);
        var chatResponse = await post(
          Uri.parse(getChatReplyForScreentime),
          body: chatPayload,
          headers: baseHttpHeader,
        );
        if (chatResponse.statusCode == 200) {
          String feedback = jsonDecode(chatResponse.body)['chat_reply'];
          setState(() {
            _feedback = feedback;
          });
          saveBehavior(autosave);
        }
      } else {
        saveBehavior(autosave);
      }

    } catch (e) {
      showCustomToast(context, e.toString(), errorColor);
    } finally {
      setState(() {
        _isLoading = false;
        if (!autosave) {
          _dependentItems = [];
          _selectedScreenTimeType = '';          
        }
      });
    }
  }

  String calculateTotalGoal() {
    int total = 0;

    _goalHourControllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) {
        int value = int.tryParse(controller.text)! * 60;
        total += value;
      }
    });

    _goalMinuteControllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) {
        int value = int.tryParse(controller.text)!;
        total += value;
      }
    });

    return total.toString();
  }

  String calculateTotalBehavior() {
    int total = 0;

    _behaviorHourControllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) {
        int value = int.tryParse(controller.text)! * 60;
        total += value;
      }
    });

    _behaviorMinuteControllers.forEach((key, controller) {
      if (controller.text.isNotEmpty) {
        int value = int.tryParse(controller.text)!;
        total += value;
      }
    });

    return total.toString();
  }

  void incrementGoalHour() {
    setState(() {
      if (_selectedScreenTimeType != '') {
        if (_goalHourControllers[_selectedScreenTimeType]!.text.isEmpty) {
          _goalHourControllers[_selectedScreenTimeType]!.text = 1.toString();
        } else {
          _goalHourControllers[_selectedScreenTimeType]!.text =
              (int.parse(_goalHourControllers[_selectedScreenTimeType]!.text) +
                      1)
                  .toString();
        }

      textFieldOnChange(_goalHourController.text);
      }
    });
  }

  void incrementBehaviorHour() {
    setState(() {
      if (_selectedScreenTimeType != '') {
        if (_behaviorHourControllers[_selectedScreenTimeType]!.text.isEmpty) {
          _behaviorHourControllers[_selectedScreenTimeType]!.text =
              1.toString();
        } else {
          _behaviorHourControllers[_selectedScreenTimeType]!.text = (int.parse(
                      _behaviorHourControllers[_selectedScreenTimeType]!.text) +
                  1)
              .toString();
        }
      
      textFieldOnChange(_behaviorHourController.text);
      }
    });

  }

  void incrementGoalMinute() {
    setState(() {
      if (_selectedScreenTimeType != '') {
        if (_goalMinuteControllers[_selectedScreenTimeType]!.text.isEmpty) {
          _goalMinuteControllers[_selectedScreenTimeType]!.text = 15.toString();
        } else {
          _goalMinuteControllers[_selectedScreenTimeType]!.text = (int.parse(
                      _goalMinuteControllers[_selectedScreenTimeType]!.text) +
                  15)
              .toString();
        }

      textFieldOnChange(_goalMinuteController.text);
      }
    });
  }

  void incrementBehaviorMinute() {
    setState(() {
      if (_selectedScreenTimeType != '') {
        if (_behaviorMinuteControllers[_selectedScreenTimeType]!.text.isEmpty) {
          _behaviorMinuteControllers[_selectedScreenTimeType]!.text =
              15.toString();
        } else {
          _behaviorMinuteControllers[_selectedScreenTimeType]!.text =
              (int.parse(_behaviorMinuteControllers[_selectedScreenTimeType]!
                          .text) +
                      15)
                  .toString();
        }
      
      textFieldOnChange(_behaviorMinuteController.text);
      }
    });
  }

  void decrementGoalHour() {
    setState(() {
      if (_selectedScreenTimeType != '') {
        if (_goalHourControllers[_selectedScreenTimeType]!.text.isNotEmpty &&
            int.parse(_goalHourControllers[_selectedScreenTimeType]!.text) >
                0) {
          _goalHourControllers[_selectedScreenTimeType]!.text =
              (int.parse(_goalHourControllers[_selectedScreenTimeType]!.text) -
                      1)
                  .toString();
        }

      textFieldOnChange(_goalHourController.text);
      }
    });
  }

  void decrementBehaviorHour() {
    setState(() {
      if (_selectedScreenTimeType != '') {
        if (_behaviorHourControllers[_selectedScreenTimeType]!
                .text
                .isNotEmpty &&
            int.parse(_behaviorHourControllers[_selectedScreenTimeType]!.text) >
                0) {
          _behaviorHourControllers[_selectedScreenTimeType]!.text = (int.parse(
                      _behaviorHourControllers[_selectedScreenTimeType]!.text) -
                  1)
              .toString();
        }
      
      textFieldOnChange(_behaviorHourController.text);
      }
    });
  }

  void decrementGoalMinute() {
    setState(() {
      if (_selectedScreenTimeType != '') {
        if (_goalMinuteControllers[_selectedScreenTimeType]!.text.isNotEmpty &&
            int.parse(_goalMinuteControllers[_selectedScreenTimeType]!.text) >=
                15) {
          _goalMinuteControllers[_selectedScreenTimeType]!.text = (int.parse(
                      _goalMinuteControllers[_selectedScreenTimeType]!.text) -
                  15)
              .toString();
        }

      textFieldOnChange(_goalMinuteController.text);
      }
    });
  }

  void decrementBehaviorMinute() {
    setState(() {
      if (_selectedScreenTimeType != '') {
        if (_behaviorMinuteControllers[_selectedScreenTimeType]!
                .text
                .isNotEmpty &&
            int.parse(
                    _behaviorMinuteControllers[_selectedScreenTimeType]!.text) >=
                15) {
          _behaviorMinuteControllers[_selectedScreenTimeType]!.text =
              (int.parse(_behaviorMinuteControllers[_selectedScreenTimeType]!
                          .text) -
                      15)
                  .toString();
        }

      textFieldOnChange(_behaviorMinuteController.text);
      }
    });
  }

  void addNewScreenTime(String? newScreenTime) {
    if (_selectedScreenTimeCategory != '' && !screenTimeMap[_selectedScreenTimeCategory]!.contains(newScreenTime)) {
      _selectedScreenTimeType = newScreenTime!;
      screenTimeMap[_selectedScreenTimeCategory]!.add(_selectedScreenTimeType);
      showCustomToast(context, 'New Screen Time has been added.', Theme.of(context).primaryColor);
      if (!_goalHourControllers.keys.contains(_selectedScreenTimeType)) {
        _goalHourControllers[newScreenTime] = TextEditingController();
        _goalHourControllers[newScreenTime]!.text = 0.toString();
        _goalMinuteControllers[newScreenTime] = TextEditingController();
        _goalMinuteControllers[newScreenTime]!.text = 0.toString();
        _behaviorHourControllers[newScreenTime] = TextEditingController();
        _behaviorHourControllers[newScreenTime]!.text = 0.toString();
        _behaviorMinuteControllers[newScreenTime] = TextEditingController();
        _behaviorMinuteControllers[newScreenTime]!.text = 0.toString();
      }
      setState(() {
        _goalHourController =_goalHourControllers[_selectedScreenTimeType]!;
        _goalMinuteController =_goalMinuteControllers[_selectedScreenTimeType]!;
        _behaviorHourController =_behaviorHourControllers[_selectedScreenTimeType]!;
        _behaviorMinuteController =_behaviorMinuteControllers[_selectedScreenTimeType]!;
        });
    }
  }

  void _initScreenTimeMap() {
    screenTimeMap =  Map<String, List<String>>.from(screenTimeTypes);

    _screentimes.keys.forEach((key) {
      Map<String, dynamic> savedActivitiesForCurCategory = _screentimes[key];

      List<String> typesSavedToServer = savedActivitiesForCurCategory.keys.toList();
      List<String> locallySavedTypes = screenTimeMap[key]!;

      for (var type in typesSavedToServer) {
        if (!locallySavedTypes.contains(type)) {
          locallySavedTypes.add(type);
        }
      }
    });
  }


  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> autosave() async {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 2000), () {
        onSave(true);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _initGoalHourControllers() {
    _goalHourControllers = {};
    screenTimeMap.values.forEach((screentimes) {
      screentimes.forEach((type) {
        if (type != addNewKey) {
          _goalHourControllers[type] = TextEditingController();
          _goalHourControllers[type]!.text = 0.toString();
        }
      });
    });
  }

  void _initGoalMinuteControllers() {
    _goalMinuteControllers = {};
     screenTimeMap.values.forEach((screentimes) {
      screentimes.forEach((type) {
        if (type != addNewKey) {
          _goalMinuteControllers[type] = TextEditingController();
          _goalMinuteControllers[type]!.text = 0.toString();
        }
      });
    });
  }

  void _initBehaviorHourControllers() {
    _behaviorHourControllers = {};
    screenTimeMap.values.forEach((screentimes) {
      screentimes.forEach((type) {
        if (type != addNewKey) {
          _behaviorHourControllers[type] = TextEditingController();
          _behaviorHourControllers[type]!.text = 0.toString();
        }
      });
    });
  }

  void _initBehaviorMinuteControllers() {
    _behaviorMinuteControllers = {};
    screenTimeMap.values.forEach((screentimes) {
      screentimes.forEach((type) {
        if (type != addNewKey) {
          _behaviorMinuteControllers[type] = TextEditingController();
          _behaviorMinuteControllers[type]!.text = 0.toString();
        }
      });
    });
  }

  void _setControllers() {
    for (String key in screenTimeMap.keys) {
      List<String> types = screenTimeMap[key]!;

      for (String item in types) {
       if (_screentimes[key] != null && item != addNewKey) {
          _goalHourControllers[item]!.text = _screentimes[key][item]['goal']['hours'].toString();
          _goalMinuteControllers[item]!.text = _screentimes[key][item]!['goal']['minutes'].toString();
          _behaviorHourControllers[item]!.text = _screentimes[key][item]!['behavior']['hours'].toString();
          _behaviorMinuteControllers[item]!.text = _screentimes[key][item]!['behavior']['minutes'].toString();
       }
      }
    }
  }

  void textFieldOnChange(String value) {
    if (value != '') {
      if (int.parse(_goalHourController.text) == 0 && int.parse(_goalMinuteController.text) == 0 &&
          int.parse(_behaviorHourController.text) == 0 && int.parse(_behaviorMinuteController.text) == 0) {
      setState(() {
        _selectedValues.remove(_selectedScreenTimeType);
      });
    } else if(int.parse(_goalHourController.text) > 0 || int.parse(_goalMinuteController.text) > 0 ||
        int.parse(_behaviorHourController.text) > 0 || int.parse(_behaviorMinuteController.text) > 0) {
      if (!_selectedValues.contains(_selectedScreenTimeType)) {
        setState(() {
          _selectedValues.add(_selectedScreenTimeType);
        });
      }
    }

     autosave();
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
                  decoration: const InputDecoration(hintText: "Enter new screen time."),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                   _selectedScreenTimeType = screenTimeMap[_selectedScreenTimeCategory]!.last;
                });
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                String newItem = newItemController.text.trim();
                if (newItem.isNotEmpty) {
                  addNewScreenTime(newItem);
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

  void saveBehavior(bool autosave) async {

    String jsonData = getScreenTimeBehaviorPayload(
            _goalHourControllers,
            _goalMinuteControllers,
            _behaviorHourControllers,
            _behaviorMinuteControllers,
            widget.userId,
            _feedback,
            _reflectionController.text,
            calculateTotalGoal(),
            calculateTotalBehavior(),
            screenTimeMap);
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

          if (!autosave) {
            _fetchData();
          }

          showCustomToast(context, 'Screen time has been saved successfully.',
              Theme.of(context).primaryColor);
        } else if (response.statusCode == 400) {
          showCustomToast(
              context, 'Screen time couldn\'t be saved.', errorColor);
        }
  }

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isTablet = screenWidth > 600; 

    return _isLoading
        ? const Center(child: CircularProgressIndicator())
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
                                            "Physical Activity",
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w400,
                                              color: Theme.of(context).primaryColor.withOpacity(0.9),
                                            ),
                                          ),
                                        )),
                                    SizedBox(
                                      width: MediaQuery.of(context).size.width * 0.05,
                                    ),
                                    const Icon(
                                      Icons.desktop_windows_outlined,
                                      color: secondaryColor,
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      myJournalItems[1],
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
                                              myJournalItems[1],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            content: const Text(
                                              screenTimeInfo,
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
                                                "Fruits & Vegetables",
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
                                Text(
                                    'Set goals and track your behavior for yesterday (${getYesterdaysDate('d/M/y')})',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: fontFamily,
                                      color: Theme.of(context).primaryColor,
                                    ),
                                ),
                                const Divider(),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                      labelText: 'Select screen time category.'),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedScreenTimeCategory = value!;
                                      _selectedScreenTimeType =
                                          screenTimeMap[value!]!.last;
                                      _dependentItems =
                                          screenTimeMap[value!] ?? [];
                                      _goalHourController =
                                          _goalHourControllers[
                                              _selectedScreenTimeType]!;
                                      _goalMinuteController =
                                          _goalMinuteControllers[
                                              _selectedScreenTimeType]!;
                                      _behaviorHourController =
                                          _behaviorHourControllers[
                                              _selectedScreenTimeType]!;
                                      _behaviorMinuteController =
                                          _behaviorMinuteControllers[
                                              _selectedScreenTimeType]!;
                                    });
                                  },
                                  items: screenTimeMap.keys
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
                                      labelText: 'Select screen time type.'),
                                  onChanged: (value) {
                                    _selectedScreenTimeType = value!;
                                    setState(() {
                                      if (_selectedScreenTimeType != addNewKey) {
                                        _goalHourController =
                                          _goalHourControllers[
                                              _selectedScreenTimeType]!;
                                      _goalMinuteController =
                                          _goalMinuteControllers[
                                              _selectedScreenTimeType]!;
                                      _behaviorHourController =
                                          _behaviorHourControllers[
                                              _selectedScreenTimeType]!;
                                      _behaviorMinuteController =
                                          _behaviorMinuteControllers[
                                              _selectedScreenTimeType]!;
                                      } else {
                                        _showAddNewDialog();
                                      }
                                    });
                                  },
                                  value: _selectedScreenTimeType,
                                  items: _dependentItems
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value,
                                      style: TextStyle(
                                          color: _selectedValues.contains(value) ? Colors.green : Colors.black,
                                          fontWeight: _selectedValues.contains(value) ? FontWeight.bold : FontWeight.normal,
                                        )
                                      ),
                                    );
                                  }).toList(),
                                ),
                                const SizedBox(
                                  height: 20,
                                ),
                                Visibility(
                                  visible: _selectedScreenTimeType.isEmpty,
                                  child: Text(
                                    'Select a screen time to set goals and track behavior.',
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
                                  visible: _selectedScreenTimeType.isNotEmpty || _feedback.isNotEmpty,
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
                                  child: 
                                    Container(width: MediaQuery.of(context).size.width * 0.5,
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
                                          decrementGoalHour();
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextFormField(
                                        onTapOutside: (event) => {FocusManager.instance.primaryFocus?.unfocus()},
                                        controller: _goalHourController,
                                        decoration: const InputDecoration(
                                            labelText: 'Hours'),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) => {
                                          textFieldOnChange(value)
                                        },
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
                                          incrementGoalHour();
                                        },
                                      ),
                                    ),
                                  ],
                                ))),
                                Center(
                                  child: 
                                    Container(width: MediaQuery.of(context).size.width * 0.5,
                                            child:
                                Row(
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
                                          decrementGoalMinute();
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextFormField(
                                        onTapOutside: (event) => {FocusManager.instance.primaryFocus?.unfocus()},
                                        controller: _goalMinuteController,
                                        decoration: const InputDecoration(
                                            labelText: 'Minutes'),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) => {
                                          textFieldOnChange(value)
                                        },
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
                                          incrementGoalMinute();
                                        },
                                      ),
                                    ),
                                  ],
                                ))),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  'Total Goal: ${( int.parse(calculateTotalGoal())/ 60).toStringAsFixed(2)} Hours',
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
                                  child: 
                                    Container(
                                      width: MediaQuery.of(context).size.width * 0.5,
                                            child:
                                Row(
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
                                          decrementBehaviorHour();
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextFormField(
                                        onTapOutside: (event) => {FocusManager.instance.primaryFocus?.unfocus()},
                                        controller: _behaviorHourController,
                                        decoration: const InputDecoration(
                                            labelText: 'Hours'),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) => {
                                          textFieldOnChange(value)
                                        },
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
                                          incrementBehaviorHour();
                                        },
                                      ),
                                    ),
                                  ],
                                ))),
                                Center(
                                  child: 
                                    Container(width: MediaQuery.of(context).size.width * 0.5,
                                            child:
                                Row(
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
                                          decrementBehaviorMinute();
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextFormField(
                                        onTapOutside: (event) => {FocusManager.instance.primaryFocus?.unfocus()},
                                        controller: _behaviorMinuteController,
                                        decoration: const InputDecoration(
                                            labelText: 'Minutes'),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) => {
                                          textFieldOnChange(value)
                                        },
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
                                          incrementBehaviorMinute();
                                        },
                                      ),
                                    ),
                                  ],
                                ))),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  'Total Behavior: ${( int.parse(calculateTotalBehavior())/ 60).toStringAsFixed(2)} Hours',
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
                                  onTapOutside: (event) => {FocusManager.instance.primaryFocus?.unfocus()},
                                  controller: _reflectionController,
                                  keyboardType: TextInputType.multiline,
                                  maxLines: null,
                                  onChanged: (value) => {
                                    autosave()
                                  },
                                  decoration: const InputDecoration(
                                      labelText: 'Type my thoughts'),
                                ),
                                const SizedBox(
                                  height: 15,
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
                                    fontSize: 18,
                                    fontFamily: fontFamily,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green
                                  ),
                                ),
                                ]))),
                              ],
                            ),
                          ),
                        ),
                      )),
                      Visibility(
                        visible: _selectedScreenTimeType.isNotEmpty || _feedback.isNotEmpty,
                        child: Expanded(
                            flex: 1,
                            child: Column(
                              children: [
                                const Divider(
                                thickness: 1,
                                color: Colors.black,
                              ),
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    const SizedBox(
                                      height: 5,
                                    ),
                                    ElevatedButton(
                                      onPressed: () {
                                        onSave(false);
                                      },
                                      style: ButtonStyle(
                                        backgroundColor: WidgetStateProperty.all<Color>(
                                            const Color(0xfff5b342)),
                                      ),
                                      child: const Text(
                                        'Get AI Feedback',
                                        style: TextStyle(
                                            fontFamily: fontFamily,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 18),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ]
                            )
                          )
                        ),
                ],
              ),
            ));
  }
}
