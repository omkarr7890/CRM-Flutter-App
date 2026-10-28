import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../Profile/profile_page.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with SingleTickerProviderStateMixin {
  final TextEditingController _usernameController = TextEditingController();

  final TextEditingController _passwordController = TextEditingController();

  bool _isLoading = false;

  final _formKey = GlobalKey<FormState>();

  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  bool _obscurePassword = true;
  bool _rememberMe = true;
  bool _isLoginPressed = false;

  static const Color blue = Color(0xFF0755D9);
  static const Color cyan = Color(0xFF43C8F5);
  static const Color background = Color(0xFFF1F7FF);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fade = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeIn,
    );

    _slide = Tween<Offset>(
      begin: const Offset(0, 0.12),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Replace this with your actual login API URL.

      const String apiUrl =
          'https://salasarcrm.aonesalasar.com/api/mobile/login';

      final requestBody = {
        'Username': _usernameController.text.trim(),
        'Password': _passwordController.text,
      };

      debugPrint('Sending login request...');

      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Accept': 'application/json',
        },
        body: requestBody,
      );

      debugPrint('Login status: ${response.statusCode}');
      debugPrint('Login response: ${response.body}');

      if (!mounted) return;

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final dynamic decoded = jsonDecode(response.body);

        if (decoded is! Map<String, dynamic>) {
          throw const FormatException('Invalid response from server.');
        }

        final bool success = decoded['status'] == 'success';

        if (success) {
          final Map<String, dynamic> data =
          Map<String, dynamic>.from(decoded['data']);

          debugPrint('Login response fields: ${data.keys.toList()}');

          final String empName =
          (data['emp_name'] ?? '').toString();

          final String empId =
          (data['emp_id'] ?? '').toString().trim();

          final String username = _usernameController.text.trim();
          final String password = _passwordController.text;

          if (empId.isEmpty) {
            throw Exception(
              'Employee ID missing from login response. '
                  'Available fields: ${data.keys.join(', ')}',
            );
          }

          final prefs = await SharedPreferences.getInstance();

          // Save the employee information
          await prefs.setString('empName', empName);
          await prefs.setString('emp_id', empId);
          await prefs.setString('username', username);

          // Existing Punch API requires Password.
          // For production, store credentials securely instead.
          await prefs.setString('password', password);

          // Mark login successful only after the required data is saved.
          await prefs.setBool('isLoggedIn', true);

          debugPrint('========== LOGIN STORAGE ==========');
          debugPrint('Username saved: ${prefs.containsKey('username')}');
          debugPrint('Password saved: ${prefs.containsKey('password')}');
          debugPrint('Employee ID saved: ${prefs.containsKey('emp_id')}');
          debugPrint('===================================');

          if (!mounted) return;

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => ProfilePage(empName: empName),
            ),
          );
        }else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                (decoded['message'] ?? 'Login failed.').toString(),
              ),
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Server error: ${response.statusCode}',
            ),
          ),
        );
      }
    } on SocketException catch (e) {
      debugPrint('Network/DNS error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Cannot connect to the server. Check your internet or API URL.',
          ),
        ),
      );
    } on http.ClientException catch (e) {
      debugPrint('HTTP connection error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Connection failed. Please try again.'),
        ),
      );
    } on FormatException catch (e) {
      debugPrint('Invalid API response: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invalid response received from the server.'),
        ),
      );
    } catch (e) {
      debugPrint('Login error: $e');

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Login failed: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  InputDecoration _decoration({
    required String label,
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Container(
        margin: const EdgeInsets.all(9),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFDCEBFF),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(icon, color: blue),
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FBFF),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 10,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: Color(0xFFD5E5FF)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(
          color: Color(0xFFD5E5FF),
          width: 1.5,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(20),
        borderSide: const BorderSide(color: blue, width: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: Stack(
        children: [
          // Background gradient
          Container(
            height: 300,
            decoration: const BoxDecoration(
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(90),
                bottomRight: Radius.circular(90),
              ),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF0739A8),
                  Color(0xFF126BE8),
                  Color(0xFF59CFFF),
                ],
              ),
            ),
          ),

          Positioned(
            top: 60,
            right: -45,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.12),
              ),
            ),
          ),

          Positioned(
            top: 230,
            left: -55,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: cyan.withOpacity(0.18),
              ),
            ),
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 2),
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: SingleChildScrollView(
                    keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // App branding
                        Transform.translate(
                          offset: const Offset(20, 25),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.18),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(
                                    Icons.auto_awesome_rounded,
                                    size: 30,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'CRM',
                                      style: TextStyle(
                                        fontSize: 23,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Smarter solutions for you',
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Welcome header
                        Row(
                          children: [
                            const SizedBox(width: 8),
                            Expanded(
                              child: SizedBox(
                                height: 90, // Reduced from 160
                                child: Stack(
                                  alignment: Alignment.bottomRight,
                                  children: [
                                    Container(
                                      width: 80,
                                      height: 80,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: Colors.white.withOpacity(0.15),
                                      ),
                                    ),
                                    Container(
                                      width: 60,
                                      height: 70,
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(20),
                                        gradient: const LinearGradient(
                                          colors: [
                                            Color(0xFF71DBFF),
                                            Color(0xFF0755D9),
                                          ],
                                        ),
                                      ),
                                      child: const Icon(
                                        Icons.lock_person_rounded,
                                        size: 40,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const Positioned(
                                      right: 0,
                                      bottom: 0,
                                      child: CircleAvatar(
                                        radius: 17,
                                        backgroundColor: Colors.white,
                                        child: Icon(
                                          Icons.verified_user_rounded,
                                          color: blue,
                                          size: 22,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 8),

                        // Login card
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.97),
                            borderRadius: BorderRadius.circular(30),
                            border: Border.all(color: Colors.white, width: 2),
                            boxShadow: [
                              BoxShadow(
                                color: blue.withOpacity(0.12),
                                blurRadius: 30,
                                offset: const Offset(0, 12),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              Transform.translate(
                                offset: const Offset(0, -20),
                                child: Container(
                                  width: 56,
                                  height: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: const LinearGradient(
                                      colors: [cyan, blue],
                                    ),
                                    border: Border.all(
                                      color: Colors.white,
                                      width: 3,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: blue.withOpacity(0.2),
                                        blurRadius: 15,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: Colors.white,
                                    size: 28,
                                  ),
                                ),
                              ),
                              Transform.translate(
                                offset: const Offset(0, -12),
                                child: Form(
                                  key: _formKey,
                                  child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.stretch,
                                    children: [
                                      const Text(
                                        'Login',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 25,
                                          fontWeight: FontWeight.bold,


                                          color: Color(0xFF163B80),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      const Text(
                                        'Enter your details to get started',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          color: Color(0xFF8195B8),
                                          fontSize: 13,
                                        ),
                                      ),
                                      const SizedBox(height: 25),

                                      TextFormField(
                                        controller: _usernameController,
                                        keyboardType: TextInputType.text,
                                        decoration: _decoration(
                                          label: 'Username',
                                          hint: 'Enter your username',
                                          icon: Icons.person_outline,
                                        ),
                                        validator: (value) {
                                          if (value == null ||
                                              value.trim().isEmpty) {
                                            return 'Please enter your username';
                                          }
                                          return null;
                                        },
                                      ),
                                      const SizedBox(height: 18),

                                      TextFormField(
                                        controller: _passwordController,
                                        obscureText: _obscurePassword,
                                        textInputAction: TextInputAction.done,
                                        onFieldSubmitted: (_) => _login(),
                                        decoration: _decoration(
                                          label: 'Password',
                                          hint: 'Enter your password',
                                          icon: Icons.lock_rounded,
                                          suffix: IconButton(
                                            onPressed: () {
                                              setState(() {
                                                _obscurePassword =
                                                !_obscurePassword;
                                              });
                                            },
                                            icon: Icon(
                                              _obscurePassword
                                                  ? Icons.visibility_off_rounded
                                                  : Icons.visibility_rounded,
                                              color: const Color(0xFF7890B8),
                                            ),
                                          ),
                                        ),
                                        validator: (value) {
                                          if (value == null || value.isEmpty) {
                                            return 'Please enter your password';
                                          }
                                          if (value.length < 6) {
                                            return 'Minimum 6 characters required';
                                          }
                                          return null;
                                        },
                                      ),

                                      const SizedBox(height: 10),

                                      Row(
                                        children: [
                                          SizedBox(
                                            width: 30,
                                            height: 40,
                                            child: Checkbox(
                                              value: _rememberMe,
                                              activeColor: blue,
                                              onChanged: (value) {
                                                setState(() {
                                                  _rememberMe = value ?? false;
                                                });
                                              },
                                            ),
                                          ),
                                          const SizedBox(width: 5),
                                          const Flexible(
                                            child: Text(
                                              'Remember me',
                                              style: TextStyle(
                                                fontSize: 9,
                                                color: Color(0xFF163B80),
                                              ),
                                            ),
                                          ),
                                          const Spacer(),
                                          TextButton(
                                            onPressed: () {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                const SnackBar(
                                                  content: Text(
                                                    'Connect password recovery here.',
                                                  ),
                                                ),
                                              );
                                            },
                                            child: const Text(
                                              'Forgot Password?',
                                              style: TextStyle(
                                                color: blue,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),

                                      const SizedBox(height: 8),

                                      // Gradient login button

// Compact Smooth 3D Login Button
                                      AnimatedContainer(
                                        duration:
                                        const Duration(milliseconds: 150),
                                        curve: Curves.easeOutCubic,
                                        height: 54,
                                        transform: Matrix4.translationValues(
                                          0,
                                          _isLoginPressed ? 3 : 0,
                                          0,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                          BorderRadius.circular(16),
                                          // boxShadow: [
                                          //   BoxShadow(
                                          //     color: const Color(0xFF0739A8).withOpacity(
                                          //       _isLoginPressed ? 0.15 : 0.4,
                                          //     ),
                                          //     blurRadius: _isLoginPressed ? 2 : 0,
                                          //     offset: Offset(0, _isLoginPressed ? 1 : 4),
                                          //   ),
                                          //   BoxShadow(
                                          //     color: blue.withOpacity(0.15),
                                          //     blurRadius: _isLoginPressed ? 3 : 8,
                                          //     offset: Offset(0, _isLoginPressed ? 1 : 5),
                                          //   ),
                                          // ],
                                        ),
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTapDown: (_) {
                                            setState(
                                                    () => _isLoginPressed = true);
                                          },
                                          onTapUp: (_) {
                                            setState(
                                                    () => _isLoginPressed = false);
                                          },
                                          onTapCancel: () {
                                            setState(
                                                    () => _isLoginPressed = false);
                                          },
                                          onTap: _isLoading ? null : _login,
                                          child: AnimatedScale(
                                            scale: _isLoginPressed ? 0.99 : 1.0,
                                            duration: const Duration(
                                                milliseconds: 150),
                                            curve: Curves.easeOutCubic,
                                            child: Container(
                                              height: 50,
                                              decoration: BoxDecoration(
                                                borderRadius:
                                                BorderRadius.circular(16),
                                                gradient: const LinearGradient(
                                                  begin: Alignment.topLeft,
                                                  end: Alignment.bottomRight,
                                                  colors: [
                                                    Color(0xFF70DCFF),
                                                    Color(0xFF2388FF),
                                                    Color(0xFF0755D9),
                                                  ],
                                                ),
                                                border: Border.all(
                                                  color: Colors.white
                                                      .withOpacity(0.4),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Center(
                                                child: _isLoading
                                                    ? const SizedBox(
                                                  width: 22,
                                                  height: 22,
                                                  child:
                                                  CircularProgressIndicator(
                                                    color: Colors.white,
                                                    strokeWidth: 2,
                                                  ),
                                                )
                                                    : const Row(
                                                  mainAxisAlignment:
                                                  MainAxisAlignment
                                                      .center,
                                                  children: [
                                                    Text(
                                                      'LOGIN',
                                                      style: TextStyle(
                                                        color:
                                                        Colors.white,
                                                        fontSize: 15,
                                                        fontWeight:
                                                        FontWeight
                                                            .w800,
                                                        letterSpacing:
                                                        1.8,
                                                      ),
                                                    ),
                                                    SizedBox(width: 10),
                                                    Icon(
                                                      Icons
                                                          .arrow_forward_rounded,
                                                      color: Colors.white,
                                                      size: 20,
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),

                                      const SizedBox(height: 8),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        SizedBox(
                          width: double.infinity,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Wrap(
                                alignment: WrapAlignment.center,
                                crossAxisAlignment: WrapCrossAlignment.center,
                                children: [
                                  const Text(
                                    "Don't have an account?",
                                    style: TextStyle(
                                      color: Color(0xFF5877A9),
                                      fontSize: 13,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {},
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 6),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    ),
                                    child: const Text(
                                      'Sign Up',
                                      style: TextStyle(
                                        color: blue,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 20),
                              const Center(
                                child: Text(
                                  'SECURE LOGIN',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    fontSize: 10,
                                    letterSpacing: 1.5,
                                    color: Color(0xFF91A8CB),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
