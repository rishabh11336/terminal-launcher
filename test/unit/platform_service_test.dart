import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:terminal_launcher/services/platform_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.rishabh.terminal_launcher/platform');
  late PlatformService svc;

  setUp(() {
    svc = PlatformService();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('PlatformService — expandNotifications', () {
    test('calls expandNotifications on channel', () async {
      String? calledMethod;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calledMethod = call.method;
        return null;
      });

      await svc.expandNotifications();
      expect(calledMethod, equals('expandNotifications'));
    });

    test('does not throw when channel returns success', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => null);

      expect(() => svc.expandNotifications(), returnsNormally);
    });

    test('does not throw when channel throws PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(code: 'EXPAND_FAILED', message: 'Hidden API blocked');
      });

      // Should not propagate — graceful degradation (TRD Section 14.1)
      expect(() async => await svc.expandNotifications(), returnsNormally);
    });
  });

  group('PlatformService — lockScreen', () {
    test('calls lockScreen on channel', () async {
      String? calledMethod;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        calledMethod = call.method;
        return null;
      });

      await svc.lockScreen();
      expect(calledMethod, equals('lockScreen'));
    });

    test('does not throw when channel returns success', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async => null);

      expect(() => svc.lockScreen(), returnsNormally);
    });

    test('does not throw when PERMISSION_DENIED PlatformException', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (call) async {
        throw PlatformException(
            code: 'PERMISSION_DENIED', message: 'Device admin not granted');
      });

      // Should not propagate — logged silently (TRD Section 14.2 P2)
      expect(() async => await svc.lockScreen(), returnsNormally);
    });
  });
}
