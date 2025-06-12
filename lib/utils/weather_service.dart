import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WeatherService {
  static const String _apiKey = 'c37443c8d1ad4551a4d91810251206'; // Replace with your key
  static const String _baseUrl = 'http://api.weatherapi.com/v1/current.json';

  static Future<Map<String, dynamic>?> fetchWeather(String location) async {
    final url = '$_baseUrl?key=$_apiKey&q=$location';

    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return {
        'temp_c': data['current']['temp_c'],
        'humidity': data['current']['humidity'],
        'icon': data['current']['condition']['icon'],
        'condition': data['current']['condition']['text'],
      };
    } else {
      if (kDebugMode) {
        print('Weather API error: ${response.statusCode}');
      }
      return null;
    }
  }
}
