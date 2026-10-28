import 'dart:ui';
import '../Leave_Application/LeaveApplication.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../Employee Tracker/employee_tracker_page.dart';
import '../Login Page/login.dart';
import '../main.dart' show navigatorKey;


class CrmColors {
  static const Color primary = Color(0xFF0755D9);
  static const Color secondary = Color(0xFF43C8F5);
  static const Color dark = Color(0xFF10213F);
  static const Color background = Color(0xFFF5F8FF);
  static const Color text = Color(0xFF24324A);
}

enum CrmPage {
  profile,
  employeeTracker,
}

class AppDrawer extends StatefulWidget {
  final CrmPage selectedPage;
  final VoidCallback onProfileTap;
  final VoidCallback onEmployeeTrackerTap;
  final VoidCallback onLogoutTap;

  const AppDrawer({
    super.key,
    required this.selectedPage,
    required this.onProfileTap,
    required this.onEmployeeTrackerTap,
    required this.onLogoutTap,
  });

  @override
  State<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends State<AppDrawer> {
  String userName = '';
  String userEmail = '';
  String designation = '';
  String employeeId = '';
  String userType = '';
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadEmployeeDetails();
  }

  Future<void> _loadEmployeeDetails() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      userName = prefs.getString('emp_name') ?? '';
      userEmail = prefs.getString('email_office') ?? '';
      designation = prefs.getString('designation') ?? '';
      employeeId = prefs.getString('emp_id') ?? '';
      userType = prefs.getString('user_type') ?? '';
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 310,
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.98),
                  const Color(0xFFEAF2FF).withOpacity(0.98),
                  const Color(0xFFF6F9FF),
                ],
              ),
              border: Border(
                right: BorderSide(
                  color: Colors.white.withOpacity(0.8),
                  width: 1.5,
                ),
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 22),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'WORKSPACE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: Color(0xFF8190AA),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: Column(
                      children: [
                        _buildDrawerItem(
                          title: 'Profile',
                          subtitle: 'Your personal account',
                          icon: Icons.person_rounded,
                          selected: widget.selectedPage == CrmPage.profile,
                          onTap: () {
                            Navigator.pop(context);
                            widget.onProfileTap();
                          },
                        ),
                        const SizedBox(height: 10),
                        _buildDrawerItem(
                          title: 'Employee Tracker',
                          subtitle: 'Track employee activity',
                          icon: Icons.location_on_rounded,
                          selected: widget.selectedPage ==
                              CrmPage.employeeTracker,
                          onTap: () {
                            Navigator.pop(context); // Close the drawer

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const EmployeeTrackerPage(),
                              ),
                            );
                          },
                        ),

                        const SizedBox(height: 10),

                        _buildDrawerItem(
                          title: 'Leave Application',
                          subtitle: 'Apply for and manage your leave',
                          icon: Icons.event_note_rounded,
                          selected: false,
                          onTap: () {
                            Navigator.pop(context);

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LeaveApplicationPage(),
                              ),
                            );
                          },
                        ),


                      ],
                    ),
                  ),
                  const Spacer(),
                  const Divider(
                    color: Color(0xFFDCE5F5),
                    indent: 22,
                    endIndent: 22,
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 8, 14, 14),
                  child: _buildDrawerItem(
                    title: 'Log Out',
                    subtitle: 'Sign out of your account',
                    icon: Icons.logout_rounded,
                    selected: false,
                    isLogout: true,
                    onTap: () {
                      Navigator.pop(context); // Close drawer first


                      showGeneralDialog(
                        context: context,
                        barrierDismissible: true,
                        barrierLabel: 'Logout confirmation',
                        barrierColor: const Color(0xFF07152E).withOpacity(0.55),
                        transitionDuration: const Duration(milliseconds: 400),
                        pageBuilder: (dialogContext, animation, secondaryAnimation) {
                          return const SizedBox.shrink();
                        },
                        transitionBuilder: (dialogContext, animation, secondaryAnimation, child) {
                          final curvedAnimation = CurvedAnimation(
                            parent: animation,
                            curve: Curves.easeOutBack,
                            reverseCurve: Curves.easeInCubic,
                          );

                          return FadeTransition(
                            opacity: animation,
                            child: ScaleTransition(
                              scale: Tween<double>(
                                begin: 0.75,
                                end: 1.0,
                              ).animate(curvedAnimation),
                              child: Center(
                                child: Material(
                                  color: Colors.transparent,
                                  child: Container(
                                    width: MediaQuery.of(dialogContext).size.width * 0.86,
                                    margin: const EdgeInsets.symmetric(horizontal: 20),
                                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(30),
                                      border: Border.all(
                                        color: const Color(0xFFDCE9FF),
                                        width: 1.2,
                                      ),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFF0755D9).withOpacity(0.18),
                                          blurRadius: 35,
                                          offset: const Offset(0, 15),
                                        ),
                                      ],
                                    ),
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        // Animated blue icon
                                        TweenAnimationBuilder<double>(
                                          tween: Tween(begin: 0.0, end: 1.0),
                                          duration: const Duration(milliseconds: 650),
                                          curve: Curves.elasticOut,
                                          builder: (context, value, child) {
                                            return Transform.scale(
                                              scale: value,
                                              child: child,
                                            );
                                          },
                                          child: Container(
                                            width: 94,
                                            height: 94,
                                            decoration: BoxDecoration(
                                              shape: BoxShape.circle,
                                              gradient: const LinearGradient(
                                                begin: Alignment.topLeft,
                                                end: Alignment.bottomRight,
                                                colors: [
                                                  Color(0xFF43C8F5),
                                                  Color(0xFF0755D9),
                                                ],
                                              ),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF0755D9)
                                                      .withOpacity(0.25),
                                                  blurRadius: 24,
                                                  offset: const Offset(0, 9),
                                                ),
                                              ],
                                            ),
                                            child: const Icon(
                                              Icons.power_settings_new_rounded,
                                              color: Colors.white,
                                              size: 46,
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 25),

                                        const Text(
                                          'Leaving So Soon?',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 24,
                                            fontWeight: FontWeight.w900,
                                            letterSpacing: -0.6,
                                            color: Color(0xFF10213F),
                                          ),
                                        ),

                                        const SizedBox(height: 12),

                                        const Text(
                                          'Are you sure you want to sign out of your CRM workspace?',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            fontSize: 14,
                                            height: 1.6,
                                            color: Color(0xFF71809A),
                                          ),
                                        ),

                                        const SizedBox(height: 30),

                                        // Confirm logout
                                        SizedBox(
                                          width: double.infinity,
                                          height: 52,
                                          child: DecoratedBox(
                                            decoration: BoxDecoration(
                                              gradient: const LinearGradient(
                                                colors: [
                                                  Color(0xFF0755D9),
                                                  Color(0xFF2787F5),
                                                ],
                                              ),
                                              borderRadius: BorderRadius.circular(16),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: const Color(0xFF0755D9)
                                                      .withOpacity(0.22),
                                                  blurRadius: 14,
                                                  offset: const Offset(0, 6),
                                                ),
                                              ],
                                            ),
                                            child: ElevatedButton(
                                              // Open Login page through parent callback


                                              onPressed: () async {
                                                debugPrint('LOGOUT: Button clicked');

                                                final prefs = await SharedPreferences.getInstance();

                                                await prefs.setBool('isLoggedIn', false);
                                                await prefs.remove('empName');
                                                await prefs.remove('emp_name');
                                                await prefs.remove('email_office');
                                                await prefs.remove('designation');
                                                await prefs.remove('emp_id');
                                                await prefs.remove('user_type');

                                                debugPrint('LOGOUT: Session cleared');

                                                final navigator = navigatorKey.currentState;

                                                if (navigator == null) {
                                                  debugPrint('LOGOUT ERROR: Root navigator is unavailable');
                                                  return;
                                                }

                                                navigator.pushAndRemoveUntil(
                                                  MaterialPageRoute<void>(
                                                    builder: (_) => const LoginPage(),
                                                  ),
                                                      (route) => false,
                                                );

                                                debugPrint('LOGOUT: LoginPage opened');
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                foregroundColor: Colors.white,
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(16),
                                                ),
                                              ),
                                              child: const Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Icon(Icons.logout_rounded, size: 19),
                                                  SizedBox(width: 9),
                                                  Text(
                                                    'Yes, Log Me Out',
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.w800,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 12),

                                        // Cancel
                                        SizedBox(
                                          width: double.infinity,
                                          height: 50,
                                          child: OutlinedButton(
                                            onPressed: () => Navigator.pop(dialogContext),
                                            style: OutlinedButton.styleFrom(
                                              foregroundColor: const Color(0xFF0755D9),
                                              backgroundColor: const Color(0xFFF3F7FF),
                                              side: const BorderSide(
                                                color: Color(0xFFDCE8FF),
                                              ),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(16),
                                              ),
                                            ),
                                            child: const Text(
                                              'Stay Logged In',
                                              style: TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ),
                                        ),

                                        const SizedBox(height: 15),

                                        const Row(
                                          mainAxisAlignment: MainAxisAlignment.center,
                                          children: [
                                            Icon(
                                              Icons.lock_outline_rounded,
                                              size: 14,
                                              color: Color(0xFF91A0B8),
                                            ),
                                            SizedBox(width: 6),
                                            Text(
                                              'Your account security matters',
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Color(0xFF91A0B8),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );

                    },
                  ),
                ),            ]
            ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        bottomLeft: Radius.circular(30),
        bottomRight: Radius.circular(30),
      ),
      child: Stack(
        children: [
          // Full-width glass background
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 25,
                sigmaY: 25,
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF0755D9).withOpacity(0.13),
                      const Color(0xFF43C8F5).withOpacity(0.10),
                      Colors.white.withOpacity(0.32),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Decorative glass glow
          Positioned(
            top: -55,
            right: -35,
            child: Container(
              width: 155,
              height: 155,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF43C8F5).withOpacity(0.12),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(23, 27, 23, 24),
            child: isLoading
                ? const SizedBox(
              height: 100,
              child: Center(
                child: CircularProgressIndicator(
                  color: CrmColors.primary,
                  strokeWidth: 2,
                ),
              ),
            )
                : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Brand label
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 17,
                        color: CrmColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      'CRM WORKSPACE',
                      style: TextStyle(
                        color: Color(0xFF0755D9),
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 2,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 27),

                // Large avatar + prominent name
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      padding: const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color(0xFF43C8F5),
                            Color(0xFF0755D9),
                            Color(0xFF10213F),
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF0755D9)
                                .withOpacity(0.23),
                            blurRadius: 20,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.94),
                        ),
                        child: Center(
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              color: CrmColors.primary,
                              fontSize: 29,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          Text(
                            userName.isNotEmpty
                                ? userName
                                : 'Welcome',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF0755D9),
                              fontSize: 21,
                              height: 1.15,
                              fontWeight: FontWeight.w900,
                              letterSpacing: -0.6,
                            ),
                          ),

                          const SizedBox(height: 8),

                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Color(0xFF17A5DB),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Expanded(
                                child: Text(
                                  designation.isNotEmpty
                                      ? designation
                                      : 'CRM Team',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Color(0xFF526D91),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 25),

                // Email row, without a card or container
                Row(
                  children: [
                    const Icon(
                      Icons.mail_rounded,
                      size: 19,
                      color: Color(0xFF0755D9),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        userEmail.isNotEmpty
                            ? userEmail
                            : 'Email unavailable',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF344F73),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 23),

                // Elegant bottom glass accent
                Container(
                  height: 2,
                  width: 76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFF0755D9),
                        Color(0xFF43C8F5),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _infoBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.17),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final Color accent =
    isLogout ? const Color(0xFFE5485D) : CrmColors.primary;

    return Material(
      color: selected
          ? accent.withOpacity(0.09)
          : Colors.white.withOpacity(0.55),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? accent.withOpacity(0.22)
                  : Colors.white.withOpacity(0.9),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: selected && !isLogout
                      ? const LinearGradient(
                    colors: [CrmColors.primary, CrmColors.secondary],
                  )
                      : null,
                  color: isLogout
                      ? accent.withOpacity(0.09)
                      : selected
                      ? null
                      : Colors.white,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: selected && !isLogout ? Colors.white : accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: isLogout
                            ? accent
                            : selected
                            ? CrmColors.primary
                            : CrmColors.text,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 10,
                        color: Color(0xFF8996AB),
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                Container(
                  width: 4,
                  height: 28,
                  decoration: BoxDecoration(
                    color: CrmColors.primary,
                    borderRadius: BorderRadius.circular(10),
                  ),
                )
              else
                const Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: Color(0xFF8996AB),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
