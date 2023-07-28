import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:voice_search/utils/app_links.dart';

Future<List<String>> fetchData(
    String youtubeVideoCode, String searchWord) async {
  // Construct the URL with query parameters
  final url = Uri.parse(
      '${AppLinks.apiURL}?video_code=$youtubeVideoCode&search_word=$searchWord');

  try {
    final response = await http.get(url);
    if (response.statusCode == 200) {
      final jsonResponse = json.decode(response.body);
      // Check if the 'timestamps' key exists and is a list
      if (jsonResponse.containsKey('timestamps') &&
          jsonResponse['timestamps'] is List) {
        // Assuming the Flask API returns the timestamps as a list of strings
        List<String> timestamps = List<String>.from(jsonResponse['timestamps']);
        return timestamps;
      } else {
        throw Exception('Invalid response from the server.');
      }
    } else {
      throw Exception('Failed to load data from the server.');
    }
  } catch (e) {
    throw Exception('Error occurred: $e');
  }
}
