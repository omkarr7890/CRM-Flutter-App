
import 'dart:ui';

import 'package:flutter/material.dart';

import '../AppDrawer/app_drawer.dart';

const Color _deepBlue = Color(0xFF173B8F);
const Color _blue = Color(0xFF2563EB);
const Color _cyan = Color(0xFF06B6D4);
const Color _ink = Color(0xFF172554);
const Color _muted = Color(0xFF64748B);

/// Reusable CRM app bar.
///
/// IMPORTANT:
/// The page displaying this widget must have
/// drawer: AppDrawer(...) on its Scaffold.
class CrmAppBar extends StatelessWidget {
  const CrmAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Hamburger button
        Builder(
          builder: (drawerContext) {
            return Material(
              color: Colors.white.withOpacity(0.92),
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () {
                  final scaffold = Scaffold.maybeOf(drawerContext);

                  if (scaffold != null && scaffold.hasDrawer) {
                    scaffold.openDrawer();
                  } else {
                    debugPrint(
                      'CrmAppBar: No drawer is attached to this Scaffold.',
                    );
                  }
                },
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFFE1EAF8),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _deepBlue.withOpacity(0.06),
                        blurRadius: 14,
                        offset: const Offset(0, 5),
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.menu_rounded,
                    color: _deepBlue,
                    size: 25,
                  ),
                ),
              ),
            );
          },
        ),

        const SizedBox(width: 12),

        // CRM branding
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: 10,
                sigmaY: 10,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 13,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.78),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.95),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            _deepBlue,
                            _blue,
                            _cyan,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(13),
                        boxShadow: [
                          BoxShadow(
                            color: _blue.withOpacity(0.22),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.business_center_rounded,
                        color: Colors.white,
                        size: 22,
                      ),
                    ),

                    const SizedBox(width: 11),

                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'CRM',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _ink,
                              fontSize: 17,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'FIELD OPERATIONS',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: _muted,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.25,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 4),

                    Container(
                      width: 7,
                      height: 7,
                      decoration: const BoxDecoration(
                        color: Color(0xFF22C55E),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Optional shared Scaffold wrapper.
///
/// Use this only on pages that do not already create their own Scaffold.
/// If a page already has a Scaffold, add AppDrawer to that existing Scaffold
/// instead of nesting another Scaffold around it.
class CrmScaffold extends StatelessWidget {
  final CrmPage selectedPage;
  final Widget body;
  final Color backgroundColor;
  final VoidCallback onProfileTap;
  final VoidCallback onEmployeeTrackerTap;
  final VoidCallback onLogoutTap;

  const CrmScaffold({
    super.key,
    required this.selectedPage,
    required this.body,
    required this.onProfileTap,
    required this.onEmployeeTrackerTap,
    required this.onLogoutTap,
    this.backgroundColor = const Color(0xFFF5F8FF),
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundColor,
      drawer: AppDrawer(
        selectedPage: selectedPage,
        onProfileTap: onProfileTap,
        onEmployeeTrackerTap: onEmployeeTrackerTap,
        onLogoutTap: onLogoutTap,
      ),
      body: body,
    );
  }
}
