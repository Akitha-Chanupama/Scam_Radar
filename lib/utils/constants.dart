/// Scam keyword dictionaries and patterns used by the rule-based detector.
class ScamKeywords {
  ScamKeywords._();

  static const List<String> urgency = [
    'urgent',
    'immediately',
    'act now',
    'limited time',
    'expires today',
    'last chance',
    'don\'t miss',
    'hurry',
    'right now',
    'within 24 hours',
    'final warning',
    'action required',
    'respond immediately',
    'time sensitive',
  ];

  static const List<String> financial = [
    'win',
    'winner',
    'prize',
    'lottery',
    'jackpot',
    'cash reward',
    'free money',
    'claim your',
    'million',
    'transfer funds',
    'bank account',
    'investment opportunity',
    'guaranteed return',
    'double your money',
    'bitcoin',
    'crypto',
    'easy money',
    'make money fast',
    'financial freedom',
    'inheritance',
    'won',
    'winning',
    'winnings',
    'pound',
    'pounds',
    'award',
    'grant',
    'reward',
    'bonus',
  ];

  static const List<String> phishing = [
    'verify your account',
    'click here',
    'click below',
    'update your information',
    'confirm your identity',
    'suspended account',
    'unusual activity',
    'security alert',
    'verify your identity',
    'reset your password',
    'unauthorized access',
    'update payment',
    'billing problem',
    'account locked',
    'login attempt',
  ];

  static const List<String> sriLankaSpecific = [
    'dialog',
    'mobitel',
    'hutch',
    'airtel lanka',
    'sri lanka telecom',
    'slt',
    'bank of ceylon',
    'peoples bank',
    'commercial bank',
    'sampath bank',
    'hatton national',
    'hnb',
    'nsb',
    'nation builders',
    'rupees',
    'lkr',
    'customs',
    'sri lanka customs',
    'ems parcel',
    'speed post',
    'government grant',
    'samurdhi',
  ];

  /// Singlish (romanized Sinhala) loan and financial scam keywords.
  /// Commonly used in Sri Lankan SMS instant-loan scams.
  static const List<String> singlishLoanScam = [
    // Core money / loan words
    'mudal',       // money / loan
    'nayak',       // a loan
    'naya mudal',  // loan money
    'palamu naya', // first loan
    // Urgency
    'hadisi',      // fast / quick
    'hadissiya',   // urgency
    'sathi anthayata', // urgently
    // "Do you need"
    'avashyada',
    'awashyada',
    'avashya',
    'awashya',
    // Promise to give
    'labadayi',
    'labhadayi',
    'labaaganna',
    'labaganna',
    'labagena',
    'dimanawa',    // will give
    // Loan action phrases
    'thora ganna', // take a loan
    'dakwa',       // up to (amount)
    'ayadum karanna', // apply now
    'ayadum',      // apply
    'wattamak',    // percentage / approval rate
    'miniththu',   // minutes
    'mehidi',      // here / from here
    'araganna',    // to take
    'danma',       // right now
  ];

  /// Regex pattern to detect URLs in text.
  static final RegExp suspiciousUrlPattern = RegExp(
    r'https?://[^\s<>"{}|\\^`\[\]]+|www\.[^\s<>"{}|\\^`\[\]]+',
    caseSensitive: false,
  );

  /// Domains commonly used for URL shortening/masking.
  static const List<String> shortenedUrlDomains = [
    'bit.ly',
    'tinyurl.com',
    'goo.gl',
    't.co',
    'ow.ly',
    'is.gd',
    'buff.ly',
    'rebrand.ly',
    'cutt.ly',
    'short.io',
    'rb.gy',
    'bitly.cx',
    'tiny.cc',
    'clck.ru',
    'shorturl.at',
  ];

  /// Pattern to detect phone numbers (Sri Lankan and international).
  static final RegExp phonePattern = RegExp(r'(\+?94|0)\d{9,10}|\+?\d{10,15}');

  /// Regex to detect email addresses.
  static final RegExp emailPattern = RegExp(
    r'\b[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}\b',
  );

  /// Free email service domains commonly misused in scams.
  static const List<String> freeEmailDomains = [
    '@gmail.com',
    '@yahoo.com',
    '@hotmail.com',
    '@outlook.com',
    '@live.com',
    '@aol.com',
    '@mail.com',
    '@icloud.com',
    '@ymail.com',
    '@protonmail.com',
    '@zohomail.com',
  ];

  /// Regex to detect large monetary amounts with optional currency adjective
  /// (e.g. "875,000 BRITISH POUND" or "50,000 dollars").
  static final RegExp largeAmountPattern = RegExp(
    r'\b\d[\d,\.]+\s*(?:\w+\s+)?(pounds?|dollars?|euros?|usd|gbp|eur|lkr|rupees?|rand)\b',
    caseSensitive: false,
  );

  /// Regex to detect Sri Lankan rupee amounts in the local Rs. prefix format:
  /// e.g. "Rs. 80 000", "Rs.120,000", "Rs 50000".
  static final RegExp sriLankanAmountPattern = RegExp(
    r'\brs\.?\s*\d[\d,\.\s]*\d\b',
    caseSensitive: false,
  );

  /// Regex to detect unsolicited advertisement opt-out patterns.
  /// "*SMS STOP", "StopAd", "SMS NO" are mandatory in Sri Lankan bulk SMS
  /// marketing — their presence signals an unsolicited promotional message.
  static final RegExp unsolicitedSmsPattern = RegExp(
    r'\*?\s*sms\s+stop\b|\*?\s*stopads?\b|\*?\s*stop\s*ad\b|sms\s+no\s+\w+',
    caseSensitive: false,
  );

  /// Regex to detect comma/semicolon-separated personal info field requests
  /// (e.g. "NAME,AGE,ADDRESS").
  static final RegExp personalFieldsPattern = RegExp(
    r'\b(name|age|address|occupation|phone|nationality)\s*[,;]'
    r'|[,;]\s*(name|age|address|occupation|phone|nationality)\b',
    caseSensitive: false,
  );

  /// Prize / lottery notification fraud keywords.
  static const List<String> prizeScam = [
    'you have won',
    "you've won",
    'you won',
    'won a prize',
    'won the lottery',
    'selected as winner',
    'lucky winner',
    'lucky draw',
    'prize winner',
    'claim your prize',
    'claim your reward',
    'congratulations',
    'congrats',
    'you have been selected',
    "you've been selected",
    'humanitarian aid',
    'relief fund',
    'charity grant',
    'unclaimed prize',
    'unclaimed funds',
    'prize money',
    'cash prize',
    'entitled to',
  ];

  /// Official organization / authority impersonation indicators.
  static const List<String> orgImpersonation = [
    'united nations',
    'un humanitarian',
    'world bank',
    'world health organization',
    'interpol',
    'fbi',
    'cia',
    'mi6',
    'scotland yard',
    'government of',
    'ministry of finance',
    'central bank',
    'international monetary fund',
    'imf',
    'royal family',
    'british government',
    'federal reserve',
    'bank of england',
    'microsoft lottery',
    'google lottery',
    'facebook lottery',
    'whatsapp lottery',
    'youtube lottery',
  ];

  /// Personal data harvesting request patterns.
  static const List<String> personalDataRequest = [
    'your full name',
    'your name',
    'your age',
    'your address',
    'your occupation',
    'your nationality',
    'your date of birth',
    'your d.o.b',
    'send us your',
    'email us your',
    'provide your',
    'send your details',
    'your details to',
    'your information to',
    'contact us with your',
    'send the following',
    'reply with your',
    'fill in your',
    'submit your',
  ];

  /// Scam type categories for reporting.
  static const List<String> scamTypes = [
    'Lottery / Prize',
    'Bank Fraud',
    'Package Delivery',
    'Insurance',
    'Romance / Dating',
    'Investment',
    'Government Impersonation',
    'Tech Support',
    'Job Offer',
    'Other',
  ];

  /// Sri Lankan districts with approximate center coordinates.
  static const Map<String, List<double>> sriLankanDistricts = {
    'Colombo': [6.9271, 79.8612],
    'Gampaha': [7.0840, 80.0098],
    'Kalutara': [6.5854, 79.9607],
    'Kandy': [7.2906, 80.6337],
    'Matale': [7.4675, 80.6234],
    'Nuwara Eliya': [6.9497, 80.7891],
    'Galle': [6.0535, 80.2210],
    'Matara': [5.9549, 80.5550],
    'Hambantota': [6.1429, 81.1212],
    'Jaffna': [9.6615, 80.0255],
    'Kilinochchi': [9.3803, 80.3770],
    'Mannar': [8.9810, 79.9044],
    'Mullaitivu': [9.2671, 80.8142],
    'Vavuniya': [8.7514, 80.4971],
    'Trincomalee': [8.5874, 81.2152],
    'Batticaloa': [7.7310, 81.6747],
    'Ampara': [7.2975, 81.6820],
    'Kurunegala': [7.4863, 80.3647],
    'Puttalam': [8.0362, 79.8283],
    'Anuradhapura': [8.3114, 80.4037],
    'Polonnaruwa': [7.9403, 81.0188],
    'Badulla': [6.9934, 81.0550],
    'Monaragala': [6.8728, 81.3507],
    'Ratnapura': [6.6828, 80.3992],
    'Kegalle': [7.2513, 80.3464],
  };
}
