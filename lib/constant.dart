import 'package:flutter/material.dart' show Color;

const List<String> months = [
  'January',
  'February',
  'March',
  'April',
  'May',
  'June',
  'July',
  'August',
  'September',
  'October',
  'November',
  'December',
];

const List<String> grades = [
  '5th',
  '6th',
  '7th',
  '8th',
  '9th',
];

const List<String> genders = [
  'Male',
  'Female',
  'Other',
  'Prefer not to tell',
];

const String charSets =
    'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

const String miniLogoPath = 'assets/images/proudme_logo_mini.png';
const String schoolKidsPicPath = 'assets/images/school_kids.png';
const String mainLogoPath = 'assets/images/proudme_logo.png';
const String appleIconPath = 'assets/icons/apple.svg';

const String fontFamily = 'Montserrat';

const String labEmail = 'pklab@lsu.edu';
const String piEmail = 'senlinchen@lsu.edu';

const String authTokenKey = 'authToken';
const String userDataKey = 'userData';

const Color errorColor = Color.fromRGBO(255, 0, 0, 0.8);
const List<String> myJournalItems = [
  'Physical Activity',
  'Screen Time',
  'Fruits & Vegetables',
  'Sleep'
];
const secondaryColor = Color(0xfff5b342);

Map<String, List<String>> activityTypes = {
  'Strenuous': ['Running', 'Jogging', 'Football', 'Soccer', 'Basketball'],
  'Moderate': ['Baseball', 'Tennis', 'Fast Walking', 'Volleyball', 'Badminton'],
  'Mild': ['Yoga', 'Archery', 'Bowling', 'Golf', 'Easy Walking']
};

const List<String> activityList = [
  'Running',
  'Jogging',
  'Football',
  'Soccer',
  'Basketball',
  'Baseball',
  'Tennis',
  'Fast Walking',
  'Volleyball',
  'Badminton',
  'Yoga',
  'Archery',
  'Bowling',
  'Golf',
  'Easy Walking'
];

const List<String> screenTimeType = ['Academic', 'Non-Academic'];
const List<String> eatingType = ['Fruits', 'Vegetables'];

const dateFormat = 'M/d/yyyy';
const recommendedSleepValue = 9;
const recommendedEatingValue = 5;
const recommendedPhysicalActivityValue = 60;
const recommendedScreenTimeValue = 120;
const baseHttpHeader = {
  'Content-Type': 'application/json',
};
