import 'dart:convert';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

class MapboxPlace {
  final String id;
  final String text;
  final String placeName;
  final double latitude;
  final double longitude;

  MapboxPlace({
    required this.id,
    required this.text,
    required this.placeName,
    required this.latitude,
    required this.longitude,
  });
}

class MapboxService {
  final String _token;

  MapboxService() : _token = dotenv.env['MAPBOX_API_KEY'] ?? '';

  Future<List<MapboxPlace>> searchPlaces(String query,
      {int limit = 5}) async {
    if (_token.isEmpty) return [];
    final encoded = Uri.encodeComponent(query);
    final url = Uri.parse(
        'https://api.mapbox.com/geocoding/v5/mapbox.places/$encoded.json?access_token=$_token&autocomplete=true&limit=$limit');

    final resp = await http.get(url);
    if (resp.statusCode != 200) return [];
    final body = json.decode(resp.body) as Map<String, dynamic>;
    final features = body['features'] as List<dynamic>;
    return features.map((f) {
      final geometry = f['geometry'] as Map<String, dynamic>;
      final coords = geometry['coordinates'] as List<dynamic>;
      return MapboxPlace(
        id: f['id'] as String,
        text: f['text'] as String? ?? '',
        placeName: f['place_name'] as String? ?? '',
        longitude: (coords[0] as num).toDouble(),
        latitude: (coords[1] as num).toDouble(),
      );
    }).toList();
  }
}
