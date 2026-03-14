import '../utils/constants.dart';

class ScamResult {
  final int score;
  final List<String> reasons;

  const ScamResult({required this.score, required this.reasons});
}

class ScamDetector {
  /// Analyze a message and return a scam score (0-100) with reasons.
  ScamResult analyzeMessage(String text) {
    if (text.trim().isEmpty) {
      return const ScamResult(score: 0, reasons: []);
    }

    final lowerText = text.toLowerCase();
    final reasons = <String>[];
    double rawScore = 0;

    // 1. Check urgency keywords (weight: 8 each)
    for (final keyword in ScamKeywords.urgency) {
      if (lowerText.contains(keyword.toLowerCase())) {
        rawScore += 8;
        reasons.add('Urgency keyword detected: "$keyword"');
      }
    }

    // 2. Check financial scam keywords (weight: 10 each)
    for (final keyword in ScamKeywords.financial) {
      if (lowerText.contains(keyword.toLowerCase())) {
        rawScore += 10;
        reasons.add('Financial scam keyword: "$keyword"');
      }
    }

    // 3. Check phishing keywords (weight: 12 each)
    for (final keyword in ScamKeywords.phishing) {
      if (lowerText.contains(keyword.toLowerCase())) {
        rawScore += 12;
        reasons.add('Phishing indicator: "$keyword"');
      }
    }

    // 4. Check Sri Lanka specific scam patterns (weight: 10 each)
    for (final keyword in ScamKeywords.sriLankaSpecific) {
      if (lowerText.contains(keyword.toLowerCase())) {
        rawScore += 10;
        reasons.add('Sri Lanka scam pattern: "$keyword"');
      }
    }

    // 5. Check for suspicious URLs (weight: 15)
    final urlMatches = ScamKeywords.suspiciousUrlPattern.allMatches(lowerText);
    if (urlMatches.isNotEmpty) {
      rawScore += 15;
      reasons.add('Suspicious link(s) detected (${urlMatches.length} found)');

      // Shortened URLs get extra penalty
      for (final match in urlMatches) {
        final url = match.group(0) ?? '';
        if (ScamKeywords.shortenedUrlDomains
            .any((d) => url.contains(d.toLowerCase()))) {
          rawScore += 10;
          reasons.add('Shortened/masked URL detected: "$url"');
          break;
        }
      }
    }

    // 6. Check for phone numbers asking to call/text (weight: 5)
    if (ScamKeywords.phonePattern.hasMatch(lowerText) &&
        (lowerText.contains('call') || lowerText.contains('text') ||
         lowerText.contains('contact') || lowerText.contains('whatsapp'))) {
      rawScore += 5;
      reasons.add('Contains phone number with call-to-action');
    }

    // 7. Excessive capitalization (weight: 5)
    final upperCount = text.runes.where((r) {
      final ch = String.fromCharCode(r);
      return ch == ch.toUpperCase() && ch != ch.toLowerCase();
    }).length;
    final letterCount = text.runes.where((r) {
      final ch = String.fromCharCode(r);
      return ch.toUpperCase() != ch.toLowerCase();
    }).length;
    if (letterCount > 10 && upperCount / letterCount > 0.5) {
      rawScore += 5;
      reasons.add('Excessive use of capital letters');
    }

    // 8. Asking for personal information (weight: 10)
    final personalInfoPatterns = [
      'bank account', 'credit card', 'debit card', 'cvv', 'pin number',
      'social security', 'nic number', 'national id', 'password',
      'otp', 'verification code',
    ];
    for (final pattern in personalInfoPatterns) {
      if (lowerText.contains(pattern)) {
        rawScore += 10;
        reasons.add('Asks for personal information: "$pattern"');
        break;
      }
    }

    // 9. Short message with link (weight: 8)
    if (text.length < 100 && urlMatches.isNotEmpty) {
      rawScore += 8;
      reasons.add('Short message with link — common scam pattern');
    }

    // Normalize score to 0-100
    final score = rawScore.clamp(0, 100).toInt();

    if (reasons.isEmpty && score == 0) {
      reasons.add('No scam indicators detected');
    }

    return ScamResult(score: score, reasons: reasons);
  }
}
