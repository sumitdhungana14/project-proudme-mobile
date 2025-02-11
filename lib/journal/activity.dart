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

class ActivityCard extends StatefulWidget {
  final String userId;

  const ActivityCard({required this.userId});

  @override
  _ActivityCardState createState() => _ActivityCardState();
}

class _ActivityCardState extends State<ActivityCard> {
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
  TextEditingController _newActivityController = TextEditingController();

  bool _isLoading = false;
  late String _feedback;

  late Map<String, List<String>> activityMap;
  late Map<String, dynamic> _activities;

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
      _newActivityController.clear();
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
      }
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchData();
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
        _goalHourControllers[activity] = TextEditingController();
        _goalHourControllers[activity]!.text = 0.toString();
      });
    });
  }

  void _initGoalMinuteControllers() {
    _goalMinuteControllers = {};
    activityMap.values.forEach((activities) {
      activities.forEach((activity) {
        _goalMinuteControllers[activity] = TextEditingController();
        _goalMinuteControllers[activity]!.text = 0.toString();
      });
    });
  }

  void _initBehaviorHourControllers() {
    _behaviorHourControllers = {};
    activityMap.values.forEach((activities) {
      activities.forEach((activity) {
        _behaviorHourControllers[activity] = TextEditingController();
        _behaviorHourControllers[activity]!.text = 0.toString();
      });
    });
  }

  void _initBehaviorMinuteControllers() {
    _behaviorMinuteControllers = {};
    activityMap.values.forEach((activities) {
      activities.forEach((activity) {
        _behaviorMinuteControllers[activity] = TextEditingController();
        _behaviorMinuteControllers[activity]!.text = 0.toString();
      });
    });
  }

  void _setControllers() {
    activityMap.keys.forEach((key) {
      List<String> types = activityMap[key]!;

      types.forEach((item) {
        _goalHourControllers[item]!.text = _activities[key][item]['goal']['hours'].toString();
        _goalMinuteControllers[item]!.text = _activities[key][item]['goal']['minutes'].toString();
        _behaviorHourControllers[item]!.text = _activities[key][item]['behavior']['hours'].toString();
        _behaviorMinuteControllers[item]!.text = _activities[key][item]['behavior']['minutes'].toString();
      });
    });
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

  void save() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String chatPayload = getChatbotPayloadForPhysicalActivity(
          int.parse(calculateTotalGoal()),
          int.parse(calculateTotalBehavior()),
          _reflectionController.text);
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

          setState(() {
            _selectedActivityType = '';
            _dependentItems = [];
          });
          showCustomToast(
              context,
              'Physical activity has been saved successfully.',
              Theme.of(context).primaryColor);
        } else if (response.statusCode == 400) {
          showCustomToast(
              context, 'Physical activity couldn\'t be saved.', errorColor);
        }
      }
    } catch (e) {
      showCustomToast(context, e.toString(), errorColor);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
                                  ],
                                ),
                                const Divider(),
                                DropdownButtonFormField<String>(
                                  decoration: const InputDecoration(
                                      labelText: 'Select activity category.'),
                                  onChanged: (value) {
                                    setState(() {
                                      _selectedActivityCategory = value!;
                                      _selectedActivityType =
                                          activityMap[value!]!.first;
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
                                  value: _selectedActivityType,
                                  items: _dependentItems
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
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
                                  visible: _selectedActivityCategory != '',
                                  child: Container(
                                    padding: const EdgeInsets.all(16.0),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        // Text component
                                        Text(
                                          'Don\'t see a physical activity you are looking for?',
                                          style: TextStyle(
                                            fontSize: 20,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: fontFamily,
                                            color: Theme.of(context).primaryColor,
                                          ),
                                        ),
                                        const SizedBox(height: 10), // Add space between the text and the row
                                        // Row with TextFormField and IconButton
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Expanded(
                                              child: TextFormField(
                                                controller: _newActivityController,
                                                decoration: const InputDecoration(
                                                  labelText: 'Add a new physical activity',
                                                ),
                                                keyboardType: TextInputType.text,
                                                onChanged: (value) => setState(() {}),
                                                inputFormatters: <TextInputFormatter>[
                                                  FilteringTextInputFormatter.singleLineFormatter,
                                                ],
                                              ),
                                            ),
                                            const SizedBox(width: 10), // Space between TextFormField and IconButton
                                            Container(
                                              decoration: BoxDecoration(
                                                color: Theme.of(context).primaryColor,
                                                borderRadius: BorderRadius.circular(4), // Rounded corners for button
                                              ),
                                              child: IconButton(
                                                icon: const Icon(Icons.add),
                                                color: Colors.white,
                                                onPressed: () {
                                                  if (_newActivityController.text.isNotEmpty) {
                                                    addNewActivity(_newActivityController.text);
                                                  }
                                                },
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                  height: 20,
                                ),
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
                                          decrementGoalHour();
                                        },
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: TextFormField(
                                        controller: _goalHourController,
                                        decoration: const InputDecoration(
                                            labelText: 'Hours'),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) => {setState(() {})},
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
                                        controller: _goalMinuteController,
                                        decoration: const InputDecoration(
                                            labelText: 'Minutes'),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) => {setState(() {})},
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
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  'Total Goal: ${calculateTotalGoal()} Minutes',
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
                                        controller: _behaviorHourController,
                                        decoration: const InputDecoration(
                                            labelText: 'Hours'),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          setState(() {});
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
                                        controller: _behaviorMinuteController,
                                        decoration: const InputDecoration(
                                            labelText: 'Minutes'),
                                        keyboardType: TextInputType.number,
                                        onChanged: (value) {
                                          setState(() {});
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
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  'Total Behavior: ${calculateTotalBehavior()} Minutes',
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
                                    fontSize: 16,
                                    fontFamily: fontFamily,
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
                    visible: _selectedActivityType != '',
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
                  )
                ],
              ),
            ));
  }
}
