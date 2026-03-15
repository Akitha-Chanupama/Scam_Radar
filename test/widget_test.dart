import 'package:flutter_test/flutter_test.dart';
import 'package:scam_radar/services/scam_detector.dart';

void main() {
  late ScamDetector detector;

  setUp(() {
    detector = ScamDetector();
  });

  group('ScamDetector', () {
    test('clean message returns low score', () {
      final result = detector.analyzeMessage('Hello, how are you doing today?');
      expect(result.score, lessThan(30));
    });

    test('message with urgency keywords scores higher', () {
      final result = detector.analyzeMessage(
        'URGENT: Act now or your account will be suspended immediately!',
      );
      expect(result.score, greaterThan(10));
      expect(result.reasons, isNotEmpty);
    });

    test('message with financial scam keywords scores high', () {
      final result = detector.analyzeMessage(
        'Congratulations! You have won a lottery prize of 1 million rupees. '
        'Claim your prize now by clicking here.',
      );
      expect(result.score, greaterThan(30));
    });

    test('message with phishing indicators scores high', () {
      final result = detector.analyzeMessage(
        'Your bank account has been locked due to unusual activity. '
        'Click here to verify your account: http://bit.ly/fake',
      );
      expect(result.score, greaterThan(40));
    });

    test('message with personal info request scores high', () {
      final result = detector.analyzeMessage(
        'Please provide your bank account number and OTP to complete verification.',
      );
      expect(result.score, greaterThan(15));
    });

    test('empty message returns score 0', () {
      final result = detector.analyzeMessage('');
      expect(result.score, equals(0));
    });

    test('Sri Lanka specific keywords detected', () {
      final result = detector.analyzeMessage(
        'Dialog Axiata is giving free 5000 rupees to selected customers. '
        'Send your NIC number to claim.',
      );
      expect(result.score, greaterThan(15));
    });

    test('short message with link is suspicious', () {
      final result = detector.analyzeMessage(
        'Check this: https://bit.ly/scam123',
      );
      expect(result.score, greaterThan(20));
    });
  });
}
