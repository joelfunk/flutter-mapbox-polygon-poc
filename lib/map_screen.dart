import 'package:flutter/material.dart';
import 'package:mapbox_gl/mapbox_gl.dart';
import 'utils/area_calculator.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({Key? key}) : super(key: key);

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  // TODO: Replace with your Mapbox access token
  static const String MAPBOX_ACCESS_TOKEN = 'YOUR_MAPBOX_ACCESS_TOKEN_HERE';
  
  MapboxMapController? mapController;
  List<LatLng> polygonPoints = [];
  List<Circle> circles = [];
  Line? polygonLine;
  Fill? polygonFill;
  double? calculatedAcres;
  bool isPolygonComplete = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mapbox Polygon Area Calculator'),
        elevation: 2,
      ),
      body: Stack(
        children: [
          // Mapbox Map
          MapboxMap(
            accessToken: MAPBOX_ACCESS_TOKEN,
            onMapCreated: _onMapCreated,
            initialCameraPosition: const CameraPosition(
              target: LatLng(37.7749, -122.4194), // San Francisco
              zoom: 12.0,
            ),
            onMapClick: _onMapTapped,
            myLocationEnabled: true,
            myLocationTrackingMode: MyLocationTrackingMode.None,
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
    );
  }

  void _onMapCreated(MapboxMapController controller) {
    mapController = controller;
  }

  /// Handle map tap to add polygon points
  void _onMapTapped(Point<double> point, LatLng coordinates) async {
    if (isPolygonComplete) return; // Don't add points if polygon is complete

    setState(() {
      polygonPoints.add(coordinates);
    });

    // Add a circle marker for the point
    await _addCircleMarker(coordinates);
    
    // Update the polygon line
    if (polygonPoints.length > 1) {
      await _updatePolygonLine();
    }
  }

  /// Add a circle marker at the tapped location
  Future<void> _addCircleMarker(LatLng position) async {
    if (mapController == null) return;

    await mapController!.addCircle(
      CircleOptions(
        geometry: position,
        circleRadius: 8,
        circleColor: '#3388ff',
        circleStrokeColor: '#ffffff',
        circleStrokeWidth: 2,
      ),
    );
  }

  /// Update the polygon line connecting all points
  Future<void> _updatePolygonLine() async {
    if (mapController == null) return;

    // Remove existing line
    if (polygonLine != null) {
      await mapController!.removeLine(polygonLine!);
    }

    // Create new line
    polygonLine = await mapController!.addLine(
      LineOptions(
        geometry: polygonPoints,
        lineColor: '#3388ff',
        lineWidth: 3,
        lineOpacity: 0.8,
      ),
    );
  }

  /// Complete the polygon and calculate area
  Future<void> _completePolygon() async {
    if (polygonPoints.length < 3 || mapController == null) return;

    setState(() {
      isPolygonComplete = true;
    });

    // Close the polygon by connecting to the first point
    List<LatLng> closedPolygon = [...polygonPoints, polygonPoints.first];

    // Remove the line and add a filled polygon
    if (polygonLine != null) {
      await mapController!.removeLine(polygonLine!);
    }

    // Add filled polygon
    polygonFill = await mapController!.addFill(
      FillOptions(
        geometry: [closedPolygon],
        fillColor: '#3388ff',
        fillOpacity: 0.3,
        fillOutlineColor: '#3388ff',
      ),
    );

    // Add outline
    polygonLine = await mapController!.addLine(
      LineOptions(
        geometry: closedPolygon,
        lineColor: '#3388ff',
        lineWidth: 3,
      ),
    );

    // Calculate area
    double areaInAcres = AreaCalculator.calculatePolygonAreaInAcres(polygonPoints);
    
    setState(() {
      calculatedAcres = areaInAcres;
    });
  }

  /// Clear the polygon and reset
  Future<void> _clearPolygon() async {
    if (mapController == null) return;

    // Remove all circles
    await mapController!.clearCircles();
    
    // Remove line
    if (polygonLine != null) {
      await mapController!.removeLine(polygonLine!);
      polygonLine = null;
    }

    // Remove fill
    if (polygonFill != null) {
      await mapController!.removeFill(polygonFill!);
      polygonFill = null;
    }

    setState(() {
      polygonPoints.clear();
      circles.clear();
      calculatedAcres = null;
      isPolygonComplete = false;
    });
  }
}
