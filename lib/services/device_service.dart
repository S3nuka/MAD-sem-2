import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:light/light.dart';
import 'package:sensors_plus/sensors_plus.dart';

class DeviceService {
  final Battery _battery = Battery();
  final Light _light = Light();
  StreamSubscription<Position>? _positionStream;
  StreamSubscription<ConnectivityResult>? _connectivityStream;
  StreamSubscription<int>? _lightStream;
  StreamSubscription<AccelerometerEvent>? _accelerometerStream;
  StreamSubscription<GyroscopeEvent>? _gyroscopeStream;

  // Battery status
  Future<int> getBatteryLevel() async {
    return await _battery.batteryLevel;
  }

  Stream<BatteryState> get batteryState => _battery.onBatteryStateChanged;

  // Location
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw Exception('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw Exception('Location permissions are permanently denied');
    }

    return await Geolocator.getCurrentPosition();
  }

  Stream<Position> getLocationStream() {
    return Geolocator.getPositionStream();
  }

  // Network connectivity
  Future<ConnectivityResult> getConnectivityStatus() async {
    return await Connectivity().checkConnectivity();
  }

  Stream<ConnectivityResult> getConnectivityStream() {
    return Connectivity().onConnectivityChanged;
  }

  // Ambient light
  Future<void> startLightSensor(Function(double) onLightChanged) async {
    try {
      _lightStream = _light.lightSensorStream.listen((int light) {
        onLightChanged(light.toDouble());
      });
    } catch (e) {
      debugPrint('Error starting light sensor: $e');
    }
  }

  // Accelerometer
  void startAccelerometer(Function(AccelerometerEvent) onAccelerometerChanged) {
    _accelerometerStream = SensorsPlatform.instance.accelerometerEventStream().listen((AccelerometerEvent event) {
      onAccelerometerChanged(event);
    });
  }

  // Gyroscope
  void startGyroscope(Function(GyroscopeEvent) onGyroscopeChanged) {
    _gyroscopeStream = SensorsPlatform.instance.gyroscopeEventStream().listen((GyroscopeEvent event) {
      onGyroscopeChanged(event);
    });
  }

  // Cleanup
  void dispose() {
    _positionStream?.cancel();
    _connectivityStream?.cancel();
    _lightStream?.cancel();
    _accelerometerStream?.cancel();
    _gyroscopeStream?.cancel();
  }
} 