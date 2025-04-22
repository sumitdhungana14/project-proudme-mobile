import 'package:flutter/material.dart';
import 'package:project_proud_me/endpoints.dart';
import 'package:project_proud_me/widgets/calendar.dart';
import 'package:project_proud_me/widgets/app_drawer.dart';
import 'package:project_proud_me/introduction/introduction.dart';
import 'package:project_proud_me/utils/helpers.dart';
import 'package:project_proud_me/language.dart';
import 'package:project_proud_me/constant.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class DailyReportPage extends StatefulWidget {
  const DailyReportPage({Key? key}) : super(key: key);

  @override
  State<DailyReportPage> createState() => _DailyReportPageState();
}

class _DailyReportPageState extends State<DailyReportPage> {
  String? _selectedDay;
  bool _isLoading = false;
  late String _userId;
  bool _isFetchingJournalDates = false;
  Map<String, dynamic> _activityData = {};
  Map<String, dynamic> _sleepData = {};
  Map<String, dynamic> _screenTimeData = {};
  Map<String, dynamic> _eatData = {};
  List<DateTime> _highlightedDates = [];

  Future<void> _setUserId() async {
    setState(() {
      _isLoading = true;
    });
    var userId = await getUserId();
    setState(() {
      _userId = userId;
      _isLoading = false;
    });
    _getJournalDates();
  }

  Future<dynamic> _getEatData(String day) async {
    try {
      setState(() {
        _isLoading = true;
    });

    String queryString =
          getQueryParams(_userId, 'eating', day);

    final response = await http.get(Uri.parse('$getGoal?$queryString'));

    if (response.statusCode == 200) {
        List<dynamic> responseBody = json.decode(response.body);

        if (responseBody.isNotEmpty) {
          _eatData = responseBody.first as Map<String, dynamic>;
        } else {
          _eatData = {};
        }
      } else {
        _eatData = {};
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      return {};
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<dynamic> _getActivityData(String day) async {
    try {
      setState(() {
        _isLoading = true;
    });

    String queryString =
          getQueryParams(_userId, 'activity', day);

    final response = await http.get(Uri.parse('$getGoal?$queryString'));

    if (response.statusCode == 200) {
        List<dynamic> responseBody = json.decode(response.body);

        if (responseBody.isNotEmpty) {
          _activityData = responseBody.first as Map<String, dynamic>;
        } else {
          _activityData = {};
        }
      } else {
        _activityData = {};
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      return {};
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<dynamic> _getSleepData(String day) async {
    try {
      setState(() {
        _isLoading = true;
      });

      String queryString =
            getQueryParams(_userId, 'sleep', day);

      final response = await http.get(Uri.parse('$getGoal?$queryString'));

      if (response.statusCode == 200) {
        List<dynamic> responseBody = json.decode(response.body);

          if (responseBody.isNotEmpty) {
            _sleepData = responseBody.first as Map<String, dynamic>;
          } else {
            _sleepData = {};
          }
        } else {
          _sleepData = {};
          throw Exception('Failed to fetch data: ${response.statusCode}');
        }
      } catch (e) {
        print('Error: $e');
        return {};
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
  }

  Future<dynamic> _getScreenTimeData(String day) async {
    try {
      setState(() {
        _isLoading = true;
      });

      String queryString =
            getQueryParams(_userId, 'screentime', day);

      final response = await http.get(Uri.parse('$getGoal?$queryString'));

      if (response.statusCode == 200) {
        List<dynamic> responseBody = json.decode(response.body);

        if (responseBody.isNotEmpty) {
          _screenTimeData = responseBody.first as Map<String, dynamic>;
        } else {
          _screenTimeData = {};
        }
      } else {
        _screenTimeData = {};
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
        print('Error: $e');
        return {};
    } finally {
        setState(() {
          _isLoading = false;
        });
    }
  }

    Future<void> _getJournalDates() async {
    try {
      setState(() {
        _isFetchingJournalDates = true;
      });

    String queryString =
          getJournalDateParams(_userId);

    final response = await http.get(Uri.parse('$journalDates?$queryString'));

    if (response.statusCode == 200) {
        List<dynamic> responseBody = json.decode(response.body);

        if (responseBody.isNotEmpty) {
          _highlightedDates = getDateInCalendarFormat(List<String>.from(responseBody));
        } else {
          _highlightedDates = [];
        }
      } else {
        _highlightedDates = [];
        throw Exception('Failed to fetch journal dates: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      setState(() {
        _isFetchingJournalDates = false;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _setUserId();
  }

  String _formatValue(dynamic value, String title) {
    if (value == null) return '0 ${title == 'Fruits & Vegetables' ? 'Servings' : 'hrs'}';

    if (title == 'Fruits & Vegetables') {
      return '${value.toString()} Servings';
    } else if (title == 'Sleep') {
      final double hours = (value is num ? value : double.tryParse(value.toString()) ?? 0) / 1.0;
      return '${hours.toStringAsFixed(2)} hrs';
    }
    else {
      final double hours = (value is num ? value : double.tryParse(value.toString()) ?? 0) / 60.0;
      return '${hours.toStringAsFixed(2)} hrs';
    }
  }

  String _formatText(dynamic text) {
    if (text == null || text.toString().trim().isEmpty) {
      return 'N/A';
    }
    return text.toString();
  }

  Widget _buildReportCard(String title, Map<String, dynamic> data) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Goal: ${_formatValue(data['goalValue'], title)}',
              ),
              const SizedBox(height: 3),
              Text(
                'Behavior: ${_formatValue(data['behaviorValue'], title)}',
              ),
              const SizedBox(height: 3),
              Text(
                'Reflection: ${_formatText(data['reflection'])}',
              ),
              const SizedBox(height: 3),
              Text(
                'AI Feedback: ${_formatText(data['feedback'])}',
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      ),
      drawer: MyDrawer(),
      body: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  'Daily Report',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    fontFamily: fontFamily,
                    color: Theme.of(context).primaryColor,
                  ),
                ),
                CustomCalendar(
                  onDateSelected: (day) {
                    _selectedDay = day;
                    _getActivityData(day);
                    _getEatData(day);
                    _getScreenTimeData(day);
                    _getSleepData(day);
                  },
                  highlightedDates: _highlightedDates,
                ),
                _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : Column(
                        children: [
                          const SizedBox(height: 24),
                          Text(
                            _selectedDay == null
                                ? 'Select a date to view report for the day.'
                                : 'Your daily ProudMe report for $_selectedDay',
                            style: const TextStyle(fontSize: 16),
                          ),
                          if (_selectedDay != null)
                            Padding(
                              padding: const EdgeInsets.only(top: 16.0),
                              child: Column(
                                children: [
                                  _buildReportCard('Physical Activity', _activityData),
                                  _buildReportCard('Screen Time', _screenTimeData),
                                  _buildReportCard('Sleep', _sleepData),
                                  _buildReportCard('Fruits & Vegetables', _eatData),
                                ],
                              ),
                            ),
                        ],
                      )
              ],
            ),
          ),
        ),
      ),
 
    );
  }
}
