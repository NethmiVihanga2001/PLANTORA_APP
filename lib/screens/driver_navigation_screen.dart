import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../theme/app_theme.dart';
import '../widgets/premium_app_bar.dart';
import '../services/socket_service.dart';
import '../services/delivery_service.dart';

class DriverNavigationScreen extends StatefulWidget {
  final String orderId;
  const DriverNavigationScreen({super.key, required this.orderId});

  @override
  State<DriverNavigationScreen> createState() => _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends State<DriverNavigationScreen> {
  final MapController _mapController = MapController();
  
  // Coordinates
  final LatLng _destination = const LatLng(6.9271, 79.8612);
  LatLng _currentLocation = const LatLng(6.8720, 79.8860);
  
  List<LatLng> _roadPoints = [];
  final List<LatLng> _traveledPoints = [];
  Timer? _driveTimer;
  bool _isNavigating = false;
  int _step = 0;

  @override
  void initState() {
    super.initState();
    _traveledPoints.add(_currentLocation);
    SocketService().joinOrderRoom(widget.orderId);
    _fetchRoad();
  }

  Future<void> _fetchRoad() async {
    final points = await DeliveryService.fetchRoadRoute(_currentLocation, _destination);
    if (mounted) {
      setState(() {
        _roadPoints = points;
      });
      if (_roadPoints.isNotEmpty) {
        _mapController.fitCamera(CameraFit.bounds(
          bounds: LatLngBounds.fromPoints([_currentLocation, _destination]),
          padding: const EdgeInsets.all(50),
        ));
      }
    }
  }

  void _startDrive() {
    final route = _roadPoints.isNotEmpty ? _roadPoints : [_currentLocation, _destination];
    setState(() {
      _isNavigating = true;
    });

    _driveTimer = Timer.periodic(const Duration(milliseconds: 700), (timer) {
      if (_step >= route.length - 1) {
        timer.cancel();
        setState(() {
          _isNavigating = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Destination reached!'),
            backgroundColor: Color(0xFF10B981),
          ),
        );
        return;
      }

      _step++;
      setState(() {
        _currentLocation = route[_step];
        _traveledPoints.add(_currentLocation);
      });

      _mapController.move(_currentLocation, 15.5);

      final distanceMeters = const Distance().as(LengthUnit.Meter, _currentLocation, _destination);

      // Emit driver location update to server
      SocketService().updateLocation(
        orderId: widget.orderId,
        lat: _currentLocation.latitude,
        lng: _currentLocation.longitude,
        heading: 0.0,
        stage: 'delivering_to_customer',
        distanceToCustomer: distanceMeters.toDouble(),
      );
    });
  }

  @override
  void dispose() {
    _driveTimer?.cancel();
    SocketService().leaveOrderRoom(widget.orderId);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: PremiumAppBar(
        title: 'Live Road Navigation',
        subtitle: 'Order #${widget.orderId}',
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCameraFit: CameraFit.bounds(
                bounds: LatLngBounds.fromPoints([_currentLocation, _destination]),
                padding: const EdgeInsets.all(50),
              ),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://{s}.google.com/vt/lyrs=m&x={x}&y={y}&z={z}',
                subdomains: const ['mt0', 'mt1', 'mt2', 'mt3'],
                userAgentPackageName: 'com.plantora.app',
              ),
              PolylineLayer(
                polylines: [
                  if (_roadPoints.isNotEmpty)
                    Polyline(
                      points: _roadPoints,
                      strokeWidth: 5.0,
                      color: const Color(0xFF10B981).withValues(alpha: 0.35),
                    ),
                  if (_traveledPoints.length >= 2)
                    Polyline(
                      points: _traveledPoints,
                      strokeWidth: 6.0,
                      color: const Color(0xFF10B981),
                    ),
                ],
              ),
              MarkerLayer(
                markers: [
                  Marker(
                    point: _destination,
                    width: 44,
                    height: 44,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.redAccent,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)],
                      ),
                      child: const Icon(Icons.home_rounded, color: Colors.white, size: 24),
                    ),
                  ),
                  Marker(
                    point: _currentLocation,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF10B981), width: 2.5),
                        boxShadow: const [BoxShadow(color: Colors.black26, blurRadius: 8)],
                      ),
                      child: const Center(child: Text('🛵', style: TextStyle(fontSize: 24))),
                    ),
                  ),
                ],
              ),
            ],
          ),
          
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 450),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: SizedBox(
                    height: 54,
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isNavigating ? Colors.orange : const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      onPressed: _isNavigating ? () {
                        _driveTimer?.cancel();
                        setState(() => _isNavigating = false);
                      } : _startDrive,
                      icon: Icon(_isNavigating ? Icons.pause_rounded : Icons.navigation_rounded),
                      label: Text(
                        _isNavigating ? 'Pause Navigation' : 'Drive Along Road Route',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
