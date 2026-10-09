import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import '../theme/app_theme.dart';
import '../config/app_config.dart';
import '../widgets/premium_app_bar.dart';
import '../widgets/responsive_layout.dart';

class DriverNavigationScreen extends StatefulWidget {
  final String orderId;
  const DriverNavigationScreen({super.key, required this.orderId});

  @override
  State<DriverNavigationScreen> createState() => _DriverNavigationScreenState();
}

class _DriverNavigationScreenState extends State<DriverNavigationScreen> {
  late IO.Socket _socket;
  final MapController _mapController = MapController();
  
  // Coordinates
  final LatLng _destination = const LatLng(6.9271, 79.8612);
  LatLng _currentLocation = const LatLng(6.8649, 79.8997);
  
  Timer? _simulationTimer;
  bool _isNavigating = false;

  @override
  void initState() {
    super.initState();
    _initSocket();
  }

  void _initSocket() {
    _socket = IO.io(AppConfig.baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
    });
    
    _socket.connect();
    
    _socket.onConnect((_) {
      print('Navigation Socket connected');
      _socket.emit('join_order', widget.orderId);
    });

    _socket.onConnectError((err) => print('Navigation Socket connect error: $err'));
    _socket.onError((err) => print('Navigation Socket error: $err'));
  }

  void _startSimulation() {
    setState(() {
      _isNavigating = true;
    });

    // Simulate driver moving towards destination over ~10 steps
    int step = 0;
    const totalSteps = 20;
    
    final latStep = (_destination.latitude - _currentLocation.latitude) / totalSteps;
    final lngStep = (_destination.longitude - _currentLocation.longitude) / totalSteps;

    _simulationTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (step >= totalSteps) {
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

      step++;
      setState(() {
        _currentLocation = LatLng(
          _currentLocation.latitude + latStep,
          _currentLocation.longitude + lngStep,
        );
      });

      _mapController.move(_currentLocation, 15.0);

      // Emit driver location update to server
      _socket.emit('driver_location_update', {
        'orderId': widget.orderId,
        'lat': _currentLocation.latitude,
        'lng': _currentLocation.longitude,
      });
    });
  }

  @override
  void dispose() {
    _simulationTimer?.cancel();
    _socket.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.scaffoldBg,
      appBar: PremiumAppBar(
        title: 'Live Navigation',
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
              MarkerLayer(
                markers: [
                  Marker(
                    point: _destination,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.home, color: Color(0xFF10B981), size: 40),
                  ),
                  Marker(
                    point: _currentLocation,
                    width: 50,
                    height: 50,
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 8)],
                      ),
                      child: const Center(child: Text('🚲', style: TextStyle(fontSize: 24))),
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
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isNavigating ? Colors.red : const Color(0xFF10B981),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 4,
                      ),
                      onPressed: _isNavigating ? null : _startSimulation,
                      child: Text(
                        _isNavigating ? 'Navigating...' : 'Start Driving Simulation',
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
