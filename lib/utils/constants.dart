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
  ];

  /// Pattern to detect phone numbers (Sri Lankan and international).
  static final RegExp phonePattern = RegExp(
    r'(\+?94|0)\d{9,10}|\+?\d{10,15}',
  );

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
