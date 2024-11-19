import 'package:flutter/material.dart';
import 'package:flutter_todo_testing_app/todo_app.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'model/todo.dart';


void main() => runApp(MaterialApp(
  home: ToDoApp(),
  debugShowCheckedModeBanner: false,
));
