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

    // -- 1. Urgency keywords (8 each) -----------------------------------------
    for (final kw in ScamKeywords.urgency) {
      if (lowerText.contains(kw)) {
        rawScore += 8;
        reasons.add('Urgency keyword detected: "$kw"');
      }
    }

    // -- 2. Financial scam keywords (10 each) ----------------------------------
    for (final kw in ScamKeywords.financial) {
      if (lowerText.contains(kw)) {
        rawScore += 10;
        reasons.add('Financial scam keyword: "$kw"');
      }
    }

    // -- 3. Prize / lottery scam patterns -------------------------------------
    final hasCongrats =
        lowerText.contains('congratulations') || lowerText.contains('congrats');
    final hasWon =
        lowerText.contains(' won ') ||
        lowerText.contains('you have won') ||
        lowerText.contains("you've won") ||
        lowerText.contains('won a prize') ||
        lowerText.contains('won the lottery');
    final hasSelected =
        lowerText.contains('lucky winner') ||
        lowerText.contains('lucky draw') ||
        lowerText.contains('selected as winner') ||
        lowerText.contains('you have been selected') ||
        lowerText.contains("you've been selected");
    final hasHumanitarian =
        lowerText.contains('humanitarian aid') ||
        lowerText.contains('relief fund') ||
        lowerText.contains('charity grant');

    if (hasCongrats) {
      rawScore += 12;
      reasons.add('Congratulatory prize language');
    }
    if (hasWon) {
      rawScore += 15;
      reasons.add('Prize winning claim');
    }
    if (hasSelected) {
      rawScore += 15;
      reasons.add('False winner-selection claim');
    }
    if (hasHumanitarian) {
      rawScore += 15;
      reasons.add('Fake humanitarian/charity prize claim');
    }

    // -- 4. Phishing keywords (12 each) ----------------------------------------
    for (final kw in ScamKeywords.phishing) {
      if (lowerText.contains(kw)) {
        rawScore += 12;
        reasons.add('Phishing indicator: "$kw"');
      }
    }

    // -- 5. Sri Lanka specific scam patterns (10 each) -------------------------
    for (final kw in ScamKeywords.sriLankaSpecific) {
      if (lowerText.contains(kw)) {
        rawScore += 10;
        reasons.add('Sri Lanka scam pattern: "$kw"');
      }
    }

    // -- 5b. Singlish / romanized Sinhala loan scam keywords (10 each) ---------
    var hasSinglishLoanKeyword = false;
    for (final kw in ScamKeywords.singlishLoanScam) {
      if (lowerText.contains(kw)) {
        rawScore += 10;
        hasSinglishLoanKeyword = true;
        reasons.add('Singlish loan scam keyword: "$kw"');
      }
    }

    // -- 6. Organization impersonation (20 each, max 2) -----------------------
    var orgMatches = 0;
    for (final org in ScamKeywords.orgImpersonation) {
      if (lowerText.contains(org)) {
        rawScore += 20;
        reasons.add('Impersonates official organization: "$org"');
        orgMatches++;
        if (orgMatches >= 2) break;
      }
    }
    final hasOrgImpersonation = orgMatches > 0;

    // -- 7. Personal data harvesting patterns (12 each) -----------------------
    var personalDataMatches = 0;
    for (final pattern in ScamKeywords.personalDataRequest) {
      if (lowerText.contains(pattern)) {
        rawScore += 12;
        reasons.add('Requests personal information: "$pattern"');
        personalDataMatches++;
      }
    }
    if (ScamKeywords.personalFieldsPattern.hasMatch(lowerText)) {
      rawScore += 15;
      reasons.add('Harvests multiple personal details (name, age, address...)');
      personalDataMatches++;
    }
    final hasPersonalDataRequest = personalDataMatches > 0;

    // -- 8. Suspicious URLs (15) -----------------------------------------------
    final urlMatches = ScamKeywords.suspiciousUrlPattern.allMatches(lowerText);
    if (urlMatches.isNotEmpty) {
      rawScore += 15;
      reasons.add('Suspicious link(s) detected (${urlMatches.length} found)');
      for (final match in urlMatches) {
        final url = match.group(0) ?? '';
        if (ScamKeywords.shortenedUrlDomains.any((d) => url.contains(d))) {
          rawScore += 10;
          reasons.add('Shortened/masked URL detected: "$url"');
          break;
        }
      }
    }

    // -- 8b. Unsolicited advertisement / SMS STOP indicator (18) ---------------
    if (ScamKeywords.unsolicitedSmsPattern.hasMatch(lowerText)) {
      rawScore += 18;
      reasons.add(
        'Unsolicited advertisement — contains SMS opt-out instruction (SMS STOP / StopAd)',
      );
    }

    // -- 8c. Promotional code in message (12) -----------------------------------
    if (lowerText.contains('promo code') ||
        lowerText.contains('promocode') ||
        lowerText.contains('promo:') ||
        RegExp(
          r'\bpromo\s+code\s*:',
          caseSensitive: false,
        ).hasMatch(lowerText)) {
      rawScore += 12;
      reasons.add(
        'Contains promotional code — common in loan scam advertisements',
      );
    }

    // -- 9. Email address detection --------------------------------------------
    final emailMatches = ScamKeywords.emailPattern.allMatches(lowerText);
    var hasContactEmail = false;
    if (emailMatches.isNotEmpty) {
      hasContactEmail = true;
      final emailStr = emailMatches.first.group(0) ?? '';
      final isFreeEmail = ScamKeywords.freeEmailDomains.any(
        (d) => emailStr.contains(d),
      );
      if (isFreeEmail) {
        rawScore += 22;
        reasons.add(
          'Free personal email used as official contact ($emailStr) - classic scam',
        );
      } else {
        rawScore += 10;
        reasons.add('Contains contact email address: $emailStr');
      }
    }

    // -- 10. Large monetary amount with currency -------------------------------
    final amountMatches = ScamKeywords.largeAmountPattern.allMatches(lowerText);
    var hasLargeAmount = false;
    if (amountMatches.isNotEmpty) {
      hasLargeAmount = true;
      rawScore += 20;
      reasons.add(
        'Large monetary amount promised (${amountMatches.first.group(0)?.trim()})',
      );
    }
    // Also catch Sri Lankan Rs. prefix format (e.g. Rs. 80 000, Rs.120,000)
    if (!hasLargeAmount &&
        ScamKeywords.sriLankanAmountPattern.hasMatch(lowerText)) {
      hasLargeAmount = true;
      final slMatch = ScamKeywords.sriLankanAmountPattern
          .firstMatch(lowerText)
          ?.group(0)
          ?.trim();
      rawScore += 18;
      reasons.add('Sri Lankan rupee amount promised ($slMatch)');
    }

    // -- 11. Phone number with call-to-action (5) ------------------------------
    if (ScamKeywords.phonePattern.hasMatch(lowerText) &&
        (lowerText.contains('call') ||
            lowerText.contains('text') ||
            lowerText.contains('contact') ||
            lowerText.contains('whatsapp'))) {
      rawScore += 5;
      reasons.add('Contains phone number with call-to-action');
    }

    // -- 12. Excessive capitalization (8) --------------------------------------
    final upperCount = text.runes.where((r) {
      final ch = String.fromCharCode(r);
      return ch == ch.toUpperCase() && ch != ch.toLowerCase();
    }).length;
    final letterCount = text.runes.where((r) {
      final ch = String.fromCharCode(r);
      return ch.toUpperCase() != ch.toLowerCase();
    }).length;
    if (letterCount > 10 && upperCount / letterCount > 0.5) {
      rawScore += 8;
      reasons.add('Excessive use of capital letters');
    }

    // -- 13. Classic sensitive credential request (10, first match only) ------
    const sensitiveFields = [
      'bank account',
      'credit card',
      'debit card',
      'cvv',
      'pin number',
      'social security',
      'nic number',
      'national id',
      'password',
      'otp',
      'verification code',
    ];
    for (final pattern in sensitiveFields) {
      if (lowerText.contains(pattern)) {
        rawScore += 10;
        reasons.add('Asks for sensitive credential: "$pattern"');
        break;
      }
    }

    // -- 14. Short message with link (8) ---------------------------------------
    if (text.length < 100 && urlMatches.isNotEmpty) {
      rawScore += 8;
      reasons.add('Short message with link - common scam pattern');
    }

    // -- 15. COMBINATION BOOSTS ------------------------------------------------
    if (hasOrgImpersonation &&
        hasLargeAmount &&
        (hasContactEmail || urlMatches.isNotEmpty)) {
      rawScore += 35;
      reasons.add(
        'HIGH RISK: Advance-fee fraud - fake organization + large reward + contact request',
      );
    }
    if ((hasCongrats || hasWon) && hasPersonalDataRequest) {
      rawScore += 25;
      reasons.add(
        'HIGH RISK: Prize claim combined with personal data harvesting',
      );
    }
    if (hasOrgImpersonation && hasPersonalDataRequest) {
      rawScore += 20;
      reasons.add(
        'HIGH RISK: Official authority impersonation requesting personal details',
      );
    }
    // Singlish loan keywords + shortened URL = instant-loan scam ad
    if (hasSinglishLoanKeyword && urlMatches.isNotEmpty) {
      rawScore += 30;
      reasons.add(
        'HIGH RISK: Singlish loan scam — local-language loan promise with suspicious link',
      );
    }

    // -- Normalize -------------------------------------------------------------
    final score = rawScore.clamp(0, 100).toInt();

    if (reasons.isEmpty && score == 0) {
      reasons.add('No scam indicators detected');
    }

    return ScamResult(score: score, reasons: reasons);
  }
}
