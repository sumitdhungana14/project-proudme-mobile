import 'package:flutter/material.dart';
import 'package:flutter/services.dart'
    show TextInputFormatter, FilteringTextInputFormatter;
import 'package:project_proud_me/constant.dart';
import 'package:project_proud_me/language.dart';
import 'package:project_proud_me/utils/helpers.dart';
import 'package:project_proud_me/endpoints.dart';
import 'package:http/http.dart' show get, post;
import 'dart:convert';
import 'package:project_proud_me/widgets/toast.dart';
import 'dart:async' show Timer;

class SleepCard extends StatefulWidget {
  //TODO: Change the API to receive goalValue and behaviorValue in minutes not hours (double)
  final String userId;
  final Function swipeLeft;
  final Function swipeRight;

  const SleepCard({required this.userId, required this.swipeLeft, required this.swipeRight});

  @override
  _SleepCardState createState() => _SleepCardState();
}

class _SleepCardState extends State<SleepCard> {
  Timer? _debounce;

  TimeOfDay _selectedBehaviorBedTime = TimeOfDay.now();
  TimeOfDay _selectedBehaviorWakeUpTime = TimeOfDay.now();

  TimeOfDay _selectedGoalBedTime = TimeOfDay.now();
  TimeOfDay _selectedGoalWakeUpTime = TimeOfDay.now();


  final TextEditingController _reflectionController = TextEditingController();
  bool _isLoading = false;
  String _feedback = '';
  
  Future<void> _selectGoalBedTime(BuildContext context) async {
    final TimeOfDay picked = await showTimePicker(
            context: context,
            initialTime: _selectedGoalBedTime,
            helpText: 'Bed Time') ??
        TimeOfDay.now();
    if (picked != _selectedGoalBedTime) {
      setState(() {
        _selectedGoalBedTime = picked;
      });
    }

    await autosave();
  }

  Future<void> _selectGoalWakeUpTime(BuildContext context) async {
    final TimeOfDay picked = await showTimePicker(
            context: context,
            initialTime: _selectedGoalWakeUpTime,
            helpText: 'Wake up Time') ??
        TimeOfDay.now();
    if (picked != _selectedGoalWakeUpTime) {
      setState(() {
        _selectedGoalWakeUpTime = picked;
      });
    }

    await autosave();
  }

  Future<void> _selectBehaviorBedTime(BuildContext context) async {
    final TimeOfDay picked = await showTimePicker(
            context: context,
            initialTime: _selectedBehaviorBedTime,
            helpText: 'Bed Time') ??
        TimeOfDay.now();
    if (picked != _selectedBehaviorBedTime) {
      setState(() {
        _selectedBehaviorBedTime = picked;
      });
    }

    await autosave();
  }

  Future<void> _selectBehaviorWakeUpTime(BuildContext context) async {
    final TimeOfDay picked = await showTimePicker(
            context: context,
            initialTime: _selectedBehaviorWakeUpTime,
            helpText: 'Wake up Time') ??
        TimeOfDay.now();
    if (picked != _selectedBehaviorWakeUpTime) {
      setState(() {
        _selectedBehaviorWakeUpTime = picked;
      });
    }

    await autosave();
  }

  Future<void> _fetchDataAndSetControllers() async {
    setState(() {
      _isLoading = true;
    });

    try {
      String queryString =
          getQueryParamsForGoalEndpoints(widget.userId, 'sleep');

      final response = await get(Uri.parse('$getGoal?$queryString'));

      if (response.statusCode == 200) {
        List<dynamic> responseBody = json.decode(response.body);

        if (responseBody.isNotEmpty) {
          var sleepData = responseBody.first as Map<String, dynamic>;

          int bedBehavior = sleepData['sleep']['bedBehavior'];
          int wakeUpBehavior = sleepData['sleep']['wakeUpBehavior'];

          int bedGoal = sleepData['sleep']['bedGoal'];
          int wakeUpGoal = sleepData['sleep']['wakeUpGoal'];

          _selectedBehaviorBedTime = intToTimeOfDay(bedBehavior);
          _selectedBehaviorWakeUpTime = intToTimeOfDay(wakeUpBehavior);
          _selectedGoalBedTime = intToTimeOfDay(bedGoal);
          _selectedGoalWakeUpTime = intToTimeOfDay(wakeUpGoal);
          _reflectionController.text = sleepData['reflection'];
          _feedback = sleepData['feedback'];
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

  void saveBehavior(String reflection, int totalBehaviorInMinutes, int totalGoalInMinutes) async {
    String payload = getSleepPayload(
              _selectedGoalBedTime,
              _selectedGoalWakeUpTime,
              totalBehaviorInMinutes,
              totalGoalInMinutes,
              _selectedBehaviorBedTime,
              _selectedBehaviorWakeUpTime,
              widget.userId,
              _feedback,
              reflection);

          var response = await post(
            Uri.parse(saveGoal),
            body: payload,
            headers: baseHttpHeader,
          );

          if (response.statusCode == 200 || response.statusCode == 201) {
            await post(
              Uri.parse(saveGoal),
              body: payload,
              headers: baseHttpHeader,
            );
            showCustomToast(context, sleepSaved, Theme.of(context).primaryColor);
          } else {
            showCustomToast(context, sleepNotSaved, errorColor);
        }
  }

  void onSave(bool autosave) async {
    setState(() {
      _isLoading = true;
    });

    String reflection = _reflectionController.text;
    int totalBehaviorInMinutes = int.tryParse(calculateTimeDifference(
            _selectedBehaviorBedTime, _selectedBehaviorWakeUpTime)) ??
        0;
    int totalGoalInMinutes = int.tryParse(calculateTimeDifference(
            _selectedGoalBedTime, _selectedGoalWakeUpTime)) ??
        0;
    
    try {
      if (!autosave) {
        String chatPayload = getChatbotPayloadForSleep(
          totalGoalInMinutes, totalBehaviorInMinutes, reflection);

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

          saveBehavior(reflection, totalBehaviorInMinutes, totalGoalInMinutes);
        } else {
          showCustomToast(context, sleepNotSaved, errorColor);
        }
      } else {
        saveBehavior(reflection, totalBehaviorInMinutes, totalGoalInMinutes);
      }
    } catch (e) {
      showCustomToast(context, e.toString(), errorColor);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> autosave() async {
    if (_debounce?.isActive ?? false) _debounce?.cancel();
      _debounce = Timer(const Duration(milliseconds: 2000), () {
        onSave(true);
    });
  }

  @override
  void initState() {
    super.initState();
    _fetchDataAndSetControllers();
  }

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
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
                                            "Fruits & Vegetables",
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
                                    Transform.rotate(
                                      angle: 0.7,
                                      child: const Icon(
                                        Icons.mode_night_outlined,
                                        color: secondaryColor,
                                      ),
                                    ),
                                    const SizedBox(
                                      width: 5,
                                    ),
                                    Text(
                                      myJournalItems[3],
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
                                              myJournalItems[3],
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                            content: const Text(
                                              sleepInfo,
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
                                                "Physical Activity",
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
                                Text(
                                  'Set My Sleep Goal',
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
                                  children: <Widget>[
                                    const Text(
                                      'Bed Time:',
                                      style: TextStyle(
                                        fontFamily: fontFamily,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      getTimeToDisplay(
                                          _selectedGoalBedTime),
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: fontFamily),
                                    ),
                                    const SizedBox(width: 20),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _selectGoalBedTime(context),
                                      child: const Text('Select'),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const Text(
                                      'Wake up Time:',
                                      style: TextStyle(fontFamily: fontFamily),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      getTimeToDisplay(
                                          _selectedGoalWakeUpTime),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: fontFamily,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _selectGoalWakeUpTime(context),
                                      child: const Text('Select'),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  'Total Goal: ${(int.parse(calculateTimeDifference(_selectedGoalBedTime, _selectedGoalWakeUpTime))/ 60).toStringAsFixed(2)} Hours',
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
                                  'Track My Sleep Behavior',
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
                                  children: <Widget>[
                                    const Text(
                                      'Bed Time:',
                                      style: TextStyle(
                                        fontFamily: fontFamily,
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      getTimeToDisplay(
                                          _selectedBehaviorBedTime),
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.bold,
                                          fontFamily: fontFamily),
                                    ),
                                    const SizedBox(width: 20),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _selectBehaviorBedTime(context),
                                      child: const Text('Select'),
                                    ),
                                  ],
                                ),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: <Widget>[
                                    const Text(
                                      'Wake up Time:',
                                      style: TextStyle(fontFamily: fontFamily),
                                    ),
                                    const SizedBox(width: 10),
                                    Text(
                                      getTimeToDisplay(
                                          _selectedBehaviorWakeUpTime),
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        fontFamily: fontFamily,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    ElevatedButton(
                                      onPressed: () =>
                                          _selectBehaviorWakeUpTime(context),
                                      child: const Text('Select'),
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Text(
                                  'Sleep Duration: ${(int.parse(calculateTimeDifference(_selectedBehaviorBedTime, _selectedBehaviorWakeUpTime))/ 60).toStringAsFixed(2)} Hours',
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
                                  onChanged: (value) => autosave(),
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
                      )),
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
                ],
              ),
            ));
  }
}
