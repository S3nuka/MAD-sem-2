import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../services/device_service.dart';

class DeviceProvider extends ChangeNotifier {
  final DeviceService _deviceService = DeviceService();
  
  // Device state
  int _batteryLevel = 0;
  BatteryState _batteryState = BatteryState.unknown;
  ConnectivityResult _connectivityStatus = ConnectivityResult.none;
  double _ambientLight = 0;
  AccelerometerEvent _accelerometerEvent = AccelerometerEvent(0, 0, 0);
  GyroscopeEvent _gyroscopeEvent = GyroscopeEvent(0, 0, 0);
  bool _isLoading = false;
  String? _error;
  
  // Location state
  Position? _currentPosition;
  String? _currentAddress;
  bool _isLocationLoading = false;
  String? _locationError;

  // Getters
  int get batteryLevel => _batteryLevel;
  BatteryState get batteryState => _batteryState;
  ConnectivityResult get connectivityStatus => _connectivityStatus;
  double get ambientLight => _ambientLight;
  AccelerometerEvent get accelerometerEvent => _accelerometerEvent;
  GyroscopeEvent get gyroscopeEvent => _gyroscopeEvent;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Position? get currentPosition => _currentPosition;
  String? get currentAddress => _currentAddress;
  bool get isLocationLoading => _isLocationLoading;
  String? get locationError => _locationError;

  // Initialize device monitoring
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // Get initial battery level
      _batteryLevel = await _deviceService.getBatteryLevel();
      
      // Monitor battery state
      _deviceService.batteryState.listen((state) {
        _batteryState = state;
        notifyListeners();
      });

      // Monitor connectivity
      _deviceService.getConnectivityStream().listen((status) {
        _connectivityStatus = status;
        notifyListeners();
      });

      // Monitor ambient light
      await _deviceService.startLightSensor((light) {
        _ambientLight = light;
        notifyListeners();
      });

      // Monitor accelerometer
      _deviceService.startAccelerometer((event) {
        _accelerometerEvent = event;
        notifyListeners();
      });

      // Monitor gyroscope
      _deviceService.startGyroscope((event) {
        _gyroscopeEvent = event;
        notifyListeners();
      });

      // Get initial connectivity status
      _connectivityStatus = await _deviceService.getConnectivityStatus();
      // (Location will be fetched after login, not here)
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get current location and address
  Future<void> getCurrentLocation() async {
    _isLocationLoading = true;
    _locationError = null;
    notifyListeners();

    try {
      // Get current position
      _currentPosition = await _deviceService.getCurrentLocation();
      
      // Convert position to address
      if (_currentPosition != null) {
        if (kIsWeb) {
          // On web, just show coordinates as address
          _currentAddress = 'Lat: ${_currentPosition!.latitude.toStringAsFixed(5)}, Lng: ${_currentPosition!.longitude.toStringAsFixed(5)}';
        } else {
          try {
            List<Placemark> placemarks = await placemarkFromCoordinates(
              _currentPosition!.latitude,
              _currentPosition!.longitude,
            );

            if (placemarks.isNotEmpty) {
              Placemark place = placemarks[0];
              final addressParts = <String>[];
              if (place.street != null && place.street!.trim().isNotEmpty) addressParts.add(place.street!);
              if (place.subLocality != null && place.subLocality!.trim().isNotEmpty) addressParts.add(place.subLocality!);
              if (place.locality != null && place.locality!.trim().isNotEmpty) addressParts.add(place.locality!);
              if (place.administrativeArea != null && place.administrativeArea!.trim().isNotEmpty) addressParts.add(place.administrativeArea!);
              if (place.country != null && place.country!.trim().isNotEmpty) addressParts.add(place.country!);
              _currentAddress = addressParts.isNotEmpty
                  ? addressParts.join(', ')
                  : 'Address not available';
            } else {
              _currentAddress = 'Address not available';
            }
          } catch (e) {
            _locationError = 'Could not get address: ${e.toString()}';
          }
        }
      }
    } catch (e) {
      _locationError = e.toString();
    } finally {
      _isLocationLoading = false;
      notifyListeners();
    }
  }

  // Check if device is online
  bool get isOnline => _connectivityStatus != ConnectivityResult.none;

  // Get connectivity status as string
  String get connectivityStatusString {
    switch (_connectivityStatus) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.none:
        return 'Offline';
      default:
        return 'Unknown';
    }
  }

  // Get battery status as string
  String get batteryStatusString {
    switch (_batteryState) {
      case BatteryState.charging:
        return 'Charging';
      case BatteryState.discharging:
        return 'Discharging';
      case BatteryState.full:
        return 'Full';
      default:
        return 'Unknown';
    }
  }

  @override
  void dispose() {
    _deviceService.dispose();
    super.dispose();
  }
} 