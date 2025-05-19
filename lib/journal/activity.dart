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

class ActivityCard extends StatefulWidget {
  final String userId;

  final Function swipeLeft;
  final Function swipeRight;

  const ActivityCard({required this.userId, required this.swipeLeft, required this.swipeRight});

  @override
  _ActivityCardState createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
  Timer? _debounce;
  String _selectedActivityType = '';
  List<String> _dependentItems = [];
  String _selectedActivityCategory = '';

  late Map<String, TextEditingController> _goalHourControllers;
  late Map<String, TextEditingController> _goalMinuteControllers;
  TextEditingController _goalHourController = TextEditingController();
  TextEditingController _goalMinuteController = TextEditingController();

  late Map<String, TextEditingController> _behaviorHourControllers;
  late Map<String, TextEditingController> _behaviorMinuteControllers;
  TextEditingController _behaviorHourController = TextEditingController();
  TextEditingController _behaviorMinuteController = TextEditingController();

  final TextEditingController _reflectionController = TextEditingController();

  bool _isLoading = false;
  late String _feedback;

  late Map<String, List<String>> activityMap;
  late Map<String, dynamic> _activities;

  List<String> _selectedValues = [];

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

  void addNewActivity(String? newActivity) {
    if (_selectedActivityCategory != '' && !activityMap[_selectedActivityCategory]!.contains(newActivity)) {
      _selectedActivityType = newActivity!;
      activityMap[_selectedActivityCategory]!.add(_selectedActivityType);
      showCustomToast(context, 'New Activity has been added.', Theme.of(context).primaryColor);
      if (!_goalHourControllers.keys.contains(_selectedActivityType)) {
        _goalHourControllers[newActivity] = TextEditingController();
        _goalHourControllers[newActivity]!.text = 0.toString();
        _goalMinuteControllers[newActivity] = TextEditingController();
        _goalMinuteControllers[newActivity]!.text = 0.toString();
        _behaviorHourControllers[newActivity] = TextEditingController();
        _behaviorHourControllers[newActivity]!.text = 0.toString();
        _behaviorMinuteControllers[newActivity] = TextEditingController();
        _behaviorMinuteControllers[newActivity]!.text = 0.toString();
      }
      setState(() {
        _goalHourController =_goalHourControllers[_selectedActivityType]!;
        _goalMinuteController =_goalMinuteControllers[_selectedActivityType]!;
        _behaviorHourController =_behaviorHourControllers[_selectedActivityType]!;
        _behaviorMinuteController =_behaviorMinuteControllers[_selectedActivityType]!;
        });
    }
  }

  void incrementGoalHour() {
    setState(() {
      if (_selectedActivityType != '') {
        if (_goalHourControllers[_selectedActivityType]!.text.isEmpty) {
          _goalHourControllers[_selectedActivityType]!.text = 1.toString();
        } else {
          _goalHourControllers[_selectedActivityType]!.text =
              (int.parse(_goalHourControllers[_selectedActivityType]!.text) + 1)
                  .toString();
        }

        textFieldOnChange(_goalHourController.text);
      }
    });
  }

  void incrementBehaviorHour() {
    setState(() {
      if (_selectedActivityType != '') {
        if (_behaviorHourControllers[_selectedActivityType]!.text.isEmpty) {
          _behaviorHourControllers[_selectedActivityType]!.text = 1.toString();
        } else {
          _behaviorHourControllers[_selectedActivityType]!.text = (int.parse(
                      _behaviorHourControllers[_selectedActivityType]!.text) +
                  1)
              .toString();
        }

        textFieldOnChange(_behaviorHourController.text);
      }
    });
  }

  void incrementGoalMinute() {
    setState(() {
      if (_selectedActivityType != '') {
        if (_goalMinuteControllers[_selectedActivityType]!.text.isEmpty) {
          _goalMinuteControllers[_selectedActivityType]!.text = 15.toString();
        } else {
          _goalMinuteControllers[_selectedActivityType]!.text =
              (int.parse(_goalMinuteControllers[_selectedActivityType]!.text) +
                      15)
                  .toString();
        }

        textFieldOnChange(_goalMinuteController.text);
      }
    });
  }

  void incrementBehaviorMinute() {
    setState(() {
      if (_selectedActivityType != '') {
        if (_behaviorMinuteControllers[_selectedActivityType]!.text.isEmpty) {
          _behaviorMinuteControllers[_selectedActivityType]!.text =
              15.toString();
        } else {
          _behaviorMinuteControllers[_selectedActivityType]!.text = (int.parse(
                      _behaviorMinuteControllers[_selectedActivityType]!.text) +
                  15)
              .toString();
        }

        textFieldOnChange(_behaviorMinuteController.text);
      }
    });
  }

  void decrementGoalHour() {
    setState(() {
      if (_selectedActivityType != '') {
        if (_goalHourControllers[_selectedActivityType]!.text.isNotEmpty &&
            int.parse(_goalHourControllers[_selectedActivityType]!.text) > 0) {
          _goalHourControllers[_selectedActivityType]!.text =
              (int.parse(_goalHourControllers[_selectedActivityType]!.text) - 1)
                  .toString();
        }

        textFieldOnChange(_goalHourController.text);
      }
    });
  }

  void decrementBehaviorHour() {
    setState(() {
      if (_selectedActivityType != '') {
        if (_behaviorHourControllers[_selectedActivityType]!.text.isNotEmpty &&
            int.parse(_behaviorHourControllers[_selectedActivityType]!.text) >
                0) {
          _behaviorHourControllers[_selectedActivityType]!.text = (int.parse(
                      _behaviorHourControllers[_selectedActivityType]!.text) -
                  1)
              .toString();
        }

        textFieldOnChange(_behaviorHourController.text);
      }
    });
  }

  void decrementGoalMinute() {
    setState(() {
      if (_selectedActivityType != '') {
        if (_goalMinuteControllers[_selectedActivityType]!.text.isNotEmpty &&
            int.parse(_goalMinuteControllers[_selectedActivityType]!.text) >=
                15) {
          _goalMinuteControllers[_selectedActivityType]!.text =
              (int.parse(_goalMinuteControllers[_selectedActivityType]!.text) -
                      15)
                  .toString();
        }

        textFieldOnChange(_goalMinuteController.text);
      }
    });
  }

  void decrementBehaviorMinute() {
    setState(() {
      if (_selectedActivityType != '') {
        if (_behaviorMinuteControllers[_selectedActivityType]!
                .text
                .isNotEmpty &&
            int.parse(_behaviorMinuteControllers[_selectedActivityType]!.text) >=
                15) {
          _behaviorMinuteControllers[_selectedActivityType]!.text = (int.parse(
                      _behaviorMinuteControllers[_selectedActivityType]!.text) -
                  15)
              .toString();
        }

        textFieldOnChange(_behaviorMinuteController.text);
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
        save(true);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }

  void _initActivityMap() {
    activityMap =  Map<String, List<String>>.from(activityTypes);

    _activities.keys.forEach((key) {
      Map<String, dynamic> savedActivitiesForCurCategory = _activities[key];

      List<String> typesSavedToServer = savedActivitiesForCurCategory.keys.toList();
      List<String> locallySavedTypes = activityMap[key]!;

      for (var type in typesSavedToServer) {
        if (!locallySavedTypes.contains(type)) {
          locallySavedTypes.add(type);
        }
      }
    });
  }

  void _initGoalHourControllers() {
    _goalHourControllers = {};
    activityMap.values.forEach((activities) {
      activities.forEach((activity) {
        if (activity != addNewKey) {
          _goalHourControllers[activity] = TextEditingController();
          _goalHourControllers[activity]!.text = 0.toString();
        }
      });
    });
  }

  void _initGoalMinuteControllers() {
    _goalMinuteControllers = {};
    activityMap.values.forEach((activities) {
      activities.forEach((activity) {
        if (activity != addNewKey) {
          _goalMinuteControllers[activity] = TextEditingController();
          _goalMinuteControllers[activity]!.text = 0.toString();
        }
      });
    });
  }

  void _initBehaviorHourControllers() {
    _behaviorHourControllers = {};
    activityMap.values.forEach((activities) {
      activities.forEach((activity) {
        if (activity != addNewKey) {
          _behaviorHourControllers[activity] = TextEditingController();
          _behaviorHourControllers[activity]!.text = 0.toString();
        }
      });
    });
  }

  void _initBehaviorMinuteControllers() {
    _behaviorMinuteControllers = {};
    activityMap.values.forEach((activities) {
      activities.forEach((activity) {
        if (activity != addNewKey) {
          _behaviorMinuteControllers[activity] = TextEditingController();
          _behaviorMinuteControllers[activity]!.text = 0.toString();
        }
      });
    });
  }

  void _setControllers() {
    for (String key in activityMap.keys) {
      List<String> types = activityMap[key]!;

      for (String item in types) {
       if (_activities[key] != null && item != addNewKey) {
          _goalHourControllers[item]!.text = _activities[key][item]['goal']['hours'].toString();
          _goalMinuteControllers[item]!.text = _activities[key][item]!['goal']['minutes'].toString();
          _behaviorHourControllers[item]!.text = _activities[key][item]!['behavior']['hours'].toString();
          _behaviorMinuteControllers[item]!.text = _activities[key][item]!['behavior']['minutes'].toString();
       }
      }
    }
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String queryString =
          getQueryParamsForGoalEndpoints(widget.userId, 'activity');

      final response = await get(Uri.parse('$getGoal?$queryString'));

      if (response.statusCode == 200) {
        List<dynamic> responseBody = json.decode(response.body);
        if (responseBody.isNotEmpty) {
          var activityData = responseBody.first as Map<String, dynamic>;
          _reflectionController.text = activityData['reflection'];
          setState(() {
            _activities = activityData['activities'];
            _feedback = activityData['feedback'];
          });
          
          _selectedValues = [];

            for (var category in _activities.entries) {
              if (category.value is Map<String, dynamic>) {
                for (var activityEntry in (category.value as Map<String, dynamic>).entries) { 
                  var activityData = activityEntry.value;

                  if (activityData is Map<String, dynamic> &&
                      activityData.containsKey("goal") &&
                      activityData.containsKey("behavior")) {

                    int goalHours = (activityData["goal"]["hours"] is int) ? activityData["goal"]["hours"] : 0;
                    int goalMinutes = (activityData["goal"]["minutes"] is int) ? activityData["goal"]["minutes"] : 0;
                    int behaviorHours = (activityData["behavior"]["hours"] is int) ? activityData["behavior"]["hours"] : 0;
                    int behaviorMinutes = (activityData["behavior"]["minutes"] is int) ? activityData["behavior"]["minutes"] : 0;

                    if (goalHours > 0 || goalMinutes > 0 || behaviorHours > 0 || behaviorMinutes > 0) {
                      setState(() {
                        _selectedValues.add(activityEntry.key);
                      });
                    }
                  }
                }
              }
            }
        } else {
          setState(() {
            _activities = {};
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

    _initActivityMap();
    _initGoalHourControllers();
    _initGoalMinuteControllers();
    _initBehaviorHourControllers();
    _initBehaviorMinuteControllers();
    _setControllers();
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
                  decoration: const InputDecoration(hintText: "Enter new physical activity"),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                setState(() {
                   _selectedActivityType = activityMap[_selectedActivityCategory]!.last;
                });
                Navigator.pop(context);
              },
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                String newItem = newItemController.text.trim();
                if (newItem.isNotEmpty) {
                  addNewActivity(newItem);
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

    String jsonData = getPhysicalActivityBehaviorPayload(
            _goalHourControllers,
            _goalMinuteControllers,
            _behaviorHourControllers,
            _behaviorMinuteControllers,
            widget.userId,
            _feedback,
            _reflectionController.text,
            calculateTotalGoal(),
            calculateTotalBehavior(),
            activityMap);
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

          showCustomToast(context, 'Physical activity has been saved successfully.',
              Theme.of(context).primaryColor);
        } else if (response.statusCode == 400) {
          showCustomToast(
              context, 'Physical activity couldn\'t be saved.', errorColor);
        }
  }

  void textFieldOnChange(String value) {
    if (value != '') {
      if (int.parse(_goalHourController.text) == 0 && int.parse(_goalMinuteController.text) == 0 &&
          int.parse(_behaviorHourController.text) == 0 && int.parse(_behaviorMinuteController.text) == 0) {
      setState(() {
        _selectedValues.remove(_selectedActivityType);
      });
    } else if(int.parse(_goalHourController.text) > 0 || int.parse(_goalMinuteController.text) > 0 ||
        int.parse(_behaviorHourController.text) > 0 || int.parse(_behaviorMinuteController.text) > 0) {
      if (!_selectedValues.contains(_selectedActivityType)) {
        setState(() {
          _selectedValues.add(_selectedActivityType);
        });
      }
    }

     autosave();
    }
  }

  void save(bool autoSave) async {
    try {
      if (!autoSave) {
        setState(() {
          _isLoading = true;
        });

        String chatPayload = getChatbotPayloadFor(
            int.parse(calculateTotalGoal()),
            int.parse(calculateTotalBehavior()),
            _reflectionController.text,
            'Physical Activity',
            recommendedPhysicalActivityValue);
        var chatResponse = await post(
          Uri.parse(getChatReply),
          body: chatPayload,
          headers: {
            'Content-Type': 'application/json',
          },
        );
        if (chatResponse.statusCode == 200) {
          String feedback = jsonDecode(chatResponse.body)['chat_reply'];
          setState(() {
            _feedback = feedback;
          });

          saveBehavior(autoSave);
        }
      } else {
        saveBehavior(autoSave);
      }
    } catch (e) {
      showCustomToast(context, e.toString(), errorColor);
    } finally {
      setState(() {
        _isLoading = false;
        if (!autoSave) {
          _dependentItems = [];
          _selectedActivityType = '';          
        }
      });
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
                                            "Sleep",
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
                                      Icons.directions_run,
                                      color: secondaryColor,
                                    ),
                                    Text(
                                      myJournalItems[0],
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
                                            title: Text(myJournalItems[0],
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                )),
                                            content: const Text(
                                              activityInfo,
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
                                                "Screen Time",
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
                                      labelText: 'Select activity category.'),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedActivityCategory = value!;
                                      _selectedActivityType =
                                          activityMap[value!]!.last;
                                      _dependentItems =
                                          activityMap[value!] ?? [];
                                      _goalHourController =
                                          _goalHourControllers[
                                              _selectedActivityType]!;
                                      _goalMinuteController =
                                          _goalMinuteControllers[
                                              _selectedActivityType]!;
                                      _behaviorHourController =
                                          _behaviorHourControllers[
                                              _selectedActivityType]!;
                                      _behaviorMinuteController =
                                          _behaviorMinuteControllers[
                                              _selectedActivityType]!;
                                    });
                                  },
                                  items: activityMap.keys
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
                                      labelText: 'Select activity type.'),
                                  onChanged: (value) {
                                    _selectedActivityType = value!;
                                    setState(() {
                                      if (_selectedActivityType != addNewKey) {
                                        _goalHourController =
                                          _goalHourControllers[
                                              _selectedActivityType]!;
                                      _goalMinuteController =
                                          _goalMinuteControllers[
                                              _selectedActivityType]!;
                                      _behaviorHourController =
                                          _behaviorHourControllers[
                                              _selectedActivityType]!;
                                      _behaviorMinuteController =
                                          _behaviorMinuteControllers[
                                              _selectedActivityType]!;
                                      } else {
                                        _showAddNewDialog();
                                      }
                                    });
                                  },
                                  value: _selectedActivityType,
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
                                  visible: _selectedActivityType.isEmpty,
                                  child: Text(
                                    'Select a physical activity to set goals and track behavior.',
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
                                  visible: _selectedActivityType.isNotEmpty || _feedback.isNotEmpty,
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
                                            ),
                                          )
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
                                            ),
                                          )
                                        ),

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
                                                    onChanged: (value) {
                                                      textFieldOnChange(value);
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
                                            ),
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
                                                    onChanged: (value) {
                                                      textFieldOnChange(value);
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
                                            ),
                                          ),
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Text(
                                          'Total Behavior: ${(int.parse(calculateTotalBehavior())/ 60).toStringAsFixed(2)} Hours',
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
                                      ],
                                    ),
                                  ),
                                ),
                                
                              ],
                            ),
                          ),
                        ),
                      )),
                      Visibility(
                        visible: _selectedActivityType.isNotEmpty || _feedback.isNotEmpty,
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
                                    save(false);
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
                      )
                ],
              ),
            ));
  }
}
