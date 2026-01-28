import 'dart:async';
import 'dart:convert';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import '../constants/colors.dart';
import '../widgets/location_permission_dialog.dart';
import '../services/location_service.dart';
import '../api_service.dart';
import 'login_screen.dart';

class ShoppingHomeScreen extends StatefulWidget {
  const ShoppingHomeScreen({Key? key}) : super(key: key);

  @override
  State<ShoppingHomeScreen> createState() => _ShoppingHomeScreenState();
}

class _ShoppingHomeScreenState extends State<ShoppingHomeScreen> {
  // ──────────────────── SERVICES & STATE ────────────────────
  final LocationService _locationService = LocationService();

  bool _locationEnabled = false;
  bool _hasAskedForLocation = false;

  // ──────────────────── NOTIFICATIONS ────────────────────
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ──────────────────── LIFECYCLE ────────────────────
  @override
  void initState() {
    super.initState();

    _initializeNotifications();
    _checkForAlert();

    Future.delayed(const Duration(milliseconds: 800), () {
      if (!_hasAskedForLocation && !_locationEnabled && mounted) {
        _showLocationDialog();
        _hasAskedForLocation = true;
      }
    });
  }

  // ──────────────────── NOTIFICATION METHODS ────────────────────
  Future<void> _initializeNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings();

    const LinuxInitializationSettings initializationSettingsLinux =
        LinuxInitializationSettings(defaultActionName: 'Open notification');

    const InitializationSettings initializationSettings =
        InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
      linux: initializationSettingsLinux,
    );

    await flutterLocalNotificationsPlugin.initialize(initializationSettings);
  }

  Future<void> _checkForAlert() async {
    print('ShoppingHomeScreen: Checking for alert...');
    final response =
        await http.get(Uri.parse('${ApiService.base}/dummy/shopping_alert'));
    print('ShoppingHomeScreen: Response status: ${response.statusCode}');
    print('ShoppingHomeScreen: Response body: ${response.body}');
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      final alert = data['alert'];
      print('ShoppingHomeScreen: Alert data: $alert');
      if (alert != null && mounted) {
        _showSystemPopupNotification(alert);
      }
    }
  }

  Future<void> _showSystemPopupNotification(Map<String, dynamic> alert) async {
    print('ShoppingHomeScreen: Showing system notification - Alert: $alert');

    final title = alert['title'] ?? '🛒 Shopping Privacy Alert';
    final message =
        alert['message'] ?? 'Privacy check required for shopping activities.';
    final style = alert['style'] ?? 'system_popup';

    // Create detailed shopping notification message
    String detailedMessage = '$message\n\n';

    // Add shopping-specific privacy details

    detailedMessage += '📍 Location Permission\n';
    detailedMessage += '✅ Allow → Better delivery & services\n';
    detailedMessage +=
        '❌ Deny → More privacy, fewer features only you can access\n\n';

    // For web, use native browser notifications
    if (html.Notification.supported) {
      final permission = html.Notification.permission;
      print('ShoppingHomeScreen: Notification permission status: $permission');

      if (permission == 'granted') {
        try {
          js.context.callMethod('eval', [
            '''
            if ('Notification' in window) {
              var notification = new Notification('${title.replaceAll("'", "\\'")}', {
                body: '${detailedMessage.replaceAll("'", "\\'").replaceAll('\n', '\\n')}',
                icon: '/favicon.ico',
                silent: true,
                tag: 'shopping-alert'
              });
              notification.onclick = function() {
                notification.close();
              };
              // Auto-close after 30 seconds as fallback
            }
          '''
          ]);
          print(
              'ShoppingHomeScreen: Native web notification created successfully');
        } catch (e) {
          print('ShoppingHomeScreen: Error creating notification: $e');
        }
      } else if (permission == 'default') {
        print('ShoppingHomeScreen: Requesting notification permission');
        try {
          final newPermission = await html.Notification.requestPermission();
          print('ShoppingHomeScreen: New permission status: $newPermission');
          if (newPermission == 'granted') {
            js.context.callMethod('eval', [
              '''
              if ('Notification' in window) {
                var notification = new Notification('${title.replaceAll("'", "\\'")}', {
                  body: '${detailedMessage.replaceAll("'", "\\'").replaceAll('\n', '\\n')}',
                  icon: '/favicon.ico',
                  silent: true,
                  tag: 'shopping-alert'
                });
                notification.onclick = function() {
                  notification.close();
                };
                // Auto-close after 30 seconds as fallback
                setTimeout(function() {
                  if (notification) {
                    notification.close();
                  }
                }, 30000);
              }
            '''
            ]);
            print(
                'ShoppingHomeScreen: Native web notification shown after permission');
          }
        } catch (e) {
          print('ShoppingHomeScreen: Error requesting permission: $e');
        }
      } else {
        print('ShoppingHomeScreen: Notification permission denied');
      }
    } else {
      // Fallback to flutter_local_notifications for mobile/desktop
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'shopping_alert_channel',
        'Shopping Alerts',
        channelDescription: 'Shopping privacy alerts',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        visibility: NotificationVisibility.public,
        fullScreenIntent: true,
      );

      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidNotificationDetails);

      await flutterLocalNotificationsPlugin.show(
        1,
        title,
        detailedMessage,
        notificationDetails,
        payload: 'shopping_alert_payload',
      );
      print('ShoppingHomeScreen: Flutter notification shown');
    }
  }

  // ──────────────────── LOGIC METHODS ────────────────────
  void _showLocationDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return LocationPermissionDialog(
          onOk: () async {
            Navigator.of(context).pop();
            final granted = await _locationService.requestLocationPermission();

            setState(() {
              _locationEnabled = granted;
            });

            if (granted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Location access enabled'),
                  backgroundColor: Colors.green,
                  duration: Duration(seconds: 2),
                ),
              );
            }
          },
          onCancel: () {
            Navigator.of(context).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Location access denied'),
                duration: Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          title: const Text(
            'Sign Out',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          content: const Text(
            'Are you sure you want to sign out?',
            style: TextStyle(fontSize: 14),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'CANCEL',
                style: TextStyle(
                  color: AmazonColors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => const LoginScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AmazonColors.primaryOrange,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'SIGN OUT',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );
  }

  // ──────────────────── UI ────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AmazonColors.background,
      appBar: _buildAppBar(),
      body: _buildBody(),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ──────────────────── APP BAR ────────────────────
  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: AmazonColors.primaryDark,
      elevation: 0,
      automaticallyImplyLeading: false,
      title: _buildSearchBar(),
      actions: [
        IconButton(
          icon: const Icon(Icons.mic, color: Colors.white),
          onPressed: () {},
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            if (value == 'logout') {
              _logout();
            }
          },
          itemBuilder: (_) => [
            PopupMenuItem<String>(
              value: 'logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 20),
                  SizedBox(width: 12),
                  Text('Sign Out'),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 40,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.search, color: Colors.grey),
          ),
          Expanded(
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Search Amazon.in',
                hintStyle: TextStyle(color: Colors.grey[600], fontSize: 16),
                border: InputBorder.none,
              ),
            ),
          ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: Icon(Icons.qr_code_scanner, color: Colors.grey),
          ),
        ],
      ),
    );
  }

  // ──────────────────── BODY ────────────────────
  Widget _buildBody() {
    return Column(
      children: [
        _buildLocationBar(),
        Expanded(child: _buildMainList()),
      ],
    );
  }

  Widget _buildLocationBar() {
    return Container(
      width: double.infinity,
      color: const Color(0xFF37475A),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const Icon(Icons.location_on, color: Colors.white, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _locationEnabled
                  ? 'Deliver to Chennai 600001'
                  : 'Select your location',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const Icon(Icons.arrow_drop_down, color: Colors.white),
        ],
      ),
    );
  }

  Widget _buildMainList() {
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        _buildBanner(),
        _buildCategories(),
        _buildDeals(),
        _buildTopPicks(),
      ],
    );
  }

  // ──────────────────── SECTIONS ────────────────────
  Widget _buildBanner() {
    return Container(
      height: 200,
      margin: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        gradient: const LinearGradient(
          colors: [Color(0xFF00A8E1), Color(0xFF006994)],
        ),
      ),
      child: const Padding(
        padding: EdgeInsets.all(20),
        child: Text(
          'Great Indian Festival',
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
      ),
    );
  }

  Widget _buildCategories() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: GridView.count(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        crossAxisCount: 2,
        childAspectRatio: 1.1,
        children: [
          _buildCategoryCard(
              'Mobiles & Accessories',
              'https://images.unsplash.com/photo-1511707171634-5f897ff02aa9?w=400',
              'Up to 40% off'),
          _buildCategoryCard(
              'Fashion',
              'https://images.unsplash.com/photo-1445205170230-053b83016050?w=400',
              'Min 50% off'),
        ],
      ),
    );
  }

  Widget _buildDeals() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: const Text(
        'Deals of the Day',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildTopPicks() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: const Text(
        'Top picks for you',
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }

  // ──────────────────── REUSABLE WIDGETS ────────────────────
  Widget _buildCategoryCard(String title, String imageUrl, String discount) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Image.network(imageUrl, height: 100, fit: BoxFit.cover),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(title),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      selectedItemColor: AmazonColors.primaryOrange,
      unselectedItemColor: AmazonColors.grey,
      items: [
        BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
        BottomNavigationBarItem(icon: Icon(Icons.person), label: 'You'),
        BottomNavigationBarItem(icon: Icon(Icons.shopping_cart), label: 'Cart'),
        BottomNavigationBarItem(icon: Icon(Icons.menu), label: 'Menu'),
      ],
    );
  }
}
