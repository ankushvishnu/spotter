class AppConstants {
  // App Info
  static const String appName = 'Spotter';
  static const String appTagline = 'Find Your Perfect Fitness Trainer';
  
  // Fitness Specialties
  static const List<String> specialties = [
    'Yoga',
    'Calisthenics',
    'HIIT',
  ];
  
  // Fitness Levels
  static const List<String> fitnessLevels = [
    'beginner',
    'intermediate',
    'advanced',
  ];
  
  // Fitness Goals
  static const List<String> fitnessGoals = [
    'weight_loss',
    'muscle_gain',
    'flexibility',
    'strength',
    'endurance',
    'general_fitness',
  ];
  
  // Location Types
  static const List<String> locationTypes = [
    'trainer_space',
    'client_location',
    'park',
    'gym',
  ];
  
  // Session Durations (in minutes)
  static const List<int> sessionDurations = [30, 45, 60, 90];
  
  // Search Radius Options (in meters)
  static const Map<String, int> searchRadii = {
    '1 km': 1000,
    '3 km': 3000,
    '5 km': 5000,
    '10 km': 10000,
  };
  
  // Price Ranges
  static const int minPrice = 1000;
  static const int maxPrice = 5000;
  
  // Subscription Tiers
  static const String freeTier = 'free';
  static const String proTier = 'pro';
  
  // Rating Thresholds
  static const double minRating = 1.0;
  static const double maxRating = 5.0;
  
  // Pagination
  static const int trainersPerPage = 20;
  static const int messagesPerPage = 50;
  static const int reviewsPerPage = 10;
}
