
import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
// import 'package:geolocator/geolocator.dart';

import 'package:location/location.dart' as loc;
import 'package:geocoding/geocoding.dart';

import 'package:field_visit_app/AppDrawer/app_drawer.dart';

class ProfilePage extends StatefulWidget {
  final String empName;

  const ProfilePage({
    super.key,
    required this.empName,
  });

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  static const Color _blue = Color(0xFF0755D9);
  static const Color _deepBlue = Color(0xFF0739A8);
  static const Color _cyan = Color(0xFF43C8F5);
  static const Color _background = Color(0xFFF1F7FF);
  static const Color _ink = Color(0xFF163B80);
  static const Color _muted = Color(0xFF8195B8);
  static const Color _green = Color(0xFF16A879);
  static const Color _orange = Color(0xFFFFA34D);

  // Replace with the actual Punch In/Out API endpoint.
  static const String _punchApiUrl = 'https://salasarcrm.aonesalasar.com/api/mobile/set-user-attend';

  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  bool _isPunchInLoading = false;
  bool _isPunchOutLoading = false;
  bool _hasPunchedIn = false;

  String? _punchInTime;
  String? _punchOutTime;

  String _locationAddress = 'Location not verified';
  double? _latitude;
  double? _longitude;

  // These remain empty until the attendance-summary
  // API is integrated.
  int? _presentCount;
  int? _absentCount;

  @override
  void initState() {
    super.initState();

    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        if (mounted) {
          setState(() {
            _now = DateTime.now();
          });
        }
      },
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    super.dispose();
  }

  String get _formattedTime {
    final hour = _now.hour % 12 == 0 ? 12 : _now.hour % 12;
    final minute = _now.minute.toString().padLeft(2, '0');
    final second = _now.second.toString().padLeft(2, '0');
    final period = _now.hour >= 12 ? 'PM' : 'AM';

    return '$hour:$minute:$second $period';
  }

  String get _formattedDate {
    const weekdays = [
      'Monday', 'Tuesday', 'Wednesday',
      'Thursday', 'Friday', 'Saturday', 'Sunday'
    ];

    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December'
    ];

    return '${weekdays[_now.weekday - 1]}, '
        '${_now.day} ${months[_now.month - 1]} ${_now.year}';
  }

  String get _greeting {
    if (_now.hour < 12) return 'Good morning';
    if (_now.hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ==========================================
  // GET LIVE GPS LOCATION
  // ==========================================



  Future<loc.LocationData> _getDevicePosition() async {
    final loc.Location location = loc.Location();

    bool serviceEnabled = await location.serviceEnabled();

    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();

      if (!serviceEnabled) {
        throw Exception('Please enable GPS location.');
      }
    }

    loc.PermissionStatus permission =
    await location.hasPermission();

    if (permission == loc.PermissionStatus.denied) {
      permission = await location.requestPermission();
    }

    if (permission != loc.PermissionStatus.granted) {
      throw Exception('Location permission is required.');
    }

    await location.changeSettings(
      accuracy: loc.LocationAccuracy.high,
    );

    final loc.LocationData position =
    await location.getLocation().timeout(
      const Duration(seconds: 25),
    );

    if (position.latitude == null ||
        position.longitude == null) {
      throw Exception('Unable to fetch GPS coordinates.');
    }

    return position;
  }



  // ==========================================
  // GET ADDRESS FROM GPS
  // ==========================================

  Future<String> _getAddress(
      double latitude,
      double longitude,
      ) async {
    final placemarks = await placemarkFromCoordinates(
      latitude,
      longitude,
    );

    if (placemarks.isEmpty) {
      throw Exception('Unable to fetch location address.');
    }

    final place = placemarks.first;

    final parts = [
      place.street,
      place.subLocality,
      place.locality,
      place.administrativeArea,
    ];

    final address = parts
        .whereType<String>()
        .where((s) => s.trim().isNotEmpty)
        .toSet()
        .join(', ');

    if (address.isEmpty) {
      throw Exception('Location address unavailable.');
    }

    return address;
  }

  // ==========================================
  // PUNCH IN / PUNCH OUT API
  // ==========================================

  Future<void> _onPunchPressed({
    required bool isPunchIn,
  }) async {
    if (_isPunchInLoading || _isPunchOutLoading) return;

    setState(() {
      if (isPunchIn) {
        _isPunchInLoading = true;
      } else {
        _isPunchOutLoading = true;
      }
    });

    try {
      // STEP 1: Validate API URL
      if (_punchApiUrl.trim().isEmpty ||
          _punchApiUrl == 'YOUR_PUNCH_API_URL') {
        throw Exception('Please configure Punch API URL.');
      }

      // STEP 2: Read saved login details
      final SharedPreferences prefs =
      await SharedPreferences.getInstance();
      debugPrint('========== SAVED KEYS ==========');
      debugPrint('Keys: ${prefs.getKeys().toList()}');
      debugPrint('Login status: ${prefs.getBool('isLoggedIn')}');
      debugPrint('================================');
      String readSavedValue(List<String> keys) {
        for (final key in keys) {
          final dynamic value = prefs.get(key);

          if (value != null &&
              value.toString().trim().isNotEmpty) {
            return value.toString().trim();
          }
        }
        return '';
      }

      final String username = readSavedValue([
        'username',
        'user_name',
        'Username',
      ]);

      final String password = readSavedValue([
        'password',
        'Password',
      ]);

      final String empId = readSavedValue([
        'emp_id',
      ]);

      // Debug safely without printing passwords
      debugPrint('========== PUNCH DETAILS ==========');
      debugPrint('Punch Type: ${isPunchIn ? 'logged in' : 'logged out'}');
      debugPrint('Username available: ${username.isNotEmpty}');
      debugPrint('Password available: ${password.isNotEmpty}');
      debugPrint('Employee ID available: ${empId.isNotEmpty}');
      debugPrint('===================================');

      // STEP 3: Validate credentials
      if (username.isEmpty) {
        throw Exception(
          'Username missing from saved login details.',
        );
      }

      if (password.isEmpty) {
        throw Exception(
          'Password missing from saved login details.',
        );
      }

      if (empId.isEmpty) {
        throw Exception(
          'Employee ID missing from saved login details.',
        );
      }

      // STEP 4: Get current GPS location
      final loc.LocationData position =
      await _getDevicePosition();

      final double? latitude = position.latitude;
      final double? longitude = position.longitude;

      if (latitude == null || longitude == null) {
        throw Exception('Unable to fetch current GPS location.');
      }

      // STEP 5: Convert GPS coordinates to address
      final String address = await _getAddress(
        latitude,
        longitude,
      );

      if (!mounted) return;

      setState(() {
        _latitude = latitude;
        _longitude = longitude;
        _locationAddress = address;
      });

      // STEP 6: Set correct Punch Type
      final String punchType =
      isPunchIn ? 'logged in' : 'logged out';

      // STEP 7: Prepare API request body
      final Map<String, String> requestBody = {
        'Username': username,
        'Password': password,
        'person_id': empId,
        'punch_type': punchType,
        'location[lat]': latitude.toString(),
        'location[long]': longitude.toString(),
        'address': address,
      };

      debugPrint('Sending Punch Request: $punchType');

      // STEP 8: Call Punch In / Punch Out API
      final http.Response response = await http.post(
        Uri.parse(_punchApiUrl),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: requestBody,
      ).timeout(
        const Duration(seconds: 30),
      );

      debugPrint('Punch API Status: ${response.statusCode}');

      // STEP 9: Check HTTP response
      if (response.statusCode < 200 ||
          response.statusCode >= 300) {
        throw Exception(
          'Attendance API error: ${response.statusCode}',
        );
      }

      // STEP 10: Decode API response
      final dynamic result = jsonDecode(response.body);

      if (result is! Map) {
        throw Exception('Invalid attendance API response.');
      }

      final String status =
          result['status']?.toString().toLowerCase() ?? '';

      final dynamic success = result['success'];

      final String message =
      (result['message'] ?? result['msg'] ?? '').toString();

      final String normalizedMessage = message.toLowerCase();

      // STEP 11: Check API success/failure
      if (status == 'error' ||
          status == 'failed' ||
          status == 'failure' ||
          success == false ||
          success == 0 ||
          success == '0' ||
          normalizedMessage.contains('failed') ||
          normalizedMessage.contains('error')) {
        throw Exception(
          message.isNotEmpty
              ? message
              : 'Attendance was not recorded.',
        );
      }

      if (!mounted) return;

      // STEP 12: Update UI after successful API response
      final String currentTime =
      TimeOfDay.now().format(context);

      setState(() {
        if (isPunchIn) {
          _punchInTime = currentTime;
          _hasPunchedIn = true;
        } else {
          _punchOutTime = currentTime;
          _hasPunchedIn = false;
        }
      });

      // STEP 13: Show success message
      _showMessage(
        message.isNotEmpty
            ? message
            : isPunchIn
            ? 'Punch In recorded successfully'
            : 'Punch Out recorded successfully',
        success: true,
      );
    } on TimeoutException {
      if (!mounted) return;

      _showMessage(
        'Request timed out. Please check your attendance status before retrying.',
        success: false,
      );
    } catch (e) {
      if (!mounted) return;

      debugPrint('Punch error: ${e.runtimeType}');

      _showMessage(
        e.toString().replaceFirst('Exception: ', ''),
        success: false,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isPunchInLoading = false;
          _isPunchOutLoading = false;
        });
      }
    }
  }

  void _showMessage(
      String message, {
        required bool success,
      }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor:
          success ? _green : Colors.redAccent,
          content: Text(message),
        ),
      );
  }

  // ==========================================
  // LOGOUT
  // ==========================================

  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();

    for (final key in [
      'username',
      'password',
      'person_id',
      'isLoggedIn',
      'empName',
      'emp_id',
      'emp_name',
      'user_name',
      'email_office',
      'designation',
      'designation_id',
      'new_dep_id',
      'user_type',
      'is_external',
    ]) {
      await prefs.remove(key);
    }

    if (!mounted) return;

    Navigator.pushNamedAndRemoveUntil(
      context,
      '/login',
          (route) => false,
    );
  }

  // ==========================================
  // MAIN SCREEN
  // ==========================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      drawer: AppDrawer(
        selectedPage: CrmPage.profile,
        onProfileTap: () {},
        onEmployeeTrackerTap: () {
          Navigator.pushNamed(
            context,
            '/employee-tracker',
          );
        },
        onLogoutTap: _logout,
      ),
      body: Stack(
        children: [
          const Positioned(
            top: -95,
            right: -75,
            child: _GlowOrb(
              size: 250,
              color: Color(0x5543C8F5),
            ),
          ),
          const Positioned(
            top: 330,
            left: -115,
            child: _GlowOrb(
              size: 240,
              color: Color(0x220755D9),
            ),
          ),
          SafeArea(
            child: RefreshIndicator(
              color: _blue,
              onRefresh: () async {
                if (mounted) {
                  setState(() => _now = DateTime.now());
                }
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20, 14, 20, 28,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        _buildTopBar(),
                        const SizedBox(height: 24),
                        _buildWelcome(),
                        const SizedBox(height: 20),
                        _buildClockCard(),
                        const SizedBox(height: 16),
                        _buildPunchCard(),
                        const SizedBox(height: 16),
                        _buildAttendanceSummary(),
                        const SizedBox(height: 16),
                        _buildLocationCard(),
                        const SizedBox(height: 22),
                        const Center(
                          child: Text(
                            'CRM WORKSPACE  •  FIELD ATTENDANCE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // HEADER
  // ==========================================

  Widget _buildTopBar() {
    return Row(
      children: [
        Builder(
          builder: (drawerContext) => IconButton(
            tooltip: 'Open menu',
            onPressed: () =>
                Scaffold.of(drawerContext).openDrawer(),
            icon: const Icon(
              Icons.menu_rounded,
              color: _blue,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 4),
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_deepBlue, _blue, _cyan],
            ),
            borderRadius: BorderRadius.circular(15),
          ),
          child: const Icon(
            Icons.auto_awesome_rounded,
            color: Colors.white,
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CRM',
                style: TextStyle(
                  color: _ink,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
              Text(
                'FIELD OPERATIONS',
                style: TextStyle(
                  color: _muted,
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ==========================================
  // WELCOME
  // ==========================================

  Widget _buildWelcome() {
    final name = widget.empName.trim().isEmpty
        ? 'Employee'
        : widget.empName.trim();

    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _greeting,
                style: const TextStyle(
                  color: _blue,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 27,
                  fontWeight: FontWeight.w900,
                  letterSpacing: -0.7,
                ),
              ),
              const SizedBox(height: 7),
              const Text(
                'Make today count.',
                style: TextStyle(
                  color: _muted,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
        Container(
          width: 62,
          height: 62,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [_cyan, _blue],
            ),
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
          ),
          child: Center(
            child: Text(
              name.isNotEmpty
                  ? name[0].toUpperCase()
                  : 'E',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // LIVE CLOCK CARD
  // ==========================================

  Widget _buildClockCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            _deepBlue,
            Color(0xFF126BE8),
            _cyan,
          ],
        ),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: _blue.withOpacity(0.24),
            blurRadius: 25,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_rounded,
                color: Colors.white70,
                size: 17,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _formattedDate,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '● LIVE',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            _formattedTime,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 37,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ==========================================
  // ATTENDANCE CARD
  // ==========================================

  Widget _buildPunchCard() {
    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F0FF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  color: _blue,
                  size: 26,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Attendance',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _hasPunchedIn
                      ? const Color(0xFFE0F9EB)
                      : const Color(0xFFFFF3DE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  _hasPunchedIn
                      ? 'PUNCHED IN'
                      : _punchOutTime != null
                      ? 'PUNCHED OUT'
                      : 'NOT STARTED',
                  style: TextStyle(
                    color: _hasPunchedIn
                        ? _green
                        : const Color(0xFF9B6500),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _timeDetail(
                  icon: Icons.login_rounded,
                  label: 'PUNCH IN',
                  value: _punchInTime ?? '--:--',
                ),
              ),
              Container(
                width: 1,
                height: 42,
                color: const Color(0xFFE5EEFA),
              ),
              Expanded(
                child: _timeDetail(
                  icon: Icons.logout_rounded,
                  label: 'PUNCH OUT',
                  value: _punchOutTime ?? '--:--',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _attendanceButton(
                  label: 'PUNCH IN',
                  icon: Icons.login_rounded,
                  isLoading: _isPunchInLoading,
                  isPunchIn: true,
                  colors: const [
                    _cyan,
                    Color(0xFF2388FF),
                    _blue,
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _attendanceButton(
                  label: 'PUNCH OUT',
                  icon: Icons.logout_rounded,
                  isLoading: _isPunchOutLoading,
                  isPunchIn: false,
                  colors: const [
                    Color(0xFFFFB36B),
                    Color(0xFFFF8A50),
                    Color(0xFFE85D4A),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'GPS location is captured during attendance.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _muted,
                fontSize: 10,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _attendanceButton({
    required String label,
    required IconData icon,
    required bool isLoading,
    required bool isPunchIn,
    required List<Color> colors,
  }) {
    final isAnyLoading =
        _isPunchInLoading || _isPunchOutLoading;

    return SizedBox(
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: colors.last.withOpacity(0.22),
              blurRadius: 15,
              offset: const Offset(0, 7),
            ),
          ],
        ),
        child: ElevatedButton(
          onPressed: isAnyLoading
              ? null
              : () => _onPunchPressed(
            isPunchIn: isPunchIn,
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: isLoading
              ? const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          )
              : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 21),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _timeDetail({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Row(
        children: [
          Icon(icon, color: _blue, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // ATTENDANCE OVERVIEW
  // ==========================================

  Widget _buildAttendanceSummary() {
    final hasData =
        _presentCount != null && _absentCount != null;

    final present = _presentCount ?? 0;
    final absent = _absentCount ?? 0;
    final total = present + absent;

    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Expanded(
                child: Text(
                  'Attendance overview',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                Icons.donut_large_rounded,
                color: _blue,
                size: 25,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              SizedBox(
                width: 124,
                height: 124,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CustomPaint(
                      size: const Size(124, 124),
                      painter: _AttendanceDonutPainter(
                        present: present.toDouble(),
                        absent: absent.toDouble(),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          hasData ? '$total' : '--',
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Text(
                          'RECORDS',
                          style: TextStyle(
                            color: _muted,
                            fontSize: 8,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  children: [
                    _legendRow(
                      color: _green,
                      label: 'Present',
                      count: hasData
                          ? '$present'
                          : '--',
                    ),
                    const SizedBox(height: 15),
                    _legendRow(
                      color: _orange,
                      label: 'Absent',
                      count: hasData
                          ? '$absent'
                          : '--',
                    ),
                    const SizedBox(height: 13),
                    Text(
                      hasData
                          ? 'Attendance summary'
                          : 'Connect attendance summary API '
                          'to display real counts.',
                      style: const TextStyle(
                        color: _muted,
                        fontSize: 10,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendRow({
    required Color color,
    required String label,
    required String count,
  }) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: _muted,
              fontSize: 12,
            ),
          ),
        ),
        Text(
          count,
          style: const TextStyle(
            color: _ink,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }

  // ==========================================
  // LOCATION CARD
  // ==========================================

  Widget _buildLocationCard() {
    final verified =
        _latitude != null && _longitude != null;

    return _GlassCard(
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              color: const Color(0xFFE4F0FF),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.my_location_rounded,
              color: _blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Location verification',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _locationAddress,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 9,
              vertical: 7,
            ),
            decoration: BoxDecoration(
              color: verified
                  ? const Color(0xFFE0F9EB)
                  : const Color(0xFFFFF3DE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              verified ? 'VERIFIED' : 'PENDING',
              style: TextStyle(
                color: verified
                    ? _green
                    : const Color(0xFF9B6500),
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ==========================================
// GLASS CARD
// ==========================================

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: Colors.white,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3976C8)
                .withOpacity(0.07),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ==========================================
// BACKGROUND GLOW
// ==========================================

class _GlowOrb extends StatelessWidget {
  final double size;
  final Color color;

  const _GlowOrb({
    required this.size,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: color,
          boxShadow: [
            BoxShadow(
              color: color,
              blurRadius: 70,
              spreadRadius: 18,
            ),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// ATTENDANCE DONUT PAINTER
// ==========================================

class _AttendanceDonutPainter extends CustomPainter {
  final double present;
  final double absent;

  const _AttendanceDonutPainter({
    required this.present,
    required this.absent,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const strokeWidth = 13.0;

    final rect = Offset.zero & size;
    final chartRect = rect.deflate(strokeWidth / 2);

    final backgroundPaint = Paint()
      ..color = const Color(0xFFE8EFF9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      chartRect,
      0,
      math.pi * 2,
      false,
      backgroundPaint,
    );

    final total = present + absent;
    if (total <= 0) return;

    final presentPaint = Paint()
      ..color = const Color(0xFF16A879)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final absentPaint = Paint()
      ..color = const Color(0xFFFFA34D)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    const startAngle = -math.pi / 2;

    final presentSweep =
        (present / total) * math.pi * 2;

    final gap = total > 1 ? 0.055 : 0.0;

    if (present > 0) {
      canvas.drawArc(
        chartRect,
        startAngle,
        math.max(0, presentSweep - gap),
        false,
        presentPaint,
      );
    }

    if (absent > 0) {
      canvas.drawArc(
        chartRect,
        startAngle + presentSweep + gap,
        math.max(
          0,
          (absent / total) * math.pi * 2 - gap,
        ),
        false,
        absentPaint,
      );
    }
  }

  @override
  bool shouldRepaint(
      covariant _AttendanceDonutPainter oldDelegate,
      ) {
    return oldDelegate.present != present ||
        oldDelegate.absent != absent;
  }
}
