import 'dart:ui';
import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class EmployeeTrackerPage extends StatefulWidget {
  const EmployeeTrackerPage({super.key});

  @override
  State<EmployeeTrackerPage> createState() => _EmployeeTrackerPageState();
}

class _EmployeeTrackerPageState extends State<EmployeeTrackerPage>
    with SingleTickerProviderStateMixin {
  static const Color blue = Color(0xFF0755D9);
  static const Color darkBlue = Color(0xFF0739A8);
  static const Color cyan = Color(0xFF43C8F5);
  static const Color background = Color(0xFFF1F7FF);
  static const Color textBlue = Color(0xFF163B80);

  final TextEditingController _searchController = TextEditingController();

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _showSearchResults = false;
  String _searchQuery = '';
  Map<String, dynamic>? _selectedEmployee;

  List<Map<String, dynamic>> _employees = [];

  bool _isLoadingEmployees = false;
  String? _employeeApiError;

// Temporary UI data. Replace with the employee-list API later.

  List<Map<String, dynamic>> get _filteredEmployees {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) return _employees;

    return _employees.where((employee) {
      return employee['emp_name']
          .toString()
          .toLowerCase()
          .contains(query);
    }).toList();
  }

  Future<void> _fetchEmployees() async {
    if (!mounted) return;

    setState(() {
      _isLoadingEmployees = true;
      _employeeApiError = null;
    });

    try {
      final response = await http.post(
        Uri.parse(
          'https://salasarcrm.aonesalasar.com/api/mobile/get-users',
        ),
        headers: const {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 20));

      debugPrint('Employee API status: ${response.statusCode}');
      debugPrint('Employee API body: ${response.body}');

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(
          'HTTP ${response.statusCode}: ${response.body}',
        );
      }

      final dynamic decoded = jsonDecode(response.body);
      final List<dynamic> users = _extractUsers(decoded);

      final List<Map<String, dynamic>> employees = users
          .whereType<Map>()
          .where((user) => user['emp_name'] != null)
          .map<Map<String, dynamic>>((user) => {
        'emp_name': user['emp_name'].toString().trim(),
        'emp_id': user['emp_id'],
      })
          .where((user) => (user['emp_name'] as String).isNotEmpty)
          .toList();

      debugPrint('Employees extracted: ${employees.length}');

      if (!mounted) return;

      setState(() {
        _employees = employees;
        _isLoadingEmployees = false;

        if (employees.isEmpty) {
          _employeeApiError =
          'The API responded, but no employee names were found. Check the API response in Debug Console.';
        }
      });
    } catch (e, stackTrace) {
      debugPrint('Employee API error: $e');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _employeeApiError = 'Failed to load employees: $e';
        _isLoadingEmployees = false;
      });
    }
  }
  List<dynamic> _extractUsers(dynamic decoded) {
    if (decoded is List) {
      return decoded;
    }

    if (decoded is Map) {
      // A single employee record.
      if (decoded.containsKey('emp_name')) {
        return [decoded];
      }

      // Common API response keys.
      for (final key in [
        'data',
        'users',
        'employees',
        'results',
        'result',
      ]) {
        if (decoded.containsKey(key)) {
          final result = _extractUsers(decoded[key]);

          if (result.isNotEmpty) {
            return result;
          }
        }
      }
    }

    return [];
  }


  @override
  void initState() {
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    );

    _animationController.forward();
    _fetchEmployees();  }

  @override
  void dispose() {
    _animationController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _selectEmployee(Map<String, dynamic> employee) {
    setState(() {
      _selectedEmployee = employee;
      _searchController.text = employee['emp_name'].toString();
      _searchQuery = employee['emp_name'].toString();
      _showSearchResults = false;
    });

    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 28),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  _buildSummary(),
                  const SizedBox(height: 24),
                  _buildSearchSection(),
                  const SizedBox(height: 24),
                  _buildMapCard(),
                  const SizedBox(height: 24),
                  _buildEmployeeSection(),
                  const SizedBox(height: 20),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 18,
        20,
        28,
      ),
      decoration: const BoxDecoration(
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(34),
          bottomRight: Radius.circular(34),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [darkBlue, blue, Color(0xFF38BDF8)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.17),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                child: const Icon(
                  Icons.location_searching_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              const SizedBox(width: 13),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Employee Tracker',
                      style: TextStyle(
                        fontSize: 23,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your team, all in one place',
                      style: TextStyle(
                        fontSize: 13,
                        color: Color(0xFFDCEBFF),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 23,
                ),
              ),
            ],
          ),
          const SizedBox(height: 26),
          const Text(
            'Track your workforce',
            style: TextStyle(
              fontSize: 25,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            'Find employees and view their location details.',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.85),
            ),
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
              child: Container(
                padding: const EdgeInsets.all(15),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.25),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.groups_rounded,
                      color: Colors.white,
                      size: 28,
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Employee Directory',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Search and select your team',
                            style: TextStyle(
                              color: Color(0xFFE4F2FF),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummary() {
    return Row(
      children: [
        Expanded(
          child: _summaryCard(
            icon: Icons.people_alt_rounded,
            title: 'Employees',
            value: '—',
            subtitle: 'Directory total',
            color: blue,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _summaryCard(
            icon: Icons.location_on_rounded,
            title: 'Locations',
            value: '—',
            subtitle: 'GPS available',
            color: const Color(0xFF0891B2),
          ),
        ),
      ],
    );
  }

  Widget _summaryCard({
    required IconData icon,
    required String title,
    required String value,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE1ECFC)),
        boxShadow: [
          BoxShadow(
            color: blue.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: color, size: 23),
          ),
          const SizedBox(height: 15),
          Text(
            value,
            style: const TextStyle(
              color: textBlue,
              fontSize: 27,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: const TextStyle(
              color: textBlue,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF8195B8),
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildSearchSection() {
    final results = _filteredEmployees;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Find an employee',
          style: TextStyle(
            color: textBlue,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Search by employee name or ID',
          style: TextStyle(
            color: Color(0xFF8195B8),
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 15),

        // Search bar
        TextField(
          controller: _searchController,
          onTap: () {
            setState(() {
              _showSearchResults = true;
            });

            if (_employees.isEmpty && !_isLoadingEmployees) {
              _fetchEmployees();
            }
          },
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _showSearchResults = true;
            });
          },
          decoration: InputDecoration(
            hintText: 'Search employee...',
            prefixIcon: const Icon(
              Icons.search_rounded,
              color: blue,
            ),
            suffixIcon: IconButton(
              icon: Icon(
                _showSearchResults
                    ? Icons.keyboard_arrow_up_rounded
                    : Icons.keyboard_arrow_down_rounded,
                color: blue,
              ),
              onPressed: () {
                setState(() {
                  _showSearchResults = !_showSearchResults;
                });

                if (_showSearchResults &&
                    _employees.isEmpty &&
                    !_isLoadingEmployees) {
                  _fetchEmployees();
                }
              },
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 18,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(19),
              borderSide: const BorderSide(
                color: Color(0xFFE0EBFC),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(19),
              borderSide: const BorderSide(
                color: Color(0xFFE0EBFC),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(19),
              borderSide: const BorderSide(
                color: blue,
                width: 1.7,
              ),
            ),
          ),
        ),

        // Employee dropdown
        if (_showSearchResults) ...[
          const SizedBox(height: 8),
          Container(
            constraints: const BoxConstraints(maxHeight: 280),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: const Color(0xFFE1ECFC),
              ),
              boxShadow: [
                BoxShadow(
                  color: blue.withOpacity(0.06),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: _isLoadingEmployees
                ? const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: CircularProgressIndicator(
                  color: blue,
                ),
              ),
            )
                : _employeeApiError != null
                ? Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_employeeApiError!),
                  TextButton(
                    onPressed: _fetchEmployees,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            )
                : results.isEmpty
                ? const Padding(
              padding: EdgeInsets.all(18),
              child: Center(
                child: Text('No employees found'),
              ),
            )
                : ListView.separated(
              shrinkWrap: true,
              padding: const EdgeInsets.symmetric(
                vertical: 6,
              ),
              itemCount: results.length,
              separatorBuilder: (_, __) =>
              const Divider(
                height: 1,
                indent: 60,
                color: Color(0xFFEAF0FA),
              ),
              itemBuilder: (context, index) {
                final employee = results[index];
                final name =
                employee['emp_name'].toString();

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                    const Color(0xFFE5EFFF),
                    child: Text(
                      name[0].toUpperCase(),
                      style: const TextStyle(
                        color: blue,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  title: Text(
                    name,
                    style: const TextStyle(
                      color: textBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  subtitle: Text(
                    'Employee ID: ${employee['emp_id']}',
                  ),
                  trailing: const Icon(
                    Icons.arrow_forward_ios_rounded,
                    color: blue,
                    size: 16,
                  ),
                  onTap: () =>
                      _selectEmployee(employee),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildMapCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFE1ECFC)),
        boxShadow: [q
          BoxShadow(
            color: blue.withOpacity(0.07),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFDCEBFF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.map_rounded,
                  color: blue,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Team Locations',
                      style: TextStyle(
                        color: textBlue,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Employee location overview',
                      style: TextStyle(
                        color: Color(0xFF8195B8),
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.fullscreen_rounded,
                  color: blue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            height: 235,
            width: double.infinity,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF2FD),
              borderRadius: BorderRadius.circular(19),
              border: Border.all(color: const Color(0xFFDCE8FA)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _MapPatternPainter(),
                  ),
                ),
                Center(
                  child: Container(
                    margin: const EdgeInsets.all(22),
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.93),
                      borderRadius: BorderRadius.circular(22),
                      boxShadow: [
                        BoxShadow(
                          color: blue.withOpacity(0.1),
                          blurRadius: 22,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.location_on_rounded,
                          color: blue,
                          size: 39,
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Map preview',
                          style: TextStyle(
                            color: textBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 5),
                        Text(
                          'Google Maps will be connected later',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF8195B8),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: 12,
                  child: Container(
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.add_rounded,
                      color: blue,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: blue,
                size: 17,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _selectedEmployee == null
                      ? 'Select an employee to view their location when available.'
                      : 'Selected: ${_selectedEmployee!['emp_name']}. GPS location will be connected later.',
                  style: const TextStyle(
                    color: Color(0xFF5877A9),
                    fontSize: 11,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmployeeSection() {
    final employee = _selectedEmployee;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Employee Details',
                style: TextStyle(
                  color: textBlue,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (employee != null)
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedEmployee = null;
                    _searchController.clear();
                    _searchQuery = '';
                  });
                },
                child: const Text(
                  'Clear',
                  style: TextStyle(color: blue),
                ),
              ),
          ],
        ),
        const SizedBox(height: 13),
        if (employee == null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 20,
              vertical: 27,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: const Color(0xFFE1ECFC)),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.person_search_rounded,
                  size: 43,
                  color: Color(0xFF9AB9E9),
                ),
                SizedBox(height: 10),
                Text(
                  'No employee selected',
                  style: TextStyle(
                    color: textBlue,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Search and select an employee above.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Color(0xFF8195B8),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          )
        else
          _buildSelectedEmployeeCard(employee),
      ],
    );
  }

  Widget _buildSelectedEmployeeCard(
    Map<String, dynamic> employee,
  ) {
    final name = employee['emp_name'].toString();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0xFFDCE8FA)),
        boxShadow: [
          BoxShadow(
            color: blue.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                height: 61,
                width: 61,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(19),
                  gradient: const LinearGradient(
                    colors: [cyan, blue],
                  ),
                ),
                child: Center(
                  child: Text(
                    initial,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 27,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: const TextStyle(
                        color: textBlue,
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      employee['designation'].toString(),
                      style: const TextStyle(
                        color: Color(0xFF5877A9),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.verified_user_rounded,
                color: blue,
                size: 24,
              ),
            ],
          ),
          const SizedBox(height: 19),
          const Divider(color: Color(0xFFEAF0FA)),
          const SizedBox(height: 12),
          _detailRow(
            Icons.badge_outlined,
            'Employee ID',
            employee['emp_id'].toString(),
          ),
          const SizedBox(height: 15),
          _detailRow(
            Icons.work_outline_rounded,
            'Designation',
            employee['designation'].toString(),
          ),
          const SizedBox(height: 15),
          _detailRow(
            Icons.email_outlined,
            'Office Email',
            employee['email_office'].toString(),
          ),
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: background,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Row(
              children: [
                Icon(
                  Icons.location_searching_rounded,
                  color: blue,
                  size: 19,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'GPS coordinates not connected yet',
                    style: TextStyle(
                      color: textBlue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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

  Widget _detailRow(
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: blue, size: 20),
        const SizedBox(width: 11),
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF8195B8),
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: const TextStyle(
              color: textBlue,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MapPatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final roadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 10
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final thinRoadPaint = Paint()
      ..color = const Color(0xFFD5E4F7)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final parkPaint = Paint()
      ..color = const Color(0xFFD8F0E5)
      ..style = PaintingStyle.fill;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.05,
          size.height * 0.08,
          size.width * 0.24,
          size.height * 0.19,
        ),
        const Radius.circular(12),
      ),
      parkPaint,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          size.width * 0.70,
          size.height * 0.68,
          size.width * 0.23,
          size.height * 0.20,
        ),
        const Radius.circular(12),
      ),
      parkPaint,
    );

    final paths = <Path>[
      Path()
        ..moveTo(-10, size.height * 0.34)
        ..lineTo(size.width * 0.38, size.height * 0.43)
        ..lineTo(size.width * 0.62, size.height * 0.20)
        ..lineTo(size.width + 10, size.height * 0.29),
      Path()
        ..moveTo(size.width * 0.10, -10)
        ..lineTo(size.width * 0.30, size.height * 0.45)
        ..lineTo(size.width * 0.20, size.height + 10),
      Path()
        ..moveTo(size.width * 0.83, -10)
        ..lineTo(size.width * 0.63, size.height * 0.48)
        ..lineTo(size.width * 0.91, size.height + 10),
      Path()
        ..moveTo(-10, size.height * 0.80)
        ..lineTo(size.width * 0.45, size.height * 0.65)
        ..lineTo(size.width + 10, size.height * 0.89),
    ];

    for (final path in paths) {
      canvas.drawPath(path, roadPaint);
      canvas.drawPath(path, thinRoadPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
