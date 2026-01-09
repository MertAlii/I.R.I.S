import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError('Initialize StorageService in main.dart');
});

class StorageService {
  final SharedPreferences _prefs;

  StorageService(this._prefs);

  // Constants for keys
  static const String _keyName = 'user_name';
  static const String _keySurgeryDate = 'surgery_date';
  static const String _keySurgeryType = 'surgery_type';
  static const String _keySurveys = 'daily_surveys';

  // Surgery Data Methods
  Future<void> saveSurgeryData(String name, DateTime date, String type) async {
    await _prefs.setString(_keyName, name);
    await _prefs.setString(_keySurgeryDate, date.toIso8601String());
    await _prefs.setString(_keySurgeryType, type);
  }

  bool hasSurgeryData() {
    return _prefs.containsKey(_keyName) && _prefs.containsKey(_keySurgeryDate);
  }

  Map<String, dynamic>? getUserData() {
    final name = _prefs.getString(_keyName);
    final dateStr = _prefs.getString(_keySurgeryDate);
    
    if (name != null && dateStr != null) {
      return {
        'name': name,
        'surgeryDate': DateTime.parse(dateStr),
        'surgeryType': _prefs.getString(_keySurgeryType),
      };
    }
    return null;
  }

  // Survey Methods
  Future<void> saveDailySurvey(int painLevel, List<String> symptoms, String note) async {
    List<String> currentSurveys = _prefs.getStringList(_keySurveys) ?? [];
    
    final survey = {
      'painLevel': painLevel,
      'symptoms': symptoms,
      'note': note,
      'date': DateTime.now().toIso8601String(),
    };

    currentSurveys.add(jsonEncode(survey));
    await _prefs.setStringList(_keySurveys, currentSurveys);
  }

  Future<bool> isDailySurveyDone() async {
    final surveys = await getWeeklySurveys(); // Reusing the parsing logic logic
    if (surveys.isEmpty) return false;

    final today = DateTime.now();
    final todayStr = "${today.year}-${today.month}-${today.day}";
    
    for (var s in surveys) {
      final date = DateTime.parse(s['date']);
      final surveyDateStr = "${date.year}-${date.month}-${date.day}";
      if (todayStr == surveyDateStr) return true;
    }
    return false;
  }

  Future<int> getSurveyCount() async {
    final list = _prefs.getStringList(_keySurveys);
    return list?.length ?? 0;
  }

  Future<List<Map<String, dynamic>>> getWeeklySurveys() async {
    List<String> rawList = _prefs.getStringList(_keySurveys) ?? [];
    List<Map<String, dynamic>> parsedList = [];

    final now = DateTime.now();
    final sevenDaysAgo = now.subtract(const Duration(days: 7));

    for (var item in rawList) {
      try {
        final Map<String, dynamic> data = jsonDecode(item);
        final date = DateTime.parse(data['date']);
        
        if (date.isAfter(sevenDaysAgo)) {
          parsedList.add(data);
        }
      } catch (e) {
        print("Error parsing survey: $e");
      }
    }
    
    // Sort by date descending
    parsedList.sort((a, b) {
      DateTime dateA = DateTime.parse(a['date']);
      DateTime dateB = DateTime.parse(b['date']);
      return dateB.compareTo(dateA);
    });

    return parsedList;
  }

  static const String _keyApiKey = 'groq_api_key';

  // API Key Methods
  Future<void> saveApiKey(String apiKey) async {
    await _prefs.setString(_keyApiKey, apiKey);
  }

  String? getApiKey() {
    return _prefs.getString(_keyApiKey);
  }

  Future<void> clearAllData() async {
    await _prefs.clear();
  }
}
