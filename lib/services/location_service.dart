import 'dart:html' as html;

class LocationService {
  Future<bool> checkLocationPermission() async {
    // For web, we check if geolocation is available
    return html.window.navigator.geolocation != null;
  }

  Future<bool> requestLocationPermission() async {
    try {
      // Request position from browser - this shows Chrome's native location permission popup
      await html.window.navigator.geolocation.getCurrentPosition();
      return true;
    } catch (e) {
      print('Location permission denied: $e');
      return false;
    }
  }
}
