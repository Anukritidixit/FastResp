class PriorityEngine {
  static Map<String, dynamic> calculatePriority(Map<String, dynamic> userSession, {bool isHardwareImpact = false}) {
    int score = 0;
    
    // 1. Age Vulnerability Factor
    if (userSession['dob'] != null && userSession['dob'].toString().trim().isNotEmpty) {
      try {
        final parts = userSession['dob'].toString().split('/');
        if (parts.length == 3) {
          int year = int.parse(parts[2]);
          int age = DateTime.now().year - year;
          if (age > 65) score += 30; // Elderly
          else if (age < 12) score += 40; // Children
        }
      } catch (_) {
        // Ignore parsing errors for mock data
      }
    }
    
    // 2. Medical History Factor
    if (userSession['medical_conditions'] != null && userSession['medical_conditions'].toString().trim().isNotEmpty) {
      score += 40; // Chronic conditions (Asthma, Heart, etc.) elevate risk drastically
    }
    
    // 3. Allergies
    if (userSession['allergies'] != null && userSession['allergies'].toString().trim().isNotEmpty) {
      score += 20; // Risk of anaphylaxis during treatment
    }
    
    // 4. Hardware Impact Verification
    if (isHardwareImpact) {
      score += 50; // Sudden high G-force detected by sensors
    } else {
      score += 10; // Manual trigger
    }
    
    // Cap score at 100
    if (score > 100) score = 100;
    
    // Determine Triage Label
    String priorityLabel = 'Low';
    if (score >= 80) {
      priorityLabel = 'Critical';
    } else if (score >= 50) {
      priorityLabel = 'High';
    } else if (score >= 30) {
      priorityLabel = 'Medium';
    }
    
    return {
      'score': score,
      'label': priorityLabel,
    };
  }
}
