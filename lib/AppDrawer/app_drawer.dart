
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Leave_Application/LeaveApplication.dart';
import '../Employee Tracker/employee_tracker_page.dart';
import '../Login Page/login.dart';
import '../main.dart' show navigatorKey;

class CrmColors {
  static const Color primary = Color(0xFF0755D9);
  static const Color secondary = Color(0xFF43C8F5);
  static const Color dark = Color(0xFF10213F);
  static const Color background = Color(0xFFF5F8FF);
  static const Color text = Color(0xFF24324A);
  static const Color muted = Color(0xFF71819B);
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
  String userName = 'Employee';
  String userEmail = '';
  String designation = '';
  String employeeId = '';
  String userType = '';

  bool isLoading = true;
  bool isLoggingOut = false;

  @override
  void initState() {
    super.initState();
    _loadEmployeeDetails();
  }

  Future<void> _loadEmployeeDetails() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      if (!mounted) return;

      setState(() {
        final savedName =
            prefs.getString('emp_name') ??
                prefs.getString('empName') ??
                '';

        userName = savedName.trim().isNotEmpty
            ? savedName.trim()
            : 'Employee';

        userEmail =
            prefs.getString('email_office')?.trim() ?? '';

        designation =
            prefs.getString('designation')?.trim() ?? '';

        employeeId =
            prefs.getString('emp_id')?.trim() ?? '';

        userType =
            prefs.getString('user_type')?.trim() ?? '';

        isLoading = false;
      });
    } catch (e) {
      debugPrint('Employee details error: $e');

      if (!mounted) return;

      setState(() {
        isLoading = false;
      });
    }
  }

  void _handleNavigation(VoidCallback callback) {
    Navigator.of(context).pop();
    callback();
  }

  void _openEmployeeTracker() {
    final navigator = Navigator.of(context);

    navigator.pop();

    navigator.push(
      MaterialPageRoute(
        builder: (_) => const EmployeeTrackerPage(),
      ),
    );
  }

  void _openLeaveApplication() {
    final navigator = Navigator.of(context);

    navigator.pop();

    navigator.push(
      MaterialPageRoute(
        builder: (_) => const LeaveApplicationPage(),
      ),
    );
  }

  Future<void> _performLogout(
      BuildContext dialogContext,
      ) async {
    if (isLoggingOut) return;

    setState(() {
      isLoggingOut = true;
    });

    try {
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

      if (navigator != null) {
        navigator.pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => const LoginPage(),
          ),
              (route) => false,
        );
      } else if (dialogContext.mounted) {
        Navigator.of(
          dialogContext,
          rootNavigator: true,
        ).pushAndRemoveUntil(
          MaterialPageRoute<void>(
            builder: (_) => const LoginPage(),
          ),
              (route) => false,
        );
      }
    } catch (e) {
      debugPrint('LOGOUT ERROR: $e');

      if (dialogContext.mounted) {
        ScaffoldMessenger.of(dialogContext).showSnackBar(
          const SnackBar(
            content: Text(
              'Unable to log out. Please try again.',
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoggingOut = false;
        });
      }
    }
  }

  void _showLogoutDialog() {
    final rootContext = Navigator.of(
      context,
      rootNavigator: true,
    ).context;

    Navigator.of(context).pop();

    showGeneralDialog<void>(
      context: rootContext,
      barrierDismissible: true,
      barrierLabel: 'Logout confirmation',
      barrierColor:
      const Color(0xFF07152E).withOpacity(0.55),
      transitionDuration:
      const Duration(milliseconds: 350),
      pageBuilder: (
          dialogContext,
          animation,
          secondaryAnimation,
          ) {
        return const SizedBox.shrink();
      },
      transitionBuilder: (
          dialogContext,
          animation,
          secondaryAnimation,
          child,
          ) {
        final curvedAnimation = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutBack,
          reverseCurve: Curves.easeInCubic,
        );

        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(
              begin: 0.82,
              end: 1.0,
            ).animate(curvedAnimation),
            child: Center(
              child: Material(
                color: Colors.transparent,
                child: Container(
                  width: MediaQuery.of(
                    dialogContext,
                  ).size.width * 0.86,
                  constraints: const BoxConstraints(
                    maxWidth: 390,
                  ),
                  padding: const EdgeInsets.fromLTRB(
                    24,
                    28,
                    24,
                    24,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                    BorderRadius.circular(28),
                    border: Border.all(
                      color: const Color(0xFFDCE9FF),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: CrmColors.primary
                            .withOpacity(0.16),
                        blurRadius: 35,
                        offset: const Offset(0, 15),
                      ),
                    ],
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TweenAnimationBuilder<double>(
                          tween: Tween(
                            begin: 0,
                            end: 1,
                          ),
                          duration: const Duration(
                            milliseconds: 600,
                          ),
                          curve: Curves.elasticOut,
                          builder: (
                              context,
                              value,
                              child,
                              ) {
                            return Transform.scale(
                              scale: value,
                              child: child,
                            );
                          },
                          child: Container(
                            width: 86,
                            height: 86,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient:
                              const LinearGradient(
                                colors: [
                                  CrmColors.secondary,
                                  CrmColors.primary,
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: CrmColors.primary
                                      .withOpacity(0.22),
                                  blurRadius: 22,
                                  offset:
                                  const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons
                                  .power_settings_new_rounded,
                              color: Colors.white,
                              size: 43,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'Leaving So Soon?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 23,
                            fontWeight: FontWeight.w900,
                            color: CrmColors.dark,
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Are you sure you want to sign out of your CRM workspace?',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            height: 1.6,
                            color: CrmColors.muted,
                          ),
                        ),
                        const SizedBox(height: 28),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient:
                              const LinearGradient(
                                colors: [
                                  CrmColors.primary,
                                  Color(0xFF2787F5),
                                ],
                              ),
                              borderRadius:
                              BorderRadius.circular(
                                15,
                              ),
                            ),
                            child: ElevatedButton.icon(
                              onPressed: () =>
                                  _performLogout(
                                    dialogContext,
                                  ),
                              icon: const Icon(
                                Icons.logout_rounded,
                                size: 19,
                              ),
                              label: const Text(
                                'Yes, Log Me Out',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight:
                                  FontWeight.w800,
                                ),
                              ),
                              style:
                              ElevatedButton.styleFrom(
                                backgroundColor:
                                Colors.transparent,
                                shadowColor:
                                Colors.transparent,
                                foregroundColor:
                                Colors.white,
                                shape:
                                RoundedRectangleBorder(
                                  borderRadius:
                                  BorderRadius.circular(
                                    15,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(
                                dialogContext,
                              ).pop();
                            },
                            style:
                            OutlinedButton.styleFrom(
                              foregroundColor:
                              CrmColors.primary,
                              backgroundColor:
                              const Color(
                                0xFFF3F7FF,
                              ),
                              side: const BorderSide(
                                color: Color(0xFFDCE8FF),
                              ),
                              shape:
                              RoundedRectangleBorder(
                                borderRadius:
                                BorderRadius.circular(
                                  15,
                                ),
                              ),
                            ),
                            child: const Text(
                              'Stay Logged In',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight:
                                FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        const Row(
                          mainAxisAlignment:
                          MainAxisAlignment.center,
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
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 310,
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topRight: Radius.circular(26),
          bottomRight: Radius.circular(26),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 16,
            sigmaY: 16,
          ),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.98),
                  const Color(0xFFEAF2FF),
                  const Color(0xFFF7FAFF),
                ],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  _buildProfileHeader(),
                  const SizedBox(height: 24),
                  const Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 22,
                    ),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'WORKSPACE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 2,
                          color: CrmColors.muted,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Expanded(
                    child: ListView(
                      padding:
                      const EdgeInsets.symmetric(
                        horizontal: 14,
                      ),
                      children: [
                        _buildDrawerItem(
                          title: 'Profile',
                          subtitle:
                          'Your personal account',
                          icon: Icons.person_rounded,
                          selected:
                          widget.selectedPage ==
                              CrmPage.profile,
                          onTap: () =>
                              _handleNavigation(
                                widget.onProfileTap,
                              ),
                        ),
                        const SizedBox(height: 10),
                        _buildDrawerItem(
                          title: 'Employee Tracker',
                          subtitle:
                          'Track employee activity',
                          icon:
                          Icons.location_on_rounded,
                          selected:
                          widget.selectedPage ==
                              CrmPage.employeeTracker,
                          onTap: _openEmployeeTracker,
                        ),
                        const SizedBox(height: 10),
                        _buildDrawerItem(
                          title: 'Leave Application',
                          subtitle:
                          'Apply for and manage leave',
                          icon:
                          Icons.event_note_rounded,
                          selected: false,
                          onTap: _openLeaveApplication,
                        ),
                      ],
                    ),
                  ),
                  const Divider(
                    color: Color(0xFFDCE5F5),
                    indent: 22,
                    endIndent: 22,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(
                      14,
                      8,
                      14,
                      16,
                    ),
                    child: _buildDrawerItem(
                      title: 'Log Out',
                      subtitle:
                      'Sign out of your account',
                      icon: Icons.logout_rounded,
                      selected: false,
                      isLogout: true,
                      onTap: _showLogoutDialog,
                    ),
                  ),
                ],
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
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    CrmColors.primary.withOpacity(0.13),
                    CrmColors.secondary.withOpacity(0.10),
                    Colors.white.withOpacity(0.35),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: -55,
            right: -35,
            child: Container(
              width: 155,
              height: 155,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CrmColors.secondary
                    .withOpacity(0.12),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              23,
              25,
              20,
              24,
            ),
            child: isLoading
                ? const SizedBox(
              height: 120,
              child: Center(
                child: CircularProgressIndicator(
                  color: CrmColors.primary,
                  strokeWidth: 2,
                ),
              ),
            )
                : Column(
              crossAxisAlignment:
              CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: Colors.white
                            .withOpacity(0.8),
                        borderRadius:
                        BorderRadius.circular(
                          10,
                        ),
                      ),
                      child: const Icon(
                        Icons.auto_awesome_rounded,
                        size: 17,
                        color: CrmColors.primary,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'CRM WORKSPACE',
                        style: TextStyle(
                          color: CrmColors.primary,
                          fontSize: 11,
                          fontWeight:
                          FontWeight.w900,
                          letterSpacing: 1.8,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () =>
                          Navigator.of(context)
                              .pop(),
                      icon: const Icon(
                        Icons.close_rounded,
                        color: CrmColors.dark,
                        size: 21,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 23),
                Row(
                  children: [
                    Container(
                      width: 68,
                      height: 68,
                      padding:
                      const EdgeInsets.all(3),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient:
                        const LinearGradient(
                          colors: [
                            CrmColors.secondary,
                            CrmColors.primary,
                            CrmColors.dark,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: CrmColors.primary
                                .withOpacity(0.2),
                            blurRadius: 18,
                            offset:
                            const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Container(
                        decoration:
                        const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                        ),
                        child: Center(
                          child: Text(
                            userName.isNotEmpty
                                ? userName[0]
                                .toUpperCase()
                                : 'E',
                            style:
                            const TextStyle(
                              color:
                              CrmColors.primary,
                              fontSize: 29,
                              fontWeight:
                              FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 15),
                    Expanded(
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment
                            .start,
                        children: [
                          Text(
                            userName,
                            maxLines: 2,
                            overflow:
                            TextOverflow.ellipsis,
                            style:
                            const TextStyle(
                              color:
                              CrmColors.primary,
                              fontSize: 20,
                              height: 1.15,
                              fontWeight:
                              FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration:
                                const BoxDecoration(
                                  shape:
                                  BoxShape.circle,
                                  color:
                                  Color(0xFF17A5DB),
                                ),
                              ),
                              const SizedBox(
                                width: 7,
                              ),
                              Expanded(
                                child: Text(
                                  designation
                                      .isNotEmpty
                                      ? designation
                                      : 'CRM Team',
                                  maxLines: 2,
                                  overflow:
                                  TextOverflow
                                      .ellipsis,
                                  style:
                                  const TextStyle(
                                    color:
                                    Color(0xFF526D91),
                                    fontSize: 12,
                                    fontWeight:
                                    FontWeight.w600,
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
                const SizedBox(height: 23),
                Row(
                  children: [
                    const Icon(
                      Icons.mail_rounded,
                      size: 18,
                      color: CrmColors.primary,
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Text(
                        userEmail.isNotEmpty
                            ? userEmail
                            : 'Email unavailable',
                        maxLines: 2,
                        overflow:
                        TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF344F73),
                          fontSize: 12,
                          fontWeight:
                          FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 22),
                Container(
                  height: 2,
                  width: 76,
                  decoration: BoxDecoration(
                    borderRadius:
                    BorderRadius.circular(10),
                    gradient:
                    const LinearGradient(
                      colors: [
                        CrmColors.primary,
                        CrmColors.secondary,
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

  Widget _buildDrawerItem({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    final Color accent = isLogout
        ? const Color(0xFFE5485D)
        : CrmColors.primary;

    return Material(
      color: selected
          ? accent.withOpacity(0.09)
          : isLogout
          ? const Color(0xFFFFF0F0)
          : Colors.white.withOpacity(0.55),
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(
            horizontal: 13,
            vertical: 13,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: selected
                  ? accent.withOpacity(0.22)
                  : isLogout
                  ? const Color(0xFFFFDADA)
                  : Colors.white.withOpacity(0.9),
            ),
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration:
                const Duration(milliseconds: 220),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  gradient: selected && !isLogout
                      ? const LinearGradient(
                    colors: [
                      CrmColors.primary,
                      CrmColors.secondary,
                    ],
                  )
                      : null,
                  color: selected && !isLogout
                      ? null
                      : isLogout
                      ? accent.withOpacity(0.09)
                      : Colors.white,
                  borderRadius:
                  BorderRadius.circular(14),
                ),
                child: Icon(
                  icon,
                  color: selected && !isLogout
                      ? Colors.white
                      : accent,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                  CrossAxisAlignment.start,
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
                    borderRadius:
                    BorderRadius.circular(10),
                  ),
                )
              else
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 13,
                  color: isLogout
                      ? accent
                      : const Color(0xFF8996AB),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
