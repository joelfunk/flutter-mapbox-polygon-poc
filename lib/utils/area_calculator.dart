import 'dart:math';
import 'package:latlong2/latlong.dart';

/// Utility class for calculating polygon areas on Earth's surface
class AreaCalculator {
  // Earth's radius in meters
  static const double EARTH_RADIUS = 6371000;
  
  // Conversion factor: 1 acre = 4046.86 square meters
  static const double SQUARE_METERS_PER_ACRE = 4046.86;

  /// Calculate the area of a polygon in acres using the Haversine formula
  /// for geodesic calculations (accounts for Earth's curvature)
  static double calculatePolygonAreaInAcres(List<LatLng> points) {
    if (points.length < 3) return 0.0;

    double areaInSquareMeters = _calculatePolygonAreaInSquareMeters(points);
    return areaInSquareMeters / SQUARE_METERS_PER_ACRE;
  }

  /// Calculate polygon area in square meters using spherical excess method
  /// This method is accurate for polygons on Earth's curved surface
  static double _calculatePolygonAreaInSquareMeters(List<LatLng> points) {
    if (points.length < 3) return 0.0;

    // Convert coordinates to radians and calculate spherical excess
    double total = 0.0;

    for (int i = 0; i < points.length; i++) {
      LatLng p1 = points[i];
      LatLng p2 = points[(i + 1) % points.length];

      double lat1 = _toRadians(p1.latitude);
      double lat2 = _toRadians(p2.latitude);
      double lng1 = _toRadians(p1.longitude);
      double lng2 = _toRadians(p2.longitude);

      total += (lng2 - lng1) * (2 + sin(lat1) + sin(lat2));
    }

    double area = (total * EARTH_RADIUS * EARTH_RADIUS / 2).abs();
    return area;
  }

  /// Alternative simpler calculation using Shoelace formula (less accurate for large areas)
  /// This assumes a flat plane, which is acceptable for small polygons
  static double calculatePolygonAreaSimple(List<LatLng> points) {
    if (points.length < 3) return 0.0;

    double area = 0.0;
    int j = points.length - 1;

    for (int i = 0; i < points.length; i++) {
      area += (points[j].longitude + points[i].longitude) * 
              (points[j].latitude - points[i].latitude);
      j = i;
    }

    // Convert to square meters (approximate)
    area = (area.abs() / 2) * 111320 * 111320 * cos(_toRadians(points[0].latitude));
    
    return area / SQUARE_METERS_PER_ACRE;
  }

  /// Convert degrees to radians
  static double _toRadians(double degrees) {
    return degrees * pi / 180.0;
  }

  /// Convert radians to degrees
  static double _toDegrees(double radians) {
    return radians * 180.0 / pi;
  }

  /// Calculate the distance between two points using Haversine formula
  static double calculateDistance(LatLng point1, LatLng point2) {
    double lat1 = _toRadians(point1.latitude);
    double lat2 = _toRadians(point2.latitude);
    double dLat = _toRadians(point2.latitude - point1.latitude);
    double dLng = _toRadians(point2.longitude - point1.longitude);

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLng / 2) * sin(dLng / 2);
    double c = 2 * atan2(sqrt(a), sqrt(1 - a));

    return EARTH_RADIUS * c;
  }
}
