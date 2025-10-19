import 'package:caferesto/utils/popups/loaders.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class MapPickerScreen extends StatefulWidget {
  final double? initialLatitude;
  final double? initialLongitude;

  const MapPickerScreen({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
  });

  @override
  State<MapPickerScreen> createState() => _MapPickerScreenState();
}

class _MapPickerScreenState extends State<MapPickerScreen> {
  late GoogleMapController _mapController;
  LatLng? _selectedLocation;
  String _selectedAddress = '';
  bool _isLoading = true;
  bool _isGettingAddress = false;

  // Default position (Paris)
  static const LatLng _defaultPosition = LatLng(48.8566, 2.3522);

  @override
  void initState() {
    super.initState();
    _initializeLocation();
  }

  Future<void> _initializeLocation() async {
    try {
      LatLng initialPosition;

      if (widget.initialLatitude != null && widget.initialLongitude != null) {
        initialPosition =
            LatLng(widget.initialLatitude!, widget.initialLongitude!);
      } else {
        // Get current device location
        initialPosition = await _getCurrentLocation();
      }

      setState(() {
        _selectedLocation = initialPosition;
        _isLoading = false;
      });

      // Get address for initial position
      await _getAddressFromLatLng(initialPosition);
    } catch (e) {
      print('Error initializing location: $e');
      setState(() {
        _selectedLocation = _defaultPosition;
        _isLoading = false;
      });
    }
  }

  Future<LatLng> _getCurrentLocation() async {
    try {
      // Check permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw 'Location permissions denied';
        }
      }

      if (permission == LocationPermission.deniedForever) {
        throw 'Location permissions permanently denied';
      }

      // Get current position
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      return LatLng(position.latitude, position.longitude);
    } catch (e) {
      print('Error getting current location: $e');
      throw 'Could not get current location: $e';
    }
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    try {
      setState(() => _isGettingAddress = true);

      List<Placemark> placemarks = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        setState(() {
          _selectedAddress =
              '${place.street ?? ''}, ${place.postalCode ?? ''} ${place.locality ?? ''}, ${place.country ?? ''}';
        });
      }
    } catch (e) {
      print('Error getting address: $e');
      setState(() {
        _selectedAddress = 'Adresse non disponible';
      });
    } finally {
      setState(() => _isGettingAddress = false);
    }
  }

  Future<void> _moveToCurrentLocation() async {
    try {
      setState(() => _isLoading = true);
      final LatLng currentLocation = await _getCurrentLocation();

      _mapController.animateCamera(
        CameraUpdate.newLatLngZoom(currentLocation, 15),
      );

      setState(() {
        _selectedLocation = currentLocation;
      });

      await _getAddressFromLatLng(currentLocation);
    } catch (e) {
      print('Error moving to current location: $e');
      TLoaders.errorSnackBar(
        message: 'Impossible d\'obtenir la localisation actuelle',
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _onMapTap(LatLng latLng) {
    setState(() {
      _selectedLocation = latLng;
    });
    _getAddressFromLatLng(latLng);
  }

  void _confirmSelection() {
    if (_selectedLocation != null) {
      Navigator.pop(context, {
        'latitude': _selectedLocation!.latitude,
        'longitude': _selectedLocation!.longitude,
        'address': _selectedAddress,
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sélectionner la localisation'),
        actions: [
          IconButton(
            icon: const Icon(Icons.my_location),
            onPressed: _moveToCurrentLocation,
            tooltip: 'Ma position actuelle',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Stack(
              children: [
                GoogleMap(
                  onMapCreated: _onMapCreated,
                  initialCameraPosition: CameraPosition(
                    target: _selectedLocation ?? _defaultPosition,
                    zoom: 15,
                  ),
                  onTap: _onMapTap,
                  markers: _selectedLocation != null
                      ? {
                          Marker(
                            markerId: const MarkerId('selected_location'),
                            position: _selectedLocation!,
                            draggable: true,
                            onDragEnd: (LatLng newPosition) {
                              setState(() => _selectedLocation = newPosition);
                              _getAddressFromLatLng(newPosition);
                            },
                          ),
                        }
                      : {},
                  myLocationEnabled: true,
                  myLocationButtonEnabled: false,
                ),

                // Center marker
                const IgnorePointer(
                  child: Center(
                    child: Icon(
                      Icons.location_pin,
                      color: Colors.red,
                      size: 40,
                    ),
                  ),
                ),

                // Address display
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Localisation sélectionnée:',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 4),
                          _isGettingAddress
                              ? const Row(
                                  children: [
                                    SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                    SizedBox(width: 8),
                                    Text('Recherche de l\'adresse...'),
                                  ],
                                )
                              : Text(
                                  _selectedAddress.isEmpty
                                      ? 'Appuyez sur la carte pour sélectionner'
                                      : _selectedAddress,
                                  style: const TextStyle(fontSize: 12),
                                ),
                          if (_selectedLocation != null) ...[
                            const SizedBox(height: 4),
                            Text(
                              'Lat: ${_selectedLocation!.latitude.toStringAsFixed(6)}, '
                              'Lng: ${_selectedLocation!.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _selectedLocation != null ? _confirmSelection : null,
        child: const Icon(Icons.check),
      ),
    );
  }
}
