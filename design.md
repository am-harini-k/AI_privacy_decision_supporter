# Design Document: Consent Dialog Analyzer

## Overview

The Consent Dialog Analyzer is a Flutter/Dart mobile application that helps users understand consent dialogs, privacy notices, and permission requests by providing real-time, simplified explanations. The application leverages platform accessibility services to extract visible text from consent dialogs, processes it using on-device natural language processing, and delivers non-intrusive notifications with analysis results.

The design prioritizes privacy by ensuring all processing occurs on-device with no data storage or transmission. The architecture is modular, separating concerns between text extraction, NLP processing, notification delivery, and user interface management.

**Key Design Principles:**
- Privacy-first: No data leaves the device
- User control: Explicit opt-in with clear status indicators
- Performance: Efficient resource usage with minimal battery impact
- Accuracy: High-precision consent dialog detection to minimize false positives
- Modularity: Clean separation between platform-specific and cross-platform code

## Architecture

The application follows a layered architecture with clear separation of concerns:

```
┌─────────────────────────────────────────────────────────┐
│                    User Interface Layer                  │
│  (Flutter Widgets: Settings, Status, Notifications UI)   │
└─────────────────────────────────────────────────────────┘
                            │
┌─────────────────────────────────────────────────────────┐
│                   Application Layer                      │
│     (Business Logic: Orchestration, State Management)    │
└─────────────────────────────────────────────────────────┘
                            │
        ┌───────────────────┼───────────────────┐
        │                   │                   │
┌───────▼────────┐  ┌──────▼──────┐  ┌────────▼─────────┐
│ Text Extractor │  │NLP Processor│  │Notification Mgr  │
│    Service     │  │   Service   │  │    Service       │
└───────┬────────┘  └──────┬──────┘  └────────┬─────────┘
        │                   │                   │
┌───────▼────────────────────▼───────────────────▼─────────┐
│              Platform Services Layer                      │
│  (Accessibility Service, ML Kit, Local Notifications)     │
└───────────────────────────────────────────────────────────┘
```

**Layer Responsibilities:**

1. **User Interface Layer**: Renders settings screens, status indicators, and notification overlays
2. **Application Layer**: Orchestrates the workflow from text extraction through analysis to notification delivery
3. **Service Layer**: Encapsulates domain logic for text extraction, NLP processing, and notification management
4. **Platform Services Layer**: Interfaces with Android/iOS platform APIs
- Accessibility Service is explicitly user-enabled and active only when the user interacts with consent or permission dialogs.
- The service reads only visible, user-opened text and does not perform background monitoring.


**Data Flow:**

1. User opens a consent dialog in any application
2. Accessibility Service detects visible text change
3. Text Extractor captures and classifies the content
4. If classified as consent dialog, text is passed to NLP Processor
5. NLP Processor analyzes and generates simplified explanation
6. Notification Manager displays results to user
7. All temporary data is immediately discarded

## Components and Interfaces

### 1. Accessibility Service Bridge

**Purpose**: Interfaces with platform accessibility services to monitor visible screen content.

**Platform-Specific Implementation:**
- **Android**: Uses `AccessibilityService` API with `TYPE_WINDOW_CONTENT_CHANGED` events
- **iOS**: Uses limited accessibility APIs (Note: iOS has significant restrictions)

**Interface:**
```dart
abstract class AccessibilityServiceBridge {
  /// Requests accessibility permissions from the system
  Future<bool> requestPermissions();
  
  /// Checks if accessibility service is currently enabled
  Future<bool> isEnabled();
  
  /// Starts monitoring for accessibility events
  Future<void> startMonitoring();
  
  /// Stops monitoring for accessibility events
  Future<void> stopMonitoring();
  
  /// Stream of text content from visible windows
  Stream<AccessibilityEvent> get contentStream;
}

class AccessibilityEvent {
  final String packageName;
  final String text;
  final DateTime timestamp;
  final WindowType windowType;
}

enum WindowType {
  dialog,
  activity,
  overlay,
  unknown
}
```

**Key Behaviors:**
- Only captures text from TYPE_WINDOW_STATE_CHANGED and TYPE_WINDOW_CONTENT_CHANGED events
- Filters events to focus on dialog and overlay windows
- Respects user's enable/disable toggle
- Implements rate limiting to prevent excessive processing

### 2. Text Extractor Service

**Purpose**: Extracts, cleans, and classifies text from accessibility events to identify consent dialogs.

**Interface:**
```dart
class TextExtractorService {
  /// Extracts and cleans text from accessibility event
  String extractText(AccessibilityEvent event);
  
  /// Classifies whether text represents a consent dialog
  ConsentClassification classifyContent(String text);
  
  /// Validates that text meets minimum quality thresholds
  bool isValidText(String text);
}

class ConsentClassification {
  final bool isConsentDialog;
  final double confidence;
  final ConsentType type;
  final List<String> matchedKeywords;
}

enum ConsentType {
  permissionRequest,
  privacyNotice,
  termsOfService,
  dataCollection,
  cookieConsent,
  unknown
}
```

**Classification Algorithm:**

The classifier uses a keyword-based approach with weighted scoring:

1. **Keyword Matching**: Maintains lists of consent-related keywords:
   - Permission keywords: "allow", "permission", "access", "enable", "grant"
   - Privacy keywords: "privacy", "data", "collect", "share", "third party"
   - Terms keywords: "terms", "conditions", "agreement", "accept", "consent"

2. **Scoring**: Each keyword match contributes to a confidence score
   - High-weight keywords (e.g., "grant permission"): +0.3
   - Medium-weight keywords (e.g., "privacy policy"): +0.2
   - Low-weight keywords (e.g., "data"): +0.1

3. **Threshold**: Content is classified as consent dialog if confidence ≥ 0.6

4. **Context Validation**: Checks for presence of action buttons ("Accept", "Deny", "Allow", "Cancel")

**Text Cleaning:**
- Removes excessive whitespace and newlines
- Normalizes Unicode characters
- Removes non-textual elements (emojis, special characters)
- Preserves sentence structure for NLP analysis

### 3. NLP Processor Service

**Purpose**: Analyzes consent dialog text to generate simplified explanations, identify risks, and summarize consequences.

**Interface:**
```dart
class NLPProcessorService {
  /// Analyzes consent text and generates comprehensive analysis
  Future<ConsentAnalysis> analyzeConsent(String text, ConsentType type);
  
  /// Generates simplified explanation in plain language
  String simplifyText(String text);
  
  /// Identifies privacy risks in the consent text
  List<PrivacyRisk> identifyRisks(String text);
  
  /// Summarizes key consequences of accepting
  List<String> summarizeConsequences(String text);
}

class ConsentAnalysis {
  final String simplifiedExplanation;
  final List<PrivacyRisk> risks;
  final List<String> consequences;
  final Duration processingTime;
}

class PrivacyRisk {
  final String description;
  final RiskSeverity severity;
  final RiskCategory category;
}

enum RiskSeverity {
  low,
  medium,
  high
}

enum RiskCategory {
  dataCollection,
  thirdPartySharing,
  locationTracking,
  deviceAccess,
  personalInformation,
  advertising
}
```

**NLP Implementation Strategy:**

Given the on-device constraint, we use a hybrid approach:

1. **Text Simplification**:
   - Rule-based sentence simplification (split complex sentences)
   - Vocabulary substitution (replace legal terms with plain language)
   - Readability scoring using Flesch-Kincaid metrics
   - Template-based generation for common patterns

2. **Risk Identification**:
   - Pattern matching for data collection statements
   - Entity extraction for third-party names
   - Permission mapping (e.g., "location" → location tracking risk)
   - Severity scoring based on data sensitivity

3. **Consequence Summarization**:
   - Extract action verbs and their objects
   - Identify modal verbs indicating obligations ("will", "may", "must")
   - Group related statements
   - Generate bullet-point summaries

**On-Device NLP Libraries:**
- **Primary**: Custom rule-based engine (lightweight, fast)
- **Optional**: TensorFlow Lite models for advanced analysis (if device supports)
- **Fallback**: Simple keyword extraction if resources are limited

**Performance Optimization:**
- Lazy loading of NLP models
- Caching of common phrase simplifications
- Parallel processing of risk identification and simplification
- Early termination for very long texts (truncate to first 1000 words)

### 4. Notification Manager Service

**Purpose**: Delivers analysis results to users through non-intrusive notifications.

**Interface:**
```dart
class NotificationManagerService {
  /// Displays analysis results as a notification
  Future<void> showAnalysis(ConsentAnalysis analysis);
  
  /// Dismisses the current notification
  Future<void> dismissNotification();
  
  /// Updates notification preferences
  Future<void> updatePreferences(NotificationPreferences prefs);
  
  /// Checks if notifications are enabled
  Future<bool> areNotificationsEnabled();
}

class NotificationPreferences {
  final NotificationStyle style;
  final Duration displayDuration;
  final NotificationPosition position;
  final bool showRisksOnly;
}

enum NotificationStyle {
  overlay,        // Floating overlay window
  systemNotification,  // Standard Android notification
  bottomSheet     // Bottom sheet modal
}

enum NotificationPosition {
  top,
  center,
  bottom
}
```

**Notification Design:**

1. **Overlay Style** (Default):
   - Semi-transparent floating window
   - Positioned at bottom of screen (configurable)
   - Swipe to dismiss
   - Tap to expand for full details
   - Auto-dismiss after 10 seconds (configurable)

2. **System Notification Style**:
   - Uses Flutter Local Notifications plugin
   - Expandable notification with full analysis
   - Action buttons: "Dismiss", "View Details"
   - Persists until user dismisses

3. **Bottom Sheet Style**:
   - Modal bottom sheet overlay
   - Requires explicit dismissal
   - Best for high-risk consents

**Content Layout:**
```
┌─────────────────────────────────────┐
│  🔍 Consent Analysis                │
├─────────────────────────────────────┤
│  Summary:                           │
│  [Simplified explanation]           │
│                                     │
│  ⚠️ Risks Identified:               │
│  • [High risk 1]                    │
│  • [Medium risk 2]                  │
│                                     │
│  Key Points:                        │
│  • [Consequence 1]                  │
│  • [Consequence 2]                  │
└─────────────────────────────────────┘
```

### 5. Application Orchestrator

**Purpose**: Coordinates the workflow from text extraction through analysis to notification delivery.

**Interface:**
```dart
class ConsentAnalyzerOrchestrator {
  final TextExtractorService _textExtractor;
  final NLPProcessorService _nlpProcessor;
  final NotificationManagerService _notificationManager;
  
  /// Starts the consent analysis workflow
  Future<void> start();
  
  /// Stops the consent analysis workflow
  Future<void> stop();
  
  /// Processes an accessibility event through the full pipeline
  Future<void> processEvent(AccessibilityEvent event);
}
```

**Workflow Logic:**

```dart
Future<void> processEvent(AccessibilityEvent event) async {
  // Step 1: Extract and clean text
  final text = _textExtractor.extractText(event);
  
  if (!_textExtractor.isValidText(text)) {
    return; // Skip invalid text
  }
  
  // Step 2: Classify content
  final classification = _textExtractor.classifyContent(text);
  
  if (!classification.isConsentDialog || classification.confidence < 0.6) {
    return; // Not a consent dialog
  }
  
  // Step 3: Analyze with NLP
  final analysis = await _nlpProcessor.analyzeConsent(
    text,
    classification.type
  );
  
  // Step 4: Show notification
  await _notificationManager.showAnalysis(analysis);
  
  // Step 5: Cleanup (all data discarded automatically when out of scope)
}
```

### 6. Settings and State Management

**Purpose**: Manages application settings and state using Flutter's state management.

**Interface:**
```dart
class AppSettings {
  bool isAccessibilityEnabled;
  NotificationPreferences notificationPrefs;
  String preferredLanguage;
  bool multiLanguageEnabled;
  
  /// Loads settings from secure storage
  Future<void> load();
  
  /// Saves settings to secure storage
  Future<void> save();
}

class AppStateManager extends ChangeNotifier {
  AppSettings settings;
  bool isProcessing;
  ConsentAnalysis? lastAnalysis;
  
  /// Toggles accessibility service
  Future<void> toggleAccessibility(bool enabled);
  
  /// Updates notification preferences
  Future<void> updateNotificationPrefs(NotificationPreferences prefs);
}
```

## Data Models

### AccessibilityEvent
```dart
class AccessibilityEvent {
  final String packageName;      // Source app package name
  final String text;              // Extracted text content
  final DateTime timestamp;       // Event timestamp
  final WindowType windowType;    // Type of window (dialog, activity, etc.)
  
  AccessibilityEvent({
    required this.packageName,
    required this.text,
    required this.timestamp,
    required this.windowType,
  });
}
```

### ConsentClassification
```dart
class ConsentClassification {
  final bool isConsentDialog;           // Whether content is a consent dialog
  final double confidence;              // Confidence score (0.0 - 1.0)
  final ConsentType type;               // Type of consent
  final List<String> matchedKeywords;   // Keywords that triggered classification
  
  ConsentClassification({
    required this.isConsentDialog,
    required this.confidence,
    required this.type,
    required this.matchedKeywords,
  });
}
```

### ConsentAnalysis
```dart
class ConsentAnalysis {
  final String simplifiedExplanation;   // Plain language explanation
  final List<PrivacyRisk> risks;        // Identified privacy risks
  final List<String> consequences;      // Key consequences of accepting
  final Duration processingTime;        // Time taken for analysis
  
  ConsentAnalysis({
    required this.simplifiedExplanation,
    required this.risks,
    required this.consequences,
    required this.processingTime,
  });
}
```

### PrivacyRisk
```dart
class PrivacyRisk {
  final String description;       // Human-readable risk description
  final RiskSeverity severity;    // Risk severity level
  final RiskCategory category;    // Risk category
  
  PrivacyRisk({
    required this.description,
    required this.severity,
    required this.category,
  });
  
  // Comparison for sorting by severity
  int compareTo(PrivacyRisk other) {
    return other.severity.index.compareTo(severity.index);
  }
}
```

### AppSettings
```dart
class AppSettings {
  final bool isAccessibilityEnabled;
  final NotificationPreferences notificationPrefs;
  final String preferredLanguage;
  final bool multiLanguageEnabled;
  
  AppSettings({
    required this.isAccessibilityEnabled,
    required this.notificationPrefs,
    required this.preferredLanguage,
    required this.multiLanguageEnabled,
  });
  
  // Serialization for persistence
  Map<String, dynamic> toJson();
  factory AppSettings.fromJson(Map<String, dynamic> json);
}
```


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system—essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Complete Text Extraction

*For any* consent dialog detected by the accessibility service, extracting text should capture all visible text content without omission.

**Validates: Requirements 1.3**

### Property 2: Visibility-Only Extraction

*For any* accessibility event, text extraction should only occur when content is user-opened and currently visible, never from background or hidden content.

**Validates: Requirements 1.4, 1.5**

### Property 3: No Network Transmission

*For any* consent dialog analysis, the entire process from extraction through NLP processing to notification should complete without any network requests or data transmission.

**Validates: Requirements 2.1, 4.2, 4.3**

### Property 4: Text Simplification Reduces Complexity

*For any* consent dialog text analyzed, the simplified explanation should have a lower readability complexity score (Flesch-Kincaid grade level) than the original text.

**Validates: Requirements 2.2**

### Property 5: Comprehensive Risk Detection

*For any* consent dialog text containing data collection practices, third-party sharing statements, or sensitive permission requests, the NLP processor should identify and categorize these as privacy risks.

**Validates: Requirements 2.3, 7.1, 7.2, 7.3**

### Property 6: Consequence Extraction Completeness

*For any* consent dialog text, the summarized consequences should include all action statements (verbs indicating what will happen if consent is granted).

**Validates: Requirements 2.4**

### Property 7: Processing Time Bounds

*For any* consent dialog text under 500 words, NLP processing should complete within 3 seconds, and for texts under 1000 words, within 5 seconds.

**Validates: Requirements 2.5, 9.2**

### Property 8: Notification Content Completeness

*For any* completed analysis, the displayed notification should contain all three required components: simplified explanation, identified risks, and key consequences.

**Validates: Requirements 3.3**

### Property 9: Non-Blocking Notification Display

*For any* notification displayed, the original consent dialog should remain accessible and interactive (not blocked or obscured).

**Validates: Requirements 3.2**

### Property 10: Immediate Dismissal Response

*For any* notification dismissal action, the notification should be removed from display within 100 milliseconds.

**Validates: Requirements 3.4**

### Property 11: Notification Preferences Application

*For any* configured notification preference (duration, position, style), the notification system should apply that preference to all subsequent notifications.

**Validates: Requirements 3.5**

### Property 12: No Persistent Data Storage

*For any* consent dialog analysis, after processing completes, no extracted text or analysis results should exist in persistent storage (files, databases, shared preferences).

**Validates: Requirements 4.1**

### Property 13: Immediate Temporary Data Cleanup

*For any* completed analysis, all temporary data (extracted text, intermediate processing results) should be inaccessible from memory within 1 second of completion.

**Validates: Requirements 4.4**

### Property 14: No Analysis History

*For any* sequence of consent dialog analyses, the system should maintain no logs, history records, or traces of previously analyzed dialogs.

**Validates: Requirements 4.5**

### Property 15: Disabled Service Blocks Access

*For any* accessibility event when the service is disabled, no screen content should be accessed or processed.

**Validates: Requirements 5.2**

### Property 16: Consent Dialog Classification Accuracy

*For any* text content containing consent-related keywords and patterns (permission requests, privacy notices, terms of service, data collection disclosures), the classifier should correctly identify it as a consent dialog with confidence ≥ 0.6.

**Validates: Requirements 6.1, 6.2, 6.4**

### Property 17: False Positive Minimization

*For any* text content that does not match consent dialog patterns, the classifier should not trigger analysis (confidence < 0.6).

**Validates: Requirements 6.3, 6.5**

### Property 18: Risk Severity Categorization

*For any* identified privacy risk, it should be assigned a valid severity level (low, medium, or high) based on data sensitivity.

**Validates: Requirements 7.4**

### Property 19: High-Severity Risk Prominence

*For any* analysis containing multiple risks, high-severity risks should appear before medium and low-severity risks in the notification display.

**Validates: Requirements 7.5**

### Property 20: Language Detection Accuracy

*For any* consent dialog text in a supported language, the language detector should correctly identify the language with accuracy ≥ 90%.

**Validates: Requirements 8.2**

### Property 21: Output Language Matches Preference

*For any* analysis when multi-language support is enabled, the simplified explanation and risk descriptions should be in the user's configured preferred language.

**Validates: Requirements 8.3**

### Property 22: Unsupported Language Notification

*For any* consent dialog text in an unsupported language, the system should notify the user that analysis is unavailable rather than providing incorrect analysis.

**Validates: Requirements 8.4**

### Property 23: Idle Resource Minimization

*For any* period when no consent dialogs are detected, CPU usage should remain below 2% and memory usage should remain below 50MB.

**Validates: Requirements 9.1, 9.4**

### Property 24: Active Analysis Memory Bounds

*For any* active consent dialog analysis, total memory usage should not exceed 100MB.

**Validates: Requirements 9.3**

### Property 25: Resource Lifecycle Management

*For any* completed analysis, all allocated processing resources (memory buffers, NLP model instances, temporary objects) should be released within 1 second of completion.

**Validates: Requirements 9.5**

### Property 26: Extraction Failure Resilience

*For any* text extraction failure, the system should log the error internally, continue monitoring for subsequent dialogs, and not crash or terminate.

**Validates: Requirements 10.1**

### Property 27: Analysis Failure User Notification

*For any* NLP analysis failure, the system should display a user notification indicating analysis is unavailable for the current dialog.

**Validates: Requirements 10.2**

### Property 28: Permission Loss Handling

*For any* accessibility permission revocation, the system should detect the loss, notify the user, and provide instructions to re-enable.

**Validates: Requirements 10.3**

### Property 29: Malformed Text Graceful Handling

*For any* malformed or corrupted text input, the NLP processor should handle it without crashing and provide partial analysis if possible, or gracefully fail with a user notification.

**Validates: Requirements 10.4**

### Property 30: Resource Constraint Graceful Degradation

*For any* analysis attempt when system resources are insufficient (memory < 100MB available), the system should skip analysis, notify the user, and not cause system instability.

**Validates: Requirements 10.5**

## Error Handling

The application implements comprehensive error handling across all layers:

### Accessibility Service Errors

**Permission Denied:**
- Detection: Check permission status before starting monitoring
- Response: Display user-friendly dialog explaining how to grant permissions
- Recovery: Provide deep link to system accessibility settings

**Service Disconnection:**
- Detection: Monitor service lifecycle callbacks
- Response: Notify user of disconnection
- Recovery: Attempt automatic reconnection; prompt user if fails

**Event Processing Errors:**
- Detection: Try-catch around event processing pipeline
- Response: Log error internally, skip current event
- Recovery: Continue monitoring for subsequent events

### Text Extraction Errors

**Empty or Null Text:**
- Detection: Validate text before classification
- Response: Skip processing silently
- Recovery: Continue monitoring

**Malformed Text:**
- Detection: Character encoding validation
- Response: Attempt text normalization; skip if fails
- Recovery: Continue monitoring

**Extraction Timeout:**
- Detection: Timeout after 2 seconds
- Response: Log timeout, skip current dialog
- Recovery: Continue monitoring

### NLP Processing Errors

**Model Loading Failure:**
- Detection: Check model initialization status
- Response: Fall back to rule-based processing
- Recovery: Retry model loading on next analysis

**Analysis Timeout:**
- Detection: Timeout after 5 seconds
- Response: Return partial results if available
- Recovery: Continue with next analysis

**Out of Memory:**
- Detection: Catch OutOfMemoryError
- Response: Trigger garbage collection, skip analysis
- Recovery: Notify user, continue monitoring

**Unsupported Language:**
- Detection: Language detection returns unsupported code
- Response: Notify user analysis unavailable
- Recovery: Continue monitoring for other dialogs

### Notification Errors

**Notification Permission Denied:**
- Detection: Check notification permission status
- Response: Prompt user to grant notification permission
- Recovery: Fall back to system notifications if overlay fails

**Display Failure:**
- Detection: Catch exceptions during notification display
- Response: Log error, attempt alternative notification style
- Recovery: Continue with next analysis

### Resource Management Errors

**Insufficient Memory:**
- Detection: Check available memory before analysis
- Response: Skip analysis, notify user
- Recovery: Wait for memory to free up

**CPU Throttling:**
- Detection: Monitor processing time exceeding thresholds
- Response: Reduce analysis complexity
- Recovery: Resume normal processing when resources available

### Error Logging Strategy

**Privacy-Preserving Logging:**
- Log error types and codes, never log extracted text
- Log timestamps and error frequencies
- Store logs in memory only (cleared on app restart)
- Provide export option for debugging (user-initiated only)

**Error Categories:**
- CRITICAL: Service crashes, permission losses
- ERROR: Processing failures, timeouts
- WARNING: Performance degradation, partial failures
- INFO: Normal operations, state changes

## Testing Strategy

The Consent Dialog Analyzer requires a dual testing approach combining unit tests for specific scenarios and property-based tests for universal correctness guarantees.

### Testing Framework Selection

**Unit Testing:**
- Framework: Flutter's built-in `flutter_test` package
- Mocking: `mockito` for service mocking
- UI Testing: `flutter_driver` for integration tests

**Property-Based Testing:**
- Framework: `test_check` (Dart's property-based testing library)
- Configuration: Minimum 100 iterations per property test
- Generators: Custom generators for consent dialog text, accessibility events, and analysis results

### Unit Testing Strategy

Unit tests focus on specific examples, edge cases, and integration points:

**Text Extraction Tests:**
- Test extraction from sample consent dialogs (5-10 examples)
- Test handling of empty text, null text, very long text
- Test classification of known consent types
- Test false positive prevention with non-consent text

**NLP Processing Tests:**
- Test simplification of sample legal text
- Test risk identification with known risk patterns
- Test consequence extraction from sample consents
- Test handling of unsupported languages
- Test performance with various text lengths

**Notification Tests:**
- Test notification display with sample analysis results
- Test dismissal behavior
- Test preference application
- Test different notification styles

**Error Handling Tests:**
- Test behavior when extraction fails
- Test behavior when analysis fails
- Test behavior when permissions are revoked
- Test behavior under resource constraints

**Integration Tests:**
- Test end-to-end flow from accessibility event to notification
- Test service enable/disable workflow
- Test settings persistence and application

### Property-Based Testing Strategy

Property tests verify universal correctness properties across all inputs:

**Each property test must:**
1. Run minimum 100 iterations with randomized inputs
2. Reference its design document property number
3. Include a tag: `Feature: consent-dialog-analyzer, Property N: [property text]`
4. Use appropriate generators for test data

**Generator Requirements:**

```dart
// Generate random consent dialog text
Generator<String> consentDialogGenerator() {
  return Generator.string(minLength: 50, maxLength: 1000)
    .where((s) => s.contains(RegExp(r'(allow|permission|privacy|data|consent)')));
}

// Generate random accessibility events
Generator<AccessibilityEvent> accessibilityEventGenerator() {
  return Generator.combine4(
    Generator.string(minLength: 10, maxLength: 50), // package name
    consentDialogGenerator(), // text
    Generator.dateTime(), // timestamp
    Generator.enumValue(WindowType.values), // window type
    (pkg, text, time, type) => AccessibilityEvent(
      packageName: pkg,
      text: text,
      timestamp: time,
      windowType: type,
    ),
  );
}

// Generate random privacy risks
Generator<PrivacyRisk> privacyRiskGenerator() {
  return Generator.combine3(
    Generator.string(minLength: 20, maxLength: 100), // description
    Generator.enumValue(RiskSeverity.values), // severity
    Generator.enumValue(RiskCategory.values), // category
    (desc, sev, cat) => PrivacyRisk(
      description: desc,
      severity: sev,
      category: cat,
    ),
  );
}
```

**Property Test Examples:**

```dart
// Property 1: Complete Text Extraction
testCheck(
  'Feature: consent-dialog-analyzer, Property 1: Complete text extraction',
  iterations: 100,
  () {
    forAll(
      accessibilityEventGenerator(),
      (event) {
        final extracted = textExtractor.extractText(event);
        // Verify no text is lost during extraction
        expect(event.text.split(' ').every((word) => 
          extracted.contains(word) || isStopWord(word)
        ), isTrue);
      },
    );
  },
);

// Property 3: No Network Transmission
testCheck(
  'Feature: consent-dialog-analyzer, Property 3: No network transmission',
  iterations: 100,
  () {
    forAll(
      consentDialogGenerator(),
      (text) async {
        // Monitor network activity
        final networkMonitor = NetworkMonitor();
        networkMonitor.start();
        
        await nlpProcessor.analyzeConsent(text, ConsentType.permissionRequest);
        
        networkMonitor.stop();
        // Verify no network requests were made
        expect(networkMonitor.requestCount, equals(0));
      },
    );
  },
);

// Property 4: Text Simplification Reduces Complexity
testCheck(
  'Feature: consent-dialog-analyzer, Property 4: Text simplification reduces complexity',
  iterations: 100,
  () {
    forAll(
      consentDialogGenerator(),
      (text) async {
        final originalComplexity = calculateFleschKincaid(text);
        final analysis = await nlpProcessor.analyzeConsent(text, ConsentType.privacyNotice);
        final simplifiedComplexity = calculateFleschKincaid(analysis.simplifiedExplanation);
        
        // Simplified text should have lower grade level
        expect(simplifiedComplexity, lessThan(originalComplexity));
      },
    );
  },
);

// Property 12: No Persistent Data Storage
testCheck(
  'Feature: consent-dialog-analyzer, Property 12: No persistent data storage',
  iterations: 100,
  () {
    forAll(
      consentDialogGenerator(),
      (text) async {
        // Clear any existing data
        await clearAllStorage();
        
        // Perform analysis
        await orchestrator.processEvent(AccessibilityEvent(
          packageName: 'test.app',
          text: text,
          timestamp: DateTime.now(),
          windowType: WindowType.dialog,
        ));
        
        // Verify no data in persistent storage
        final storedData = await getAllStoredData();
        expect(storedData, isEmpty);
      },
    );
  },
);

// Property 16: Consent Dialog Classification Accuracy
testCheck(
  'Feature: consent-dialog-analyzer, Property 16: Consent dialog classification accuracy',
  iterations: 100,
  () {
    forAll(
      consentDialogGenerator(),
      (text) {
        final classification = textExtractor.classifyContent(text);
        
        // Text with consent keywords should be classified as consent dialog
        if (text.contains(RegExp(r'(allow|permission|privacy|consent|agree)'))) {
          expect(classification.isConsentDialog, isTrue);
          expect(classification.confidence, greaterThanOrEqualTo(0.6));
        }
      },
    );
  },
);
```

### Test Coverage Goals

- **Unit Test Coverage**: Minimum 80% code coverage
- **Property Test Coverage**: All 30 correctness properties implemented
- **Integration Test Coverage**: All critical user workflows
- **Platform Test Coverage**: Both Android and iOS (where applicable)

### Continuous Testing

- Run unit tests on every commit
- Run property tests on every pull request
- Run integration tests nightly
- Monitor test execution time (property tests may take longer due to iterations)

### Test Data Management

**Privacy-Preserving Test Data:**
- Use synthetic consent dialog text (never real user data)
- Generate test data programmatically
- Clear all test data after test execution
- Never commit test data containing sensitive information

**Test Data Sources:**
- Publicly available privacy policies and terms of service
- Synthetic generated consent text
- Anonymized and sanitized examples
