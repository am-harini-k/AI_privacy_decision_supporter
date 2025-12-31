import 'package:flutter/material.dart';

void main() {
  runApp(const MyApp());
}

// Global navigator key (optional, still included if needed for navigation)
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'Privacy AI Demo',
      theme: ThemeData(primarySwatch: Colors.deepPurple),
      home: const Screen1Logo(),
    );
  }
}

// -------------------- SCREEN 1 --------------------
class Screen1Logo extends StatelessWidget {
  const Screen1Logo({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.white, Color(0xFFF0F2FF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 50,
                backgroundColor: Colors.deepPurple,
                child: const Icon(Icons.shield, size: 50, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'Privacy AI Demo',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Colors.deepPurple,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Screen2Explain(),
                    ),
                  );
                },
                child: const Text(
                  '✨ Click to continue ✨',
                  style: TextStyle(fontSize: 16, color: Colors.deepPurple),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- SCREEN 2 --------------------
class Screen2Explain extends StatelessWidget {
  const Screen2Explain({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F2FF),
      body: Center(
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(30),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: const [
              BoxShadow(
                blurRadius: 15,
                color: Colors.black12,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: Colors.deepPurple,
                child: const Icon(Icons.shield, size: 30, color: Colors.white),
              ),
              const SizedBox(height: 20),
              const Text(
                'About Privacy AI',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 10),
              const Text(
                'This app helps you analyze other apps\' Terms & Conditions and permissions using AI. Get instant privacy alerts and actionable recommendations to keep your data safe.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.black87),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: const [
                  FeatureWidget(
                    icon: Icons.article,
                    label: 'T&C Analysis',
                    subLabel: 'Analyzes Terms & Conditions automatically',
                  ),
                  FeatureWidget(
                    icon: Icons.lock,
                    label: 'Permission Check',
                    subLabel: 'Reviews app permissions for privacy risks',
                  ),
                  FeatureWidget(
                    icon: Icons.smart_toy,
                    label: 'AI Powered',
                    subLabel: 'Uses advanced AI for accurate insights',
                  ),
                ],
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const Screen3Dummy(),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('OK, Start'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// -------------------- FEATURE WIDGET --------------------
class FeatureWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subLabel;
  const FeatureWidget({
    super.key,
    required this.icon,
    required this.label,
    required this.subLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 25,
          backgroundColor: const Color(0xFFEDE6FF),
          child: Icon(icon, color: Colors.deepPurple),
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 3),
        SizedBox(
          width: 80,
          child: Text(
            subLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
        ),
      ],
    );
  }
}

// -------------------- SCREEN 3 --------------------
class Screen3Dummy extends StatelessWidget {
  const Screen3Dummy({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> apps = [
      {'name': 'ShopEasy', 'type': 'Shopping'},
      {'name': 'GameFun', 'type': 'Gaming'},
      {'name': 'Foodie', 'type': 'Food & Drink'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Select an App to Analyze')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Text(
              'Choose an app to see its privacy analysis',
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 15,
                  mainAxisSpacing: 15,
                ),
                itemCount: apps.length,
                itemBuilder: (context, index) {
                  final app = apps[index];
                  return Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 5,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.deepPurple,
                          child: Icon(
                            app['type'] == 'Gaming'
                                ? Icons.videogame_asset
                                : Icons.shopping_cart,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          app['name']!,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          app['type']!,
                          style: const TextStyle(color: Colors.black54),
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            // Show popup dialog instead of notification
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: Text('Privacy Alert - ${app['name']}'),
                                content: const Text(
                                  'Risk Score: 4.2/10\nPermissions: Storage, Network\nTap OK to view full analysis.',
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context); // Close popup
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              Screen4NotificationDetails(
                                                appName: app['name']!,
                                              ),
                                        ),
                                      );
                                    },
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.deepPurple,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          child: const Text('Explain with AI'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// -------------------- SCREEN 4 --------------------
class Screen4NotificationDetails extends StatelessWidget {
  final String appName;
  const Screen4NotificationDetails({super.key, required this.appName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('$appName Privacy Analysis')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green.shade300,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                children: const [
                  Text(
                    'Privacy Risk Score',
                    style: TextStyle(color: Colors.white70),
                  ),
                  SizedBox(height: 5),
                  Text(
                    '4.2 / 10',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text('Low Risk', style: TextStyle(color: Colors.white70)),
                ],
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Permissions Requested',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: const ListTile(
                leading: Icon(Icons.storage, color: Colors.deepPurple),
                title: Text('Storage'),
              ),
            ),
            Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: const ListTile(
                leading: Icon(Icons.wifi, color: Colors.deepPurple),
                title: Text('Network'),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'AI Recommendation',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 5),
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: Colors.green.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Low risk detected. This app only requests essential permissions for its functionality.',
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: () =>
                    Navigator.popUntil(context, (route) => route.isFirst),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
