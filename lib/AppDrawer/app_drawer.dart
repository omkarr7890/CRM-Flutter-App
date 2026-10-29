
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Identifies the page currently displayed in the application.
enum CrmPage {
  profile,
  employeeTracker,
}

class CrmColors {
  static const Color primary = Color(0xFF0755D9);
  static const Color secondary = Color(0xFF43C8F5);
  static const Color dark = Color(0xFF10213F);
  static const Color background = Color(0xFFF5F8FF);
  static const Color text = Color(0xFF24324A);
  static const Color muted = Color(0xFF71819B);
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
  String _employeeName = 'Employee';
  String _employeeEmail = '';
  String _designation = '';

  @override
  void initState() {
    super.initState();
    _loadEmployeeDetails();
  }

  Future<void> _loadEmployeeDetails() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _employeeName =
      prefs.getString('emp_name')?.trim().isNotEmpty == true
          ? prefs.getString('emp_name')!.trim()
          : 'Employee';

      _employeeEmail =
          prefs.getString('email_office')?.trim() ?? '';

      _designation =
          prefs.getString('designation')?.trim() ?? '';
    });
  }

  /// Closes the drawer first, then runs the navigation callback.
  void _handleTap(VoidCallback callback) {
    Navigator.of(context).pop();
    callback();
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 310,
      elevation: 0,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFF5F8FF),
              Color(0xFFE8F2FF),
              Color(0xFFF9FCFF),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              _buildProfileHeader(),

              const SizedBox(height: 24),

              // Navigation heading
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 22),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'WORKSPACE',
                    style: TextStyle(
                      color: CrmColors.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Navigation items
              _buildDrawerItem(
                icon: Icons.person_rounded,
                title: 'Profile',
                subtitle: 'Your personal workspace',
                selected: widget.selectedPage == CrmPage.profile,
                onTap: () => _handleTap(widget.onProfileTap),
              ),

              _buildDrawerItem(
                icon: Icons.location_searching_rounded,
                title: 'Employee Tracker',
                subtitle: 'Track your workforce',
                selected:
                widget.selectedPage == CrmPage.employeeTracker,
                onTap: () =>
                    _handleTap(widget.onEmployeeTrackerTap),
              ),

              const Spacer(),

              // Logout
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 18),
                child: _buildLogoutItem(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(22, 24, 18, 24),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0739A8),
            Color(0xFF0755D9),
            Color(0xFF168DDC),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: ClipRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 62,
                    height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withOpacity(0.18),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.55),
                        width: 1.5,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _employeeName.trim().isNotEmpty
                            ? _employeeName.trim()[0].toUpperCase()
                            : 'E',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 27,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    tooltip: 'Close drawer',
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: Colors.white,
                      size: 23,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              Text(
                _employeeName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 23,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.2,
                ),
              ),

              if (_designation.isNotEmpty) ...[
                const SizedBox(height: 7),
                Row(
                  children: [
                    const Icon(
                      Icons.work_outline_rounded,
                      color: Color(0xFFBFEAFF),
                      size: 16,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        _designation,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE1F3FF),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ],

              if (_employeeEmail.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(
                      Icons.mail_outline_rounded,
                      color: Color(0xFFBFEAFF),
                      size: 16,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        _employeeEmail,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFFE1F3FF),
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDrawerItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 5,
      ),
      child: Material(
        color: selected
            ? CrmColors.primary.withOpacity(0.10)
            : Colors.white.withOpacity(0.45),
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: selected
                    ? CrmColors.primary.withOpacity(0.24)
                    : Colors.white.withOpacity(0.8),
              ),
            ),
            child: Row(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: selected
                        ? const LinearGradient(
                      colors: [
                        CrmColors.primary,
                        CrmColors.secondary,
                      ],
                    )
                        : null,
                    color: selected
                        ? null
                        : const Color(0xFFE7F0FF),
                  ),
                  child: Icon(
                    icon,
                    color: selected
                        ? Colors.white
                        : CrmColors.primary,
                    size: 23,
                  ),
                ),

                const SizedBox(width: 13),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: selected
                              ? CrmColors.primary
                              : CrmColors.dark,
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: CrmColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),

                Icon(
                  selected
                      ? Icons.radio_button_checked_rounded
                      : Icons.arrow_forward_ios_rounded,
                  size: selected ? 19 : 14,
                  color: selected
                      ? CrmColors.primary
                      : const Color(0xFF9BAAC0),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutItem() {
    return Material(
      color: const Color(0xFFFFF0F0).withOpacity(0.85),
      borderRadius: BorderRadius.circular(17),
      child: InkWell(
        onTap: () => _handleTap(widget.onLogoutTap),
        borderRadius: BorderRadius.circular(17),
        child: Container(
          padding: const EdgeInsets.symmetric(
            horizontal: 15,
            vertical: 15,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(17),
            border: Border.all(
              color: const Color(0xFFFFDADA),
            ),
          ),
          child: const Row(
            children: [
              Icon(
                Icons.logout_rounded,
                color: Color(0xFFD92D3A),
                size: 22,
              ),
              SizedBox(width: 13),
              Expanded(
                child: Text(
                  'Log Out',
                  style: TextStyle(
                    color: Color(0xFFD92D3A),
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: Color(0xFFD92D3A),
                size: 19,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
