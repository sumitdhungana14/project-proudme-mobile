import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:project_proud_me/constant.dart';
import 'package:shared_preferences/shared_preferences.dart'
    show SharedPreferences;
import 'package:intl/intl.dart';

Future<void> logout() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  await prefs.remove(authTokenKey);
  await prefs.remove(userDataKey);
}

String getQueryParamsForGoalEndpoints(String id, String goalType) {
  var params = {
    'user[_id]': id,
    'goalType': goalType,
    'date': getNowInFormat(dateFormat)
  };
  return Uri(queryParameters: params).query;
}

String getQueryParams(String id, String goalType, String day) {
  var params = {
    'user[_id]': id,
    'goalType': goalType,
    'date': day
  };
  return Uri(queryParameters: params).query;
}

String getJournalDateParams(String id) {

  var params = {
    'userId': id,
    'date': getNowInFormat('M/d/yyyy')
  };
  return Uri(queryParameters: params).query;
}

String getNowInFormat(String format) {
  DateTime now = DateTime.now();
  return DateFormat(format).format(now);
}

String getYesterdaysDate(String format) {
  DateTime yesterday = DateTime.now().subtract(const Duration(days: 1));
  return DateFormat(format).format(yesterday);
}

TimeOfDay intToTimeOfDay(int intValue) {
  final int hour = intValue ~/ 60;
  final int minute = intValue % 60;
  return TimeOfDay(hour: hour, minute: minute);
}

String getPhysicalActivityBehaviorPayload(
    Map<String, TextEditingController> goalHourController,
    Map<String, TextEditingController> goalMinuteController,
    Map<String, TextEditingController> behaviorHourController,
    Map<String, TextEditingController> behaviorMinuteController,
    String userId,
    String feedback,
    String reflection,
    String totalGoal,
    String totalBehavior,
    Map<String, List<String>> activityMap) {
  String date = getNowInFormat(dateFormat);
  String dateToday = getNowInFormat('yyyy-MM-ddTHH:mm:ss.SSSZ');

  int goalValue = int.parse(totalGoal);
  int behaviorValue = int.parse(totalBehavior);

  Map<String, dynamic> activities = {};

  activityMap.keys.forEach((key) {
    List<String> setActivities = activityMap[key]!;
    Map<String, dynamic> activitiesMap = {};


    setActivities.forEach((item) {
      if (item != addNewKey) {
        int goalHours = int.tryParse(goalHourController[item]!.text) ?? 0;
        int goalMinutes = int.tryParse(goalMinuteController[item]!.text) ?? 0;

        int behaviorHours = int.tryParse(behaviorHourController[item]!.text) ?? 0;
        int behaviorMinutes = int.tryParse(behaviorMinuteController[item]!.text) ?? 0;

        activitiesMap[item] = {
          'goal': {'hours': goalHours, 'minutes': goalMinutes},
          'behavior': {'hours': behaviorHours, 'minutes': behaviorMinutes},
        };
      }
    });
    
    activities[key] = activitiesMap;
  });

  bool goalStatus = behaviorValue >= goalValue;

  Map<String, dynamic> payload = {
    'behaviorValue': behaviorValue,
    'goalValue': goalValue,
    'reflection': reflection,
    'feedback': feedback,
    'date': date,
    'goalStatus': goalStatus,
    'user': userId,
    'recommendedValue': recommendedPhysicalActivityValue,
    'goalType': 'activity',
    'dateToday': dateToday,
    'activities': activities
  };

  return jsonEncode(payload);
}

String getScreenTimeBehaviorPayload(
    Map<String, TextEditingController> goalHourController,
    Map<String, TextEditingController> goalMinuteController,
    Map<String, TextEditingController> behaviorHourController,
    Map<String, TextEditingController> behaviorMinuteController,
    String userId,
    String feedback,
    String reflection,
    String totalGoal,
    String totalBehavior,
    Map<String, List<String>> screenTimeMap) {
  String date = getNowInFormat(dateFormat);
  String dateToday = getNowInFormat('yyyy-MM-ddTHH:mm:ss.SSSZ');

  int goalValue = int.parse(totalGoal);
  int behaviorValue = int.parse(totalBehavior);

  Map<String, dynamic> screentime = {};

  screenTimeMap.keys.forEach((key) {
    List<String> setScreenTimes = screenTimeMap[key]!;
    Map<String, dynamic> screenTimesMap = {};

    setScreenTimes.forEach((item) {
      if (item != addNewKey) {
        int goalHours = int.tryParse(goalHourController[item]!.text) ?? 0;
        int goalMinutes = int.tryParse(goalMinuteController[item]!.text) ?? 0;

        int behaviorHours = int.tryParse(behaviorHourController[item]!.text) ?? 0;
        int behaviorMinutes = int.tryParse(behaviorMinuteController[item]!.text) ?? 0;

        screenTimesMap[item] = {
          'goal': {'hours': goalHours, 'minutes': goalMinutes},
          'behavior': {'hours': behaviorHours, 'minutes': behaviorMinutes},
        };
      }
    });
    
    screentime[key] = screenTimesMap;
  });

  bool goalStatus = behaviorValue >= goalValue;

  Map<String, dynamic> payload = {
    'behaviorValue': behaviorValue,
    'goalValue': goalValue,
    'reflection': reflection,
    'feedback': feedback,
    'date': date,
    'goalStatus': goalStatus,
    'user': userId,
    'recommendedValue': recommendedScreenTimeValue,
    'goalType': 'screentime',
    'dateToday': dateToday,
    'screentime': screentime
  };

  return jsonEncode(payload);
}

String getEatingBehaviorPayload(
    Map<String, TextEditingController> goalController,
    Map<String, TextEditingController> behaviorController,
    String userId,
    String feedback,
    String reflection,
    String totalGoal,
    String totalBehavior,
    Map<String, List<String>> eatMap) {
  String date = getNowInFormat(dateFormat);
  String dateToday = getNowInFormat('yyyy-MM-ddTHH:mm:ss.SSSZ');

  int goalValue = int.parse(totalGoal);
  int behaviorValue = int.parse(totalBehavior);

  Map<String, dynamic> eating = {};

  eatMap.keys.forEach((key) {
    List<String> setEats = eatMap[key]!;
    Map<String, dynamic> eatsMap = {};

    setEats.forEach((item) {
      if (item != addNewKey) {
        int goalHours = int.tryParse(goalController[item]!.text) ?? 0;

        int behaviorHours = int.tryParse(behaviorController[item]!.text) ?? 0;

        eatsMap[item] = {
          'goal': goalHours,
          'behavior': behaviorHours,
        };
      }
    });

    eating[key] = eatsMap;
  });

  bool goalStatus = behaviorValue >= goalValue;

  Map<String, dynamic> payload = {
    'behaviorValue': behaviorValue,
    'goalValue': goalValue,
    'reflection': reflection,
    'feedback': feedback,
    'date': date,
    'goalStatus': goalStatus,
    'user': userId,
    'recommendedValue': recommendedEatingValue,
    'goalType': 'eating',
    'dateToday': dateToday,
    'servings': eating
  };

  return jsonEncode(payload);
}

Future<Map<String, dynamic>> getUserFromSharedPreference() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  return jsonDecode(prefs.getString(userDataKey) ?? '');
}

bool isToday(String date) {
  DateTime today = DateTime.parse(date);
  DateTime now = DateTime.now();

  return today.year == now.year &&
      today.month == now.month &&
      today.day == now.day;
}

List<DateTime> getDateInCalendarFormat(List<String> dates) {
  final dateFormat = DateFormat('M/d/yyyy');

  List<DateTime> dateTimes = dates.map((date) {
    return dateFormat.parse(date);
  }).toList();

  return dateTimes;
}

Future<String> getUserId() async {
  Map<String, dynamic> user = await getUserFromSharedPreference();
  return user['_id'];
}

String getHourFromResponse(double s) {
  return s.toInt().toString();
}

String getMinuteFromResponse(double s) {
  return ((s - s.toInt()) * 60).toInt().toString();
}

double toDouble(dynamic value) {
  if (value.runtimeType == int) {
    return value.toDouble();
  } else if (value.runtimeType == double) {
    return value;
  } else {
    throw ArgumentError("Value must be numeric.");
  }
}

double getHourInDouble(String hour, String minute) {
  return int.parse(hour) + (int.parse(minute) / 60);
}

int timeOfDayToInt(TimeOfDay time) {
  return time.hour * 60 + time.minute;
}

String getSleepPayload(
    TimeOfDay bedGoal,
    TimeOfDay wakeUpGoal,
    int totalBehaviorInMinutes,
    int totalGoalInMinutes,
    TimeOfDay bedBehavior,
    TimeOfDay wakeUpBehavior,
    String userId,
    String feedback,
    String reflection) {
  double behaviorValue = totalBehaviorInMinutes / 60;
  double goalValue = totalGoalInMinutes / 60;

  bool goalStatus = behaviorValue >= goalValue;
  String date = getNowInFormat(dateFormat);
  String dateToday = getNowInFormat('yyyy-MM-ddTHH:mm:ss.SSSZ');

  Map<String, dynamic> sleep = {
    'bedBehavior': timeOfDayToInt(bedBehavior),
    'wakeUpBehavior': timeOfDayToInt(wakeUpBehavior),
    'bedGoal': timeOfDayToInt(bedGoal),
    'wakeUpGoal': timeOfDayToInt(wakeUpGoal)
  };

  Map<String, dynamic> payload = {
    'behaviorValue': behaviorValue,
    'goalValue': goalValue,
    'reflection': reflection,
    'feedback': feedback,
    'date': date,
    'goalStatus': goalStatus,
    'user': userId,
    'recommendedValue': recommendedSleepValue,
    'goalType': 'sleep',
    'dateToday': dateToday,
    'sleep': sleep
  };

  return jsonEncode(payload);
}

String getEatingPayload(String goal, String behavior, String userId,
    String feedback, String reflection) {
  int goalValue = int.parse(goal);
  int behaviorValue = int.parse(behavior);

  bool goalStatus = behaviorValue >= goalValue;
  String date = getNowInFormat(dateFormat);
  String dateToday = getNowInFormat('yyyy-MM-ddTHH:mm:ss.SSSZ');

  Map<String, dynamic> payload = {
    'behaviorValue': behaviorValue,
    'goalValue': goalValue,
    'reflection': reflection,
    'feedback': feedback,
    'date': date,
    'goalStatus': goalStatus,
    'user': userId,
    'recommendedValue': recommendedEatingValue,
    'goalType': 'eating',
    'dateToday': dateToday
  };

  return jsonEncode(payload);
}

String getChatbotPayloadForSleep(int totalGoalInMinutes,
    int totalBehaviorInMinutes, String reflection) {
  double totalGoal = totalGoalInMinutes / 60;
  double totalBehavior = totalBehaviorInMinutes / 60;

  double percentageAchieved = (totalBehavior / totalGoal) * 100;

  double percentageOfRecommendedGoal = (totalBehavior / 9) * 100;

  String content = "Health goal type: sleep, "
      "Recommended value: $recommendedSleepValue, "
      "Actual Goal Value: ${totalGoal.toStringAsFixed(2)}, "
      "Actual behavior value achieved: ${totalBehavior.toStringAsFixed(2)}, "
      "percentage of actual goal achieved: ${percentageAchieved.toStringAsFixed(2)}%, "
      "percentage of recommended goal achieved: ${percentageOfRecommendedGoal.toStringAsFixed(2)}%, "
      "Reflection: $reflection.";

  Map<String, List<Map<String, String>>> payload = {
    'prompt': [
      {'role': 'system', 'content': content}
    ]
  };

  return jsonEncode(payload);
}

String getChatbotPayloadFor(
    int totalGoal, int totalBehavior, String reflection, String type, int recommendedValue) {

  String systemContent = "Provide feedback based on the user's actual behavior compared to both their set personal goals and default recommended value.";
  String userContent = "Goal Type: $type, "
      "Recommended value by default: $recommendedValue minutes, "
      "Personal goal that student set: $totalGoal minutes, "
      "Goal that student achieved: $totalBehavior minutes, "
      "Reflection: $reflection, "
      "Personal goal met: ${totalBehavior >= totalGoal}, "
      "Recommended goal met: ${totalBehavior >= recommendedValue}";

  Map<String, List<Map<String, String>>> payload = {
    'prompt': [
      {'role': 'system', 'content': systemContent},
      {'role': 'system', 'content': userContent}
    ]
  };

  return jsonEncode(payload);
}

String getChatbotPayloadForEating(
    int goal, int behavior, String reflection) {
  String systemContent = "Provide feedback based on the user's actual behavior compared to both their set personal goals and default recommended value.";
  String userContent = "Goal Type: Eating, "
      "Recommended value by default: $recommendedEatingValue servings, "
      "Personal goal that student set: $goal servings, "
      "Goal that student achieved: $behavior servings, "
      "Reflection: $reflection, "
      "Personal goal met: ${behavior >= goal}, "
      "Recommended goal met: ${behavior >= recommendedEatingValue}";

  Map<String, List<Map<String, String>>> payload = {
    'prompt': [
      {'role': 'system', 'content': systemContent},
      {'role': 'system', 'content': userContent}
    ]
  };

  return jsonEncode(payload);
}

String calculateTimeDifference(TimeOfDay startTime, TimeOfDay endTime) {
  int startMinutes = startTime.hour * 60 + startTime.minute;
  int endMinutes = endTime.hour * 60 + endTime.minute;

  int difference = endMinutes - startMinutes;

  if (difference < 0) {
    difference = 24 * 60 + difference;
  }

  return difference.toString();
}

String getTimeToDisplay(TimeOfDay time) {
  return '${time.hourOfPeriod}:${getDoubleDigitMinute(time.minute)} ${time.period.name}';
}

String getDoubleDigitMinute(int timeOfDayMinute) {
  String minute = timeOfDayMinute.toString();

  return minute.length == 1 ? '0$minute' : minute;
}
