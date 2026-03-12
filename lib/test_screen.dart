import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TestScreen extends StatefulWidget {
  const TestScreen({super.key});

  @override
  State<TestScreen> createState() => _TestScreenState();
}

class _TestScreenState extends State<TestScreen> {
  final _supabase = Supabase.instance.client;
  final _output = StringBuffer();
  bool _isLoading = false;

  void _log(String message) {
    setState(() {
      _output.writeln('${DateTime.now().toString().substring(11, 19)} - $message');
    });
  }

  void _clearLog() {
    setState(() {
      _output.clear();
    });
  }

  // Test 1: Basic Connection
  Future<void> _testConnection() async {
    setState(() => _isLoading = true);
    _log('🔌 Testing Supabase connection...');
    
    try {
      final response = await _supabase
          .from('users')
          .select('count')
          .count(CountOption.exact);
      
      _log('✅ Connection successful!');
      _log('📊 Total users in database: ${response.count}');
    } catch (e) {
      _log('❌ Connection failed: $e');
    }
    
    setState(() => _isLoading = false);
  }

  // Test 2: Fetch Trainers
  Future<void> _testFetchTrainers() async {
    setState(() => _isLoading = true);
    _log('👨‍🏫 Fetching trainers...');
    
    try {
      final response = await _supabase
          .from('trainer_profiles')
          .select()
          .limit(5);
      
      _log('✅ Found ${response.length} trainers');
      
      for (var trainer in response) {
        _log('  • ${trainer['full_name']} - ${trainer['specialties']} - ₹${trainer['price_per_session']}');
      }
    } catch (e) {
      _log('❌ Failed to fetch trainers: $e');
    }
    
    setState(() => _isLoading = false);
  }

  // Test 3: Geolocation Query (Nearby Trainers)
  Future<void> _testNearbyTrainers() async {
    setState(() => _isLoading = true);
    _log('📍 Testing geolocation query...');
    
    try {
      // Pune coordinates
      final response = await _supabase.rpc(
        'get_nearby_trainers',
        params: {
          'user_lat': 18.5204,
          'user_lng': 73.8567,
          'radius_meters': 10000,
          'limit_count': 10,
        },
      );
      
      _log('✅ Found ${response.length} nearby trainers');
      
      for (var trainer in response) {
        final distance = (trainer['distance_meters'] / 1000).toStringAsFixed(2);
        _log('  • ${trainer['full_name']} - ${distance}km away');
      }
    } catch (e) {
      _log('❌ Geolocation query failed: $e');
    }
    
    setState(() => _isLoading = false);
  }

  // Test 4: Authentication (Sign Up)
  Future<void> _testSignUp() async {
    setState(() => _isLoading = true);
    _log('🔐 Testing authentication (sign up)...');
    
    try {
      final email = 'test${DateTime.now().millisecondsSinceEpoch}@example.com';
      final password = 'Test123456!';
      
      final response = await _supabase.auth.signUp(
        email: email,
        password: password,
        data: {'full_name': 'Test User'},
      );
      
      if (response.user != null) {
        _log('✅ Sign up successful!');
        _log('📧 Email: $email');
        _log('🆔 User ID: ${response.user!.id}');
        
        // Sign out immediately
        await _supabase.auth.signOut();
        _log('🚪 Signed out');
      }
    } catch (e) {
      _log('❌ Sign up failed: $e');
    }
    
    setState(() => _isLoading = false);
  }

  // Test 5: Insert Data
  Future<void> _testInsertData() async {
    setState(() => _isLoading = true);
    _log('📝 Testing data insertion...');
    
    try {
      // First, sign up a test user
      final email = 'testinsert${DateTime.now().millisecondsSinceEpoch}@example.com';
      final password = 'Test123456!';
      
      final authResponse = await _supabase.auth.signUp(
        email: email,
        password: password,
      );
      
      if (authResponse.user != null) {
        _log('✅ Test user created');
        
        // Insert user profile
        await _supabase.from('users').insert({
          'id': authResponse.user!.id,
          'email': email,
          'full_name': 'Test Insert User',
          'role': 'client',
          'fitness_level': 'beginner',
          'city': 'Pune',
          'email_verified': true,
        });
        
        _log('✅ User profile inserted successfully');
        
        // Clean up
        await _supabase.auth.signOut();
        _log('🚪 Signed out');
      }
    } catch (e) {
      _log('❌ Insert failed: $e');
    }
    
    setState(() => _isLoading = false);
  }

  // Test 6: Real-time Subscription
  Future<void> _testRealtime() async {
    _log('🔴 Testing real-time subscriptions...');
    _log('📡 Listening for changes in users table...');
    _log('⏳ Waiting 10 seconds...');
    
    final subscription = _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .limit(1)
        .listen((data) {
          _log('🎯 Real-time update received! ${data.length} records');
        });
    
    await Future.delayed(const Duration(seconds: 10));
    
    subscription.cancel();
    _log('✅ Real-time test complete (subscription cancelled)');
  }

  // Test 7: Fetch Reviews
  Future<void> _testFetchReviews() async {
    setState(() => _isLoading = true);
    _log('⭐ Fetching reviews...');
    
    try {
      final response = await _supabase
          .from('reviews')
          .select('''
            rating,
            review_text,
            created_at,
            users!inner(full_name)
          ''')
          .limit(5);
      
      _log('✅ Found ${response.length} reviews');
      
      for (var review in response) {
        _log('  • ${review['users']['full_name']}: ${review['rating']}⭐ - "${review['review_text']}"');
      }
    } catch (e) {
      _log('❌ Failed to fetch reviews: $e');
    }
    
    setState(() => _isLoading = false);
  }

  // Run all tests
  Future<void> _runAllTests() async {
    _clearLog();
    _log('🚀 Running all tests...\n');
    
    await _testConnection();
    await Future.delayed(const Duration(seconds: 1));
    
    await _testFetchTrainers();
    await Future.delayed(const Duration(seconds: 1));
    
    await _testNearbyTrainers();
    await Future.delayed(const Duration(seconds: 1));
    
    await _testFetchReviews();
    await Future.delayed(const Duration(seconds: 1));
    
    await _testSignUp();
    await Future.delayed(const Duration(seconds: 1));
    
    await _testInsertData();
    
    _log('\n✨ All tests complete!');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Spotter DB Test'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          // Test Buttons
          Container(
            padding: const EdgeInsets.all(16),
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _runAllTests,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Run All Tests'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testConnection,
                  icon: const Icon(Icons.wifi),
                  label: const Text('Connection'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testFetchTrainers,
                  icon: const Icon(Icons.people),
                  label: const Text('Trainers'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testNearbyTrainers,
                  icon: const Icon(Icons.location_on),
                  label: const Text('Nearby'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testFetchReviews,
                  icon: const Icon(Icons.star),
                  label: const Text('Reviews'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testSignUp,
                  icon: const Icon(Icons.person_add),
                  label: const Text('Sign Up'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testInsertData,
                  icon: const Icon(Icons.add),
                  label: const Text('Insert'),
                ),
                ElevatedButton.icon(
                  onPressed: _isLoading ? null : _testRealtime,
                  icon: const Icon(Icons.radio),
                  label: const Text('Real-time'),
                ),
                ElevatedButton.icon(
                  onPressed: _clearLog,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(),
          
          // Loading Indicator
          if (_isLoading)
            const LinearProgressIndicator(),
          
          // Output Log
          Expanded(
            child: Container(
              color: Colors.black87,
              padding: const EdgeInsets.all(16),
              child: SingleChildScrollView(
                child: Text(
                  _output.toString(),
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    color: Colors.greenAccent,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}