import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'utils/area_calculator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  final MapController _mapController = MapController();
  List<LatLng> polygonPoints = [];
  double? calculatedAcres;
  bool isPolygonComplete = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapbox Polygon Area Calculator'),
        elevation: 2,
      ),
      body: SafeArea(
        child: Stack(
          children: [
          // Flutter Map
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: const LatLng(37.7749, -122.4194), // San Francisco
              initialZoom: 12.0,
              onTap: _onMapTapped,
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.example.flutter_mapbox_polygon_poc',
              ),
              // Points layer
              MarkerLayer(
                markers: polygonPoints.map((point) => 
                  Marker(
                    point: point,
                    width: 16,
                    height: 16,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                        border: Border.symmetric(
                          horizontal: BorderSide(color: Colors.white, width: 2),
                          vertical: BorderSide(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                  ),
                ).toList(),
              ),
              // Polygon layer
              if (polygonPoints.length > 1)
                PolylineLayer(
                  polylines: [
                    Polyline(
                      points: isPolygonComplete 
                          ? [...polygonPoints, polygonPoints.first]
                          : polygonPoints,
                      color: Colors.blue,
                      strokeWidth: 3,
                    ),
                  ],
                ),
              // Fill layer for completed polygon
              if (isPolygonComplete && polygonPoints.length >= 3)
                PolygonLayer(
                  polygons: [
                    Polygon(
                      points: polygonPoints,
                      color: Colors.blue.withOpacity(0.3),
                      borderColor: Colors.blue,
                      borderStrokeWidth: 3,
                    ),
                  ],
                ),
            ],
          ),
          
          // Area Display Card
          if (calculatedAcres != null)
            Positioned(
              top: 16,
              left: 16,
              right: 16,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Polygon Area',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${calculatedAcres!.toStringAsFixed(2)} acres',
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                      Text(
                        '${(calculatedAcres! * 4046.86).toStringAsFixed(0)} m²',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          
          // Points Counter
          if (polygonPoints.isNotEmpty && !isPolygonComplete)
            Positioned(
              top: 16,
              left: 16,
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  child: Text(
                    '${polygonPoints.length} point${polygonPoints.length != 1 ? 's' : ''}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          
          // Control Buttons
          Positioned(
            bottom: 16,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (polygonPoints.length >= 3 && !isPolygonComplete)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton.icon(
                        onPressed: _completePolygon,
                        icon: const Icon(Icons.check),
                        label: const Text('Complete'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
                if (polygonPoints.isNotEmpty)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ElevatedButton.icon(
                        onPressed: _clearPolygon,
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
        ),
      ),
    );
  }

  /// Handle map tap to add polygon points
  void _onMapTapped(TapPosition tapPosition, LatLng point) async {
    if (isPolygonComplete) return; // Don't add points if polygon is complete

    setState(() {
      polygonPoints.add(point);
    });
  }

  /// Complete the polygon and calculate area
  Future<void> _completePolygon() async {
    if (polygonPoints.length < 3) return;

    setState(() {
      isPolygonComplete = true;
    });

    // Calculate area using the AreaCalculator
    double areaInAcres = AreaCalculator.calculatePolygonAreaInAcres(polygonPoints);
    
    setState(() {
      calculatedAcres = areaInAcres;
    });
  }

  /// Clear the polygon and reset
  Future<void> _clearPolygon() async {
    setState(() {
      polygonPoints.clear();
      calculatedAcres = null;
      isPolygonComplete = false;
    });
  }
}


