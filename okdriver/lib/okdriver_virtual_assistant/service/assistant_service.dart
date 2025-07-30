import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/chat_message.dart';

class AssistantService {
  // Base URL for the backend API
  static const String baseUrl = 'http://192.168.0.101:3000';

  // Send a message to the backend API
  Future<Map<String, dynamic>> sendMessage(
      String message, String userId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/chat'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'message': message,
          'userId': userId,
        }),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to send message: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Check audio status
  Future<Map<String, dynamic>> checkAudioStatus(String audioId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/audio-status/$audioId'),
      );

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to check audio status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Get conversation history
  Future<List<ChatMessage>> getHistory(String userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/history/$userId'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> historyData = data['history'];

        return historyData.map((item) {
          return ChatMessage(
            text: item['content'],
            isUser: item['role'] == 'user',
          );
        }).toList();
      } else {
        throw Exception('Failed to get history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }

  // Clear conversation history
  Future<void> clearHistory(String userId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/api/history/$userId'),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to clear history: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Network error: $e');
    }
  }
}
