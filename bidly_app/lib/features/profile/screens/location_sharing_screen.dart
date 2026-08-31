import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_theme.dart';

class LocationSharingScreen extends StatefulWidget {
  const LocationSharingScreen({super.key});

  @override
  State<LocationSharingScreen> createState() => _LocationSharingScreenState();
}

class _LocationSharingScreenState extends State<LocationSharingScreen> {
  bool _shareWithBuyers = true;
  bool _showCityInProfile = true;
  bool _preciseLocation = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20, color: AppTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Location Sharing',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppTheme.textPrimary,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppTheme.border.withValues(alpha: 0.7),
            height: 1,
          ),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          children: [
            // Current Location Box
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFE8F6F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFB8E0DC)),
              ),
              child: Row(
                children: const [
                  Icon(Icons.location_on_outlined, color: Color(0xFF004E54), size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Current location: Chennai, Tamil Nadu, India',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF004E54),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            const Text(
              'LOCATION SETTINGS',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppTheme.textSecondary,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.border),
              ),
              child: Column(
                children: [
                  _buildSwitchRow(
                    'Share location with buyers',
                    _shareWithBuyers ? 'ON' : 'OFF',
                    _shareWithBuyers,
                    (v) => setState(() => _shareWithBuyers = v),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildSwitchRow(
                    'Show city in profile',
                    _showCityInProfile ? 'ON' : 'OFF',
                    _showCityInProfile,
                    (v) => setState(() => _showCityInProfile = v),
                  ),
                  const Divider(height: 1, indent: 16, endIndent: 16),
                  _buildSwitchRow(
                    'Precise location for radius listings',
                    _preciseLocation ? 'ON' : 'OFF',
                    _preciseLocation,
                    (v) => setState(() => _preciseLocation = v),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchRow(String title, String status, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
                Text(
                  status,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
                    color: value ? const Color(0xFF004E54) : AppTheme.textHint,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: const Color(0xFF004E54),
          ),
        ],
      ),
    );
  }
}
