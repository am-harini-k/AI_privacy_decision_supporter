import 'dart:async';
import 'dart:html' as html;
import 'dart:js' as js;
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../constants/colors.dart';
import '../api_service.dart'; // ✅ API helper for fetching alerts
import 'shopping_home_screen.dart'; // ✅ Navigate here after successful login

// -----------------------------------------------------------
// Login screen with popup alert logic
// -----------------------------------------------------------
class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // ---------- controllers / focus ----------
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _emailFocusNode = FocusNode();

  // ---------- error state ----------
  String? _errorMessage;

  // ---------- recognizers for inline links ----------
  late final TapGestureRecognizer _conditionsRecognizer;
  late final TapGestureRecognizer _privacyRecognizer;

  // ---------- notifications ----------
  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  // ---------- lifecycle ----------
  @override
  void initState() {
    super.initState();

    // Initialize notifications
    _initializeNotifications();

    // When the screen first shows, try fetching any alert from the server.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkAlert();
    });

    // Initialize recognizers for Conditions of Use / Privacy Notice links.
    _conditionsRecognizer = TapGestureRecognizer()
      ..onTap = _showConditionsOfUse;
    _privacyRecognizer = TapGestureRecognizer()..onTap = _showPrivacyNotice;
  }

  @override
  void dispose() {
    _conditionsRecognizer.dispose();
    _privacyRecognizer.dispose();
    _emailController.dispose();
    _emailFocusNode.dispose();
    super.dispose();
  }

  // -----------------------------------------------------------
  // Initialize notifications
  // -----------------------------------------------------------
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

  // -----------------------------------------------------------
  // Fetch alert from backend and display either popup or banner
  // -----------------------------------------------------------
  void _checkAlert() async {
    try {
      final data = await ApiService.getDummyAlert(style: 'popup');
      if (!mounted) return;

      // Debug print so you can see the raw server response.
      debugPrint('LoginScreen._checkAlert -> data: $data');

      final messenger = ScaffoldMessenger.of(context);

      if (data == null) return;

      // If the server wants existing alerts cleared, do that.
      if (data['clear_existing_alerts'] == true) {
        messenger.clearMaterialBanners();
      }

      final notification = data['notification'];
      if (notification != null && notification is Map<String, dynamic>) {
        // Another flag to remove existing banners.
        if (notification['remove_existing_alerts'] == true) {
          messenger.clearMaterialBanners();
        }

        final style = notification['style'] ?? 'banner';

        if (style == 'popup') {
          // Popup: hide banners/snackbars first to avoid overlap.
          messenger.clearMaterialBanners();
          ScaffoldMessenger.of(context).hideCurrentSnackBar();

          await _showPopupNotification(context, notification);
        } else {
          // Default to banner (top) if not popup
          final position = notification['position'] ?? 'top';
          if (position == 'top') {
            final title = notification['title'] ?? '';
            final subtitle = notification['subtitle'] ?? '';
            final summary = notification['summary'] ?? '';

            messenger.showMaterialBanner(
              MaterialBanner(
                leading: const Icon(
                  Icons.notification_important,
                  color: Colors.white,
                ),
                backgroundColor: Colors.deepPurple,
                content: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((title as String).isNotEmpty)
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    if ((subtitle as String).isNotEmpty)
                      Text(
                        subtitle,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    if ((summary as String).isNotEmpty)
                      Text(
                        summary,
                        style: const TextStyle(color: Colors.white),
                      ),
                  ],
                ),
                actions: [
                  TextButton(
                    onPressed: () => messenger.hideCurrentMaterialBanner(),
                    child: const Text(
                      'DISMISS',
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            );
          }
        }
      }
    } catch (e) {
      debugPrint("Error fetching alert: $e");
    }
  }

  // -----------------------------------------------------------
  // Helper to render the popup dialog instructed by the server
  // -----------------------------------------------------------
  Future<void> _showPopupNotification(
    BuildContext context,
    Map<String, dynamic> n,
  ) async {
    final title = (n['title'] ?? '') as String;
    final subtitle = (n['subtitle'] ?? '') as String;
    final summary = (n['summary'] ?? '') as String;
    final dismissEndpoint = (n['dismiss_endpoint'] ?? '/dummy/ack') as String;

    debugPrint(
        'LoginScreen: Showing system notification - Title: $title, Subtitle: $subtitle');

    // Create detailed notification message
    String detailedMessage = '';

    if (subtitle.isNotEmpty) {
      detailedMessage += '$subtitle\n\n';
    }

    if (summary.isNotEmpty) {
      detailedMessage += '$summary\n\n';
    }

    // Add detailed privacy considerations for login
    detailedMessage += '\n\n⚠️ Privacy Considerations for Login:\n\n';
    detailedMessage += '⚠️ You agree to Amazon rules by using the site\n';
    detailedMessage += '🔐 You are responsible for your account & password\n';
    detailedMessage +=
        '📦 Amazon is a platform, not responsible for seller issues\n';
    detailedMessage += '✍️ Your reviews/content can be reused by Amazon\n\n';

    detailedMessage +=
        '✅ Safe to use \n❗ Be careful with account security & reviews\n\n';

    // For web, use native browser notifications
    if (html.Notification.supported) {
      final permission = html.Notification.permission;
      debugPrint('LoginScreen: Notification permission status: $permission');

      if (permission == 'granted') {
        try {
          // Use JavaScript interop for proper notification creation
          js.context.callMethod('eval', [
            '''
            if ('Notification' in window) {
              var notification = new Notification('${title.replaceAll("'", "\\'")}', {
                body: '${detailedMessage.replaceAll("'", "\\'").replaceAll('\n', '\\n')}',
                icon: '/favicon.ico',
                silent: true,
                tag: 'privacy-alert'
              });
              notification.onclick = function() {
                notification.close();
              };
              // Auto-close after 30 seconds as fallback
            }
          '''
          ]);
          debugPrint(
              'LoginScreen: Native web notification created successfully');
        } catch (e) {
          debugPrint('LoginScreen: Error creating notification: $e');
        }
      } else if (permission == 'default') {
        debugPrint('LoginScreen: Requesting notification permission');
        try {
          final newPermission = await html.Notification.requestPermission();
          debugPrint('LoginScreen: New permission status: $newPermission');
          if (newPermission == 'granted') {
            js.context.callMethod('eval', [
              '''
              if ('Notification' in window) {
                var notification = new Notification('${title.replaceAll("'", "\\'")}', {
                  body: '${detailedMessage.replaceAll("'", "\\'").replaceAll('\n', '\\n')}',
                  icon: '/favicon.ico',
                  silent: true,
                  tag: 'privacy-alert'
                });
                notification.onclick = function() {
                  notification.close();
                };
                // Auto-close after 30 seconds as fallback
              }
            '''
            ]);
            debugPrint(
                'LoginScreen: Native web notification shown after permission');
          }
        } catch (e) {
          debugPrint('LoginScreen: Error requesting permission: $e');
        }
      } else {
        debugPrint('LoginScreen: Notification permission denied');
      }
    } else {
      // Fallback to flutter_local_notifications for mobile/desktop
      const AndroidNotificationDetails androidNotificationDetails =
          AndroidNotificationDetails(
        'alert_channel',
        'Alerts',
        channelDescription: 'Alert notifications',
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'ticker',
        visibility: NotificationVisibility.public,
        fullScreenIntent: true,
      );

      const NotificationDetails notificationDetails =
          NotificationDetails(android: androidNotificationDetails);

      await flutterLocalNotificationsPlugin.show(
        0,
        title,
        detailedMessage,
        notificationDetails,
        payload: 'alert_payload',
      );
      debugPrint('LoginScreen: Flutter notification shown');
    }

    // Optionally ack the notification
    try {
      await ApiService.ackNotification(
        endpoint: dismissEndpoint,
        payload: {'source': 'login', 'action': 'shown'},
      );
    } catch (e) {
      debugPrint('Ack failed: $e');
    }
  }

  // -----------------------------------------------------------
  // Validation helpers
  // -----------------------------------------------------------
  bool _isValidEmail(String email) {
    email = email.trim();

    final emailRegex = RegExp(
      r'^[a-zA-Z0-9.!#$%&*+/=?^_{|}~-]+@[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?'
      r'(?:\.[a-zA-Z0-9](?:[a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$',
    );

    final phoneRegex = RegExp(r'^[0-9]{10,12}$');

    return emailRegex.hasMatch(email) || phoneRegex.hasMatch(email);
  }

  // -----------------------------------------------------------
  // Continue / login button
  // -----------------------------------------------------------
  void _continue() {
    final input = _emailController.text.trim();

    setState(() {
      _errorMessage = null;
    });

    if (input.isEmpty) {
      setState(() {
        _errorMessage = 'Enter your email or mobile phone number';
      });
      _emailFocusNode.requestFocus();
      return;
    }

    if (!_isValidEmail(input)) {
      setState(() {
        _errorMessage =
            'Wrong or Invalid email address or mobile phone number. Please correct and try again.';
      });
      _emailFocusNode.requestFocus();
      return;
    }

    // If validation passes, navigate to ShoppingHomeScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const ShoppingHomeScreen()),
    );
  }

  // -----------------------------------------------------------
  // Navigation helpers for Conditions / Privacy / Help
  // -----------------------------------------------------------
  void _showConditionsOfUse() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentPage(
          title: 'Conditions of Use',
          content: _getConditionsOfUseText(),
        ),
      ),
    );
  }

  void _showPrivacyNotice() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DocumentPage(
          title: 'Privacy Notice',
          content: _getPrivacyNoticeText(),
        ),
      ),
    );
  }

  void _showHelp() {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Opening Help...')));
  }

  void _createBusinessAccount() {
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Creating business account...')));
  }

  // -----------------------------------------------------------
  // Large string for Conditions of Use text
  // -----------------------------------------------------------
  String _getConditionsOfUseText() {
    return '''Disclaimer: In the event of any discrepancy or conflict, the English version will prevail over the translation.
Last updated: Aug 25, 2025.

The website www.amazon.in ("Amazon.in") is operated by Amazon Seller Services Private Limited ("Amazon" or "us" or "we" or "our"), having its registered office located 8th Floor, Brigade Gateway 26/1 Dr. Rajkumar Road Bangalore - 560055, Karnataka, India.

Please read the Conditions of Use document carefully before using the Amazon.in website. By using the Amazon.in website, you signify your agreement to be bound by Amazon's Conditions of Use.

PRIVACY
Please review our Privacy Notice, which also governs your visit to Amazon.in, to understand your practices. The personal information/data provided to us by you during the course of usage of Amazon.in will be treated as strictly confidential and in accordance with the Privacy Notice and applicable laws and regulations.

YOUR ACCOUNT
If you use the website, you are responsible for maintaining the confidentiality of your account and password and for restricting access to your computer to prevent unauthorised access to your account. You agree to accept responsibility for all activities that occur under your account or password.

You should take all necessary steps to ensure that the password is kept confidential and secure and should inform us immediately if you have any reason to believe that your password has become known to anyone else, or if the password is being, or is likely to be, used in an unauthorised manner.

E-PLATFORM FOR COMMUNICATION
You agree, understand and acknowledge that the website is an online platform that enables you to purchase products listed on the website at the price indicated therein at any time from any location. You further agree and acknowledge that Amazon is only a facilitator and is not and cannot be a party to or control in any manner any transactions on the website.

ACCESS TO AMAZON.IN
We will do our utmost to ensure that availability of the website will be uninterrupted and that transmissions will be error-free. However, due to the nature of the Internet, this cannot be guaranteed. Also, your access to the website may also be occasionally suspended or restricted to allow for repairs, maintenance, or the introduction of new facilities or services at any time without prior notice.

YOUR CONDUCT
You must not use the website in any way that causes, or is likely to cause, the website or access to it to be interrupted, damaged or impaired in any way. You understand that, and not Amazon.in, are responsible for all electronic communications and content sent from your computer to us and you must use the website for lawful purposes only.

You must not use the website for fraudulent purposes, or in connection with a criminal offense or other unlawful activity, to send, use or reuse any material that does not belong to you; or is illegal, offensive, deceptive, misleading, abusive, indecent, harassing, blasphemous, defamatory, obscene, pornographic, pedophilic or menacing.

REVIEWS, COMMENTS, COMMUNICATIONS AND OTHER CONTENT
Users of this website can post reviews, comments and other content; send communications; and submit suggestions, ideas, comments, questions, or other information, as long as the content is not illegal, offensive, or otherwise unlawful. If you do post content or submit material, you grant Amazon Seller Services Private Limited and its affiliates the rights to use that content as stated in the original doc.

COPYRIGHT AND DATABASE RIGHTS
All content included on the website is protected by law. It belongs to Amazon Seller Services or its suppliers.

TRADEMARKS
AMAZON.IN, AMAZON, THE AMAZON LOGO, and other marks are trademarks or registered trademarks of Amazon.com, Inc. or its subsidiaries.

DISCLAIMER
You acknowledge you are accessing services at your own risk. Amazon disclaims certain responsibilities as stated earlier in this document.

INDEMNITY AND RELEASE
You shall indemnify and hold harmless Amazon parties for claims related to your breach of these Conditions of Use.

CHILDREN
Use of Amazon.in is available only to persons who can form a legally binding contract. Minors may only use it with involvement of a parent or guardian.

GOVERNING LAW AND JURISDICTION
These conditions are governed by the laws of India, with exclusive jurisdiction in Delhi courts.

OUR DETAILS
Operated by Amazon Seller Services Private Limited.

© 1996-2026, Amazon.com, Inc. or its affiliates''';
  }

  // -----------------------------------------------------------
  // Large string for Privacy Notice text
  // -----------------------------------------------------------
  String _getPrivacyNoticeText() {
    return '''Amazon.in Privacy Notice

Disclaimer: In the event of any discrepancy or conflict, the English version will prevail over the translation.
Last updated: November 18, 2025.

We know that you care how information about you is used and shared, and we appreciate your trust that we will do so carefully and sensibly. This Privacy Notice describes how Amazon Seller Services Private Limited and its affiliates collect and process your personal information through Amazon services.

By using Amazon Services you agree to our use of personal information as described here.

WHAT PERSONAL INFORMATION ABOUT CUSTOMERS DOES AMAZON COLLECT?
We collect personal information to provide and improve services...

[Text continues exactly as previously pasted in your version; keep the full block here.]

© 1996-2026, Amazon.com, Inc. or its affiliates''';
  }

  // -----------------------------------------------------------  // Build UI
  // -----------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Amazon Header
              Container(
                width: double.infinity,
                color: AmazonColors.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        'amazon',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1,
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.only(left: 2, top: 8),
                        child: const Text(
                          '.in',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 30),
              // Login Form
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Sign in or create account',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w400,
                        color: AmazonColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Enter mobile number or email',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AmazonColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _emailController,
                      focusNode: _emailFocusNode,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: _errorMessage != null
                                ? Colors.red
                                : const Color(0xFF888C8C),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: _errorMessage != null
                                ? Colors.red
                                : const Color(0xFF888C8C),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(4),
                          borderSide: BorderSide(
                            color: _errorMessage != null
                                ? Colors.red
                                : const Color(0xFFE77600),
                            width: 2,
                          ),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                      onChanged: (value) {
                        if (_errorMessage != null) {
                          setState(() {
                            _errorMessage = null;
                          });
                        }
                      },
                      onSubmitted: (value) {
                        _continue();
                      },
                    ),
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline,
                            color: Colors.red,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.red,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 45,
                      child: ElevatedButton(
                        onPressed: _continue,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFFFD814),
                          foregroundColor: Colors.black,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                            side: const BorderSide(color: Color(0xFFFCD200)),
                          ),
                        ),
                        child: const Text(
                          'Continue',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    RichText(
                      text: TextSpan(
                        style: const TextStyle(
                          fontSize: 12,
                          color: AmazonColors.textDark,
                        ),
                        children: [
                          const TextSpan(
                            text: 'By continuing, you agree to Amazon\'s ',
                          ),
                          TextSpan(
                            text: 'Conditions of Use',
                            style: const TextStyle(
                              color: AmazonColors.textBlue,
                              decoration: TextDecoration.none,
                            ),
                            recognizer: _conditionsRecognizer,
                          ),
                          const TextSpan(text: ' and '),
                          TextSpan(
                            text: 'Privacy Notice',
                            style: const TextStyle(
                              color: AmazonColors.textBlue,
                              decoration: TextDecoration.none,
                            ),
                            recognizer: _privacyRecognizer,
                          ),
                          const TextSpan(text: '.'),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    const Divider(color: Color(0xFFDDD)),
                    const SizedBox(height: 15),
                    const Text(
                      'Buying for work?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: AmazonColors.textDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _createBusinessAccount,
                      child: const Text(
                        'Create a free business account',
                        style: TextStyle(
                          fontSize: 13,
                          color: AmazonColors.textBlue,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              // Footer links
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Colors.grey.shade300)),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: _showConditionsOfUse,
                          child: const Text(
                            'Conditions of Use',
                            style: TextStyle(
                              fontSize: 12,
                              color: AmazonColors.textBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: _showPrivacyNotice,
                          child: const Text(
                            'Privacy Notice',
                            style: TextStyle(
                              fontSize: 12,
                              color: AmazonColors.textBlue,
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        GestureDetector(
                          onTap: _showHelp,
                          child: const Text(
                            'Help',
                            style: TextStyle(
                              fontSize: 12,
                              color: AmazonColors.textBlue,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '© 1996-2026, Amazon.com, Inc. or its affiliates',
                      style: TextStyle(fontSize: 11, color: AmazonColors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -----------------------------------------------------------
// Full-page document viewer (top-level) used by Conditions / Privacy
// -----------------------------------------------------------
class DocumentPage extends StatelessWidget {
  final String title;
  final String content;

  const DocumentPage({
    Key? key,
    required this.title,
    required this.content,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AmazonColors.primaryDark,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SingleChildScrollView(
            child: SelectableText(
              content,
              style: const TextStyle(fontSize: 14, height: 1.4),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
          child: SizedBox(
            height: 44,
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AmazonColors.primaryDark,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ),
        ),
      ),
    );
  }
}
