import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import '../../../../utils/constants/colors.dart';
import '../../models/order_model.dart';

class DeliveryMapView extends StatefulWidget {
  final OrderModel order;
  const DeliveryMapView({super.key, required this.order});

  @override
  State<DeliveryMapView> createState() => _DeliveryMapViewState();
}

class _DeliveryMapViewState extends State<DeliveryMapView> {
  final MapController _mapController = MapController();
  List<LatLng> routePoints = [];
  String travelTime = "";
  String distanceText = "";
  http.Client? _httpClient;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    _httpClient = http.Client();
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchRoute());
  }

  @override
  void dispose() {
    _isDisposed = true;
    _httpClient?.close(); // Properly close the HTTP client
    super.dispose();
  }

  Future<void> _showSnack(String title, String msg) async {
    if (_isDisposed) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_isDisposed) {
        Get.snackbar(title, msg, snackPosition: SnackPosition.TOP);
      }
    });
  }

  String _formatTravelTime(double milliseconds) {
    final totalMinutes = (milliseconds / 60000).round();
    if (totalMinutes < 60) {
      return '${totalMinutes} min';
    } else {
      final hours = totalMinutes ~/ 60;
      final minutes = totalMinutes % 60;
      if (minutes == 0) {
        return '${hours}h';
      } else {
        return '${hours}h ${minutes}min';
      }
    }
  }

  Future<void> _fetchRoute() async {
    try {
      final clientLat = widget.order.address?.latitude ?? 0.0;
      final clientLng = widget.order.address?.longitude ?? 0.0;
      final restoLat = widget.order.etablissement?.latitude ?? 0.0;
      final restoLng = widget.order.etablissement?.longitude ?? 0.0;

      if (clientLat == 0.0 ||
          clientLng == 0.0 ||
          restoLat == 0.0 ||
          restoLng == 0.0) {
        await _showSnack("Erreur", "Coordonnées invalides pour la commande.");
        return;
      }

      final apiKey = dotenv.env['GRAPHHOPPER_API_KEY'] ?? '';
      if (apiKey.isEmpty) {
        await _showSnack("Erreur", "Clé API GraphHopper non configurée.");
        return;
      }

      final url = Uri.parse(
        'https://graphhopper.com/api/1/route?point=$restoLat,$restoLng&point=$clientLat,$clientLng&vehicle=car&points_encoded=false&key=$apiKey',
      );

      final res =
          await _httpClient!.get(url).timeout(const Duration(seconds: 30));

      if (_isDisposed) return;

      if (res.statusCode != 200) {
        throw Exception('Erreur API: ${res.statusCode} ${res.body}');
      }

      final data = jsonDecode(res.body) as Map<String, dynamic>;
      if (data['paths'] == null || (data['paths'] as List).isEmpty) {
        throw Exception('Aucun chemin retourné par l\'API');
      }

      final path = (data['paths'] as List).first as Map<String, dynamic>;

      final distance = (path['distance'] as num?)?.toDouble() ?? 0.0;
      final time = (path['time'] as num?)?.toDouble() ?? 0.0;

      final pointsObj = path['points'] as Map<String, dynamic>?;
      final coords = pointsObj != null
          ? (pointsObj['coordinates'] as List<dynamic>?) ?? []
          : [];

      if (coords.isEmpty) {
        await _showSnack("Erreur", "Itinéraire introuvable (aucun point).");
        return;
      }

      final points = <LatLng>[];
      for (final coord in coords) {
        if (coord is List && coord.length >= 2) {
          final lon = double.tryParse(coord[0].toString()) ?? 0.0;
          final lat = double.tryParse(coord[1].toString()) ?? 0.0;
          if (lat != 0.0 && lon != 0.0) {
            points.add(LatLng(lat, lon));
          }
        }
      }

      if (points.isEmpty) {
        await _showSnack(
            "Erreur", "Impossible de parser les coordonnées de l'itinéraire.");
        return;
      }

      if (_isDisposed) return;

      setState(() {
        distanceText = "${(distance / 1000).toStringAsFixed(1)} km";
        travelTime = _formatTravelTime(time);
        routePoints = points;
      });

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_isDisposed || routePoints.isEmpty) return;

        try {
          final bounds = LatLngBounds.fromPoints(routePoints);
          final center = bounds.center;

          final sw = bounds.southWest;
          final ne = bounds.northEast;
          final meters = Distance().distance(
            LatLng(sw.latitude, sw.longitude),
            LatLng(ne.latitude, ne.longitude),
          );

          final zoom = _zoomForDistance(meters);
          _mapController.move(center, zoom);
        } catch (e) {
          debugPrint('Error fitting map to bounds: $e');
          final center = routePoints[(routePoints.length / 2).floor()];
          _mapController.move(center, 13.0);
        }
      });
    } catch (e) {
      if (_isDisposed) return;
      await _showSnack("Erreur", "Impossible de récupérer l'itinéraire: $e");
      debugPrint("Route fetch error: $e");
    }
  }

  void _zoomIn() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom + 1);
  }

  void _zoomOut() {
    final currentZoom = _mapController.camera.zoom;
    _mapController.move(_mapController.camera.center, currentZoom - 1);
  }

  @override
  Widget build(BuildContext context) {
    final clientLat = widget.order.address?.latitude ?? 0.0;
    final clientLng = widget.order.address?.longitude ?? 0.0;
    final restoLat = widget.order.etablissement?.latitude ?? 0.0;
    final restoLng = widget.order.etablissement?.longitude ?? 0.0;

    final initialCenter = routePoints.isNotEmpty
        ? routePoints[(routePoints.length / 2).floor()]
        : (clientLat != 0.0 && clientLng != 0.0
            ? LatLng(clientLat, clientLng)
            : (restoLat != 0.0 && restoLng != 0.0
                ? LatLng(restoLat, restoLng)
                : const LatLng(0, 0)));

    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(
            initialCenter: initialCenter,
            initialZoom: 13,
            keepAlive: true,
          ),
          children: [
            TileLayer(
              urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
              userAgentPackageName: 'com.example.app',
            ),
            if (routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [
                  Polyline(
                    points: routePoints,
                    strokeWidth: 5,
                    color: AppColors.primary,
                  ),
                ],
              ),
            MarkerLayer(
              markers: [
                if (restoLat != 0.0 && restoLng != 0.0)
                  Marker(
                    point: LatLng(restoLat, restoLng),
                    width: 60,
                    height: 60,
                    child: const Icon(Icons.store, color: Colors.red, size: 36),
                  ),
                if (clientLat != 0.0 && clientLng != 0.0)
                  Marker(
                    point: LatLng(clientLat, clientLng),
                    width: 60,
                    height: 60,
                    child: const Icon(Icons.person_pin_circle,
                        color: Colors.blue, size: 36),
                  ),
              ],
            ),
          ],
        ),

        // Travel info badge
        if (travelTime.isNotEmpty || distanceText.isNotEmpty)
          Positioned(
            top: 16,
            left: 16,
            right: 16,
            child: SafeArea(
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.eerieBlack,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black12,
                        blurRadius: 6,
                        offset: const Offset(0, 3))
                  ],
                ),
                child: Text(
                  "🕒 ${travelTime.isNotEmpty ? travelTime : '-'} | 📍 ${distanceText.isNotEmpty ? distanceText : '-'}",
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),

        // Zoom controls
        Positioned(
          bottom: 100,
          right: 16,
          child: SafeArea(
            child: Column(
              children: [
                FloatingActionButton.small(
                  heroTag: "zoom_in",
                  onPressed: _zoomIn,
                  child: const Icon(Icons.add),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: "zoom_out",
                  onPressed: _zoomOut,
                  child: const Icon(Icons.remove),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

double _zoomForDistance(double meters) {
  final km = meters / 1000.0;
  if (km < 0.05) return 18.0;
  if (km < 0.3) return 17.0;
  if (km < 0.8) return 16.0;
  if (km < 2.0) return 15.0;
  if (km < 5.0) return 14.0;
  if (km < 15.0) return 13.0;
  if (km < 30.0) return 12.0;
  if (km < 60.0) return 11.0;
  if (km < 120.0) return 10.0;
  return 9.0;
}
