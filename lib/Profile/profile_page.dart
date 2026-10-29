
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:field_visit_app/AppDrawer/app_drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/crm_app_bar.dart';

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

  Timer? _clockTimer;
  DateTime _now = DateTime.now();

  // Employee name loaded from SharedPreferences.
  String _loggedInEmpName = '';

  bool _isPunchInLoading = false;
  bool _isPunchOutLoading = false;

  // Connect these to the attendance-summary API.
  int? _presentCount;
  int? _absentCount;

  @override
  void initState() {
    super.initState();

    _loadLoggedInEmployee();

    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        if (mounted) {
          setState(() => _now = DateTime.now());
        }
      },
    );
  }

  Future<void> _loadLoggedInEmployee() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedName = prefs.getString('emp_name');

      if (!mounted) return;

      setState(() {
        _loggedInEmpName =
        savedName != null && savedName.trim().isNotEmpty
            ? savedName.trim()
            : widget.empName.trim();
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _loggedInEmpName = widget.empName.trim();
      });
    }
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
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];

    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${weekdays[_now.weekday - 1]}, '
        '${_now.day} ${months[_now.month - 1]} ${_now.year}';
  }

  String get _greeting {
    if (_now.hour < 12) return 'Good morning';
    if (_now.hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

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

    // Replace this delay with the actual attendance API request.
    await Future<void>.delayed(
      const Duration(milliseconds: 350),
    );

    if (!mounted) return;

    setState(() {
      _isPunchInLoading = false;
      _isPunchOutLoading = false;
    });

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(
            '${isPunchIn ? 'Punch In' : 'Punch Out'} service '
                'is not connected yet. No punch was recorded.',
          ),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _background,
      drawer: AppDrawer(
        selectedPage: CrmPage.profile,
        onProfileTap: () {
          // Already on the Profile page.
        },
        onEmployeeTrackerTap: () {
          Navigator.pushNamed(context, '/employee-tracker');
        },
        onLogoutTap: () {},
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
                await Future<void>.delayed(
                  const Duration(milliseconds: 250),
                );

                if (mounted) {
                  setState(() => _now = DateTime.now());
                }
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                slivers: [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(
                      20,
                      14,
                      20,
                      28,
                    ),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        const CrmAppBar(),
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
                        Center(
                          child: Text(
                            'CRM WORKSPACE  •  FIELD ATTENDANCE',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: _muted.withOpacity(0.85),
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

  Widget _buildWelcome() {
    final name = _loggedInEmpName.trim().isNotEmpty
        ? _loggedInEmpName.trim()
        : (widget.empName.trim().isNotEmpty
        ? widget.empName.trim()
        : 'Employee');

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
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
                  height: 1.12,
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
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: _blue.withOpacity(0.22),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: Colors.white,
              width: 3,
            ),
          ),
          child: Center(
            child: Text(
              name[0].toUpperCase(),
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -35,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 24,
            bottom: -54,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withOpacity(0.12),
                  width: 18,
                ),
              ),
            ),
          ),
          Column(
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
                      border: Border.all(
                        color: Colors.white24,
                      ),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.circle,
                          color: Color(0xFF9BFFD6),
                          size: 7,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'LIVE',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                      ],
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
                  height: 1.05,
                  fontFeatures: [
                    FontFeature.tabularFigures(),
                  ],
                ),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ],
      ),
    );
  }

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 3),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF3DE),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'NOT STARTED',
                  style: TextStyle(
                    color: Color(0xFF9B6500),
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
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
                  value: '--:--',
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
                  value: '--:--',
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
          const SizedBox(height: 11),
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: _muted,
                size: 14,
              ),
              SizedBox(width: 6),
              Flexible(
                child: Text(
                  'Attendance is not recorded until the API is connected.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
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
    final isAnyRequestLoading =
        _isPunchInLoading || _isPunchOutLoading;

    return SizedBox(
      height: 58,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: colors,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
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
          onPressed: isAnyRequestLoading
              ? null
              : () => _onPunchPressed(isPunchIn: isPunchIn),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: isLoading
                ? const SizedBox(
              key: ValueKey('loading'),
              width: 22,
              height: 22,
              child: CircularProgressIndicator(
                strokeWidth: 2.5,
                color: Colors.white,
              ),
            )
                : Row(
              key: ValueKey(label),
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
                      letterSpacing: 0.6,
                    ),
                  ),
                ),
              ],
            ),
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
                    letterSpacing: 0.6,
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

  Widget _buildAttendanceSummary() {
    final hasData =
        _presentCount != null && _absentCount != null;

    final total = hasData
        ? _presentCount! + _absentCount!
        : 0;

    return _GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance overview',
                      style: TextStyle(
                        color: _ink,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 4),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFE4F0FF),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: const Icon(
                  Icons.donut_large_rounded,
                  color: _blue,
                  size: 21,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
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
                        present: hasData
                            ? _presentCount!.toDouble()
                            : 0,
                        absent: hasData
                            ? _absentCount!.toDouble()
                            : 0,
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
                            letterSpacing: 1,
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
                      count: hasData ? '$_presentCount' : '--',
                    ),
                    const SizedBox(height: 15),
                    _legendRow(
                      color: _orange,
                      label: 'Absent',
                      count: hasData ? '$_absentCount' : '--',
                    ),
                    const SizedBox(height: 13),
                    Text(
                      hasData
                          ? 'Attendance summary from connected data.'
                          : 'Connect the attendance summary API to display real counts.',
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
              fontWeight: FontWeight.w600,
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

  Widget _buildLocationCard() {
    return _GlassCard(
      padding: const EdgeInsets.all(17),
      child: Row(
        children: [
          Container(
            width: 45,
            height: 45,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  Color(0xFFE1F7FF),
                  Color(0xFFE4F0FF),
                ],
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.my_location_rounded,
              color: _blue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Location verification',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'GPS permission and site validation',
                  style: TextStyle(
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
              color: const Color(0xFFFFF3DE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'PENDING',
              style: TextStyle(
                color: Color(0xFF9B6500),
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;

  const _GlassCard({
    required this.child,
    this.padding = const EdgeInsets.all(18),
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(25),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 14,
          sigmaY: 14,
        ),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.76),
            borderRadius: BorderRadius.circular(25),
            border: Border.all(
              color: Colors.white.withOpacity(0.95),
              width: 1.4,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3976C8).withOpacity(0.07),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

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
      3.141592653589793 * 2,
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

    const startAngle = -1.5707963267948966;

    final presentSweep =
        (present / total) * 6.283185307179586;

    final gap = total > 1 ? 0.055 : 0.0;

    if (present > 0) {
      canvas.drawArc(
        chartRect,
        startAngle,
        (presentSweep - gap).clamp(0.0, 6.283185307179586),
        false,
        presentPaint,
      );
    }

    if (absent > 0) {
      canvas.drawArc(
        chartRect,
        startAngle + presentSweep + gap,
        ((absent / total) * 6.283185307179586 - gap)
            .clamp(0.0, 6.283185307179586),
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
