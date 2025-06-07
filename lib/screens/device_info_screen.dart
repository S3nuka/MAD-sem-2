import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/device_provider.dart';

class DeviceInfoScreen extends StatefulWidget {
  const DeviceInfoScreen({super.key});

  @override
  State<DeviceInfoScreen> createState() => _DeviceInfoScreenState();
}

class _DeviceInfoScreenState extends State<DeviceInfoScreen> {
  @override
  void initState() {
    super.initState();
    // Initialize device monitoring when screen is created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<DeviceProvider>(context, listen: false).initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Device Information'),
      ),
      body: Consumer<DeviceProvider>(
        builder: (context, deviceProvider, child) {
          if (deviceProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (deviceProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error loading device information',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    deviceProvider.error!,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          color: Colors.grey,
                        ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSection(
                  context,
                  'Network Status',
                  [
                    _buildInfoRow(
                      'Connection',
                      deviceProvider.connectivityStatusString,
                      Icons.wifi,
                    ),
                    _buildInfoRow(
                      'Status',
                      deviceProvider.isOnline ? 'Online' : 'Offline',
                      Icons.cloud,
                      color: deviceProvider.isOnline ? Colors.green : Colors.red,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Location',
                  [
                    if (deviceProvider.isLocationLoading)
                      const Center(child: CircularProgressIndicator())
                    else if (deviceProvider.locationError != null)
                      _buildInfoRow(
                        'Error',
                        deviceProvider.locationError!,
                        Icons.error_outline,
                        color: Colors.red,
                      )
                    else if (deviceProvider.currentAddress != null)
                      _buildInfoRow(
                        'Current Location',
                        deviceProvider.currentAddress!,
                        Icons.location_on,
                      )
                    else
                      _buildInfoRow(
                        'Location',
                        'Not available',
                        Icons.location_off,
                        color: Colors.grey,
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Battery Information',
                  [
                    _buildInfoRow(
                      'Level',
                      '${deviceProvider.batteryLevel}%',
                      Icons.battery_full,
                    ),
                    _buildInfoRow(
                      'Status',
                      deviceProvider.batteryStatusString,
                      Icons.power,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildSection(
                  context,
                  'Sensors',
                  [
                    _buildInfoRow(
                      'Ambient Light',
                      '${deviceProvider.ambientLight.toStringAsFixed(2)} lux',
                      Icons.lightbulb,
                    ),
                    _buildInfoRow(
                      'Accelerometer',
                      'X: ${deviceProvider.accelerometerEvent.x.toStringAsFixed(2)}\n'
                      'Y: ${deviceProvider.accelerometerEvent.y.toStringAsFixed(2)}\n'
                      'Z: ${deviceProvider.accelerometerEvent.z.toStringAsFixed(2)}',
                      Icons.speed,
                    ),
                    _buildInfoRow(
                      'Gyroscope',
                      'X: ${deviceProvider.gyroscopeEvent.x.toStringAsFixed(2)}\n'
                      'Y: ${deviceProvider.gyroscopeEvent.y.toStringAsFixed(2)}\n'
                      'Z: ${deviceProvider.gyroscopeEvent.z.toStringAsFixed(2)}',
                      Icons.rotate_right,
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () async {
                      await deviceProvider.getCurrentLocation();
                    },
                    icon: const Icon(Icons.refresh),
                    label: const Text('Refresh Location'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: children,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, {Color? color}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 