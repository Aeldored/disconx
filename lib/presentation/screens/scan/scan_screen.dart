import 'package:flutter/material.dart';
import 'dart:async';
import '../../../core/theme/app_colors.dart';
import 'widgets/scan_animation_widget.dart';
import 'widgets/scan_result_item.dart' show ScanResult, ScanStatus, ScanResultItem;

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with SingleTickerProviderStateMixin {
  bool _isScanning = true;
  int _networksFound = 0;
  int _verifiedNetworks = 0;
  double _scanProgress = 0.0;
  final List<ScanResult> _scanResults = [];
  Timer? _scanTimer;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _startScanning();
  }

  @override
  void dispose() {
    _scanTimer?.cancel();
    _progressTimer?.cancel();
    super.dispose();
  }

  void _startScanning() {
    setState(() {
      _isScanning = true;
      _scanProgress = 0.0;
      _scanResults.clear();
      _networksFound = 0;
      _verifiedNetworks = 0;
    });

    // Simulate progress
    _progressTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (_scanProgress < 1.0) {
        setState(() {
          _scanProgress += 0.01;
        });
      } else {
        timer.cancel();
      }
    });

    // Simulate finding networks
    _scanTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_networksFound < 7) {
        _addMockScanResult();
      } else {
        timer.cancel();
        setState(() {
          _isScanning = false;
        });
      }
    });
  }

  void _addMockScanResult() {
    final results = [
      ScanResult(
        networkName: 'CalambaFreeWiFi',
        status: ScanStatus.verified,
        description: 'Verified official access point',
        timeAgo: '${_scanResults.length * 10 + 10}s ago',
      ),
      ScanResult(
        networkName: 'FREE_WiFi_CalambaCity',
        status: ScanStatus.suspicious,
        description: 'Suspicious - potential evil twin',
        timeAgo: '${_scanResults.length * 10 + 35}s ago',
      ),
      ScanResult(
        networkName: 'OPEN_WiFi_CalambaCity',
        status: ScanStatus.suspicious,
        description: 'Suspicious - potential evil twin',
        timeAgo: '${_scanResults.length * 10 + 58}s ago',
      ),
      ScanResult(
        networkName: 'BatangasFreeWiFi',
        status: ScanStatus.verified,
        description: 'Verified DICT access point',
        timeAgo: '${_scanResults.length * 10 + 70}s ago',
      ),
    ];

    if (_scanResults.length < results.length) {
      setState(() {
        _scanResults.add(results[_scanResults.length]);
        _networksFound++;
        if (results[_scanResults.length - 1].status == ScanStatus.verified) {
          _verifiedNetworks++;
        }
      });
    }
  }

  void _stopScanning() {
    _scanTimer?.cancel();
    _progressTimer?.cancel();
    setState(() {
      _isScanning = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 24),
            // Scan animation
            ScanAnimationWidget(isScanning: _isScanning),
            const SizedBox(height: 32),
            
            // Title and description
            Text(
              _isScanning ? 'Scanning for Networks' : 'Scan Complete',
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _isScanning
                  ? 'Detecting nearby Wi-Fi networks and checking them against DICT\'s verified database'
                  : 'Found $_networksFound networks, $_verifiedNetworks verified',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 32),
            
            // Progress section
            Container(
              width: double.infinity,
              constraints: const BoxConstraints(maxWidth: 300),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Networks found: $_networksFound',
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text(
                        'Verified: $_verifiedNetworks',
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: _scanProgress,
                      backgroundColor: AppColors.lightGray,
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
            
            // Recent findings
            if (_scanResults.isNotEmpty) ...[
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Recent Findings',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                    color: Colors.grey[800],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ...(_scanResults.map((result) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: ScanResultItem(result: result),
              ))),
            ],
            
            const SizedBox(height: 24),
            
            // Action button
            ElevatedButton.icon(
              onPressed: _isScanning ? _stopScanning : _startScanning,
              icon: Icon(_isScanning ? Icons.stop_circle : Icons.play_circle),
              label: Text(_isScanning ? 'Stop Scanning' : 'Start Scanning'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                minimumSize: const Size(200, 48),
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}