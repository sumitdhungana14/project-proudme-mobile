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
  late dynamic _activityData;
  late dynamic _sleepData;
  late dynamic _screenTimeData;
  late dynamic _eatData;

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

  Future<dynamic> _getEatData(String day) async {
    try {
      setState(() {
        _isLoading = true;
    });

    String queryString =
          getQueryParams(_userId, 'eating', day);

    final response = await http.get(Uri.parse('$getGoal?$queryString'));

    if (response.statusCode == 200) {
        _eatData = jsonDecode(response.body);
      } else {
        _eatData = [];
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      return null;
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
        _activityData = jsonDecode(response.body);
      } else {
        _activityData = [];
        throw Exception('Failed to fetch data: ${response.statusCode}');
      }
    } catch (e) {
      print('Error: $e');
      return null;
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
          _sleepData = jsonDecode(response.body);
        } else {
          _sleepData = [];
          throw Exception('Failed to fetch data: ${response.statusCode}');
        }
      } catch (e) {
        print('Error: $e');
        return null;
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
          _screenTimeData = jsonDecode(response.body);
        } else {
          _screenTimeData = [];
          throw Exception('Failed to fetch data: ${response.statusCode}');
        }
      } catch (e) {
        print('Error: $e');
        return null;
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
  }

  @override
  void initState() {
    super.initState();
    _setUserId();
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
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            CustomCalendar(
              onDateSelected: (day) {
                _selectedDay = day;
                _getActivityData(day);
                _getEatData(day);
                _getScreenTimeData(day);
                _getSleepData(day);
              },
              highlightedDates: [],
            ),
            _isLoading ? const Center(child: CircularProgressIndicator(),) :
              const SizedBox(height: 24),
              Expanded(
                child: Center(
                  child: Text(
                    _selectedDay == null
                        ? 'Select a date to view report'
                        : 'Report for $_selectedDay',
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
