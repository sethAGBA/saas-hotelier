import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:k_empire/screens/home_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({Key? key}) : super(key: key);

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> _onboardingPages = [
    {
      'image': 'assets/icon/icon.png',
      'title': 'Bienvenue sur K-EmpireCorporation',
      'description': 'Votre plateforme de gestion de formations tout-en-un.',
    },
    {
      'image': 'assets/icon/icon.png',
      'title': 'Gérez vos cours',
      'description': 'Accédez facilement à vos formations et suivez votre progression.',
    },
    {
      'image': 'assets/icon/icon.png',
      'title': 'Restez informé',
      'description': 'Recevez des notifications importantes et des annonces.',
    },
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  Future<void> _completeOnboarding() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasSeenOnboarding', true);
    // Debug log to help trace navigation issues
    print('[ONBOARDING] Completed onboarding, navigating to HomeScreen');
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (context) => const HomeScreen()),
        );
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            itemCount: _onboardingPages.length,
            onPageChanged: _onPageChanged,
            itemBuilder: (context, index) {
              return _buildPage(context, _onboardingPages[index]);
            },
          ),
          Positioned( // Dots indicator
            bottom: 100,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _onboardingPages.length,
                (index) => _buildDot(index, context),
              ),
            ),
          ),
          Positioned( // Skip or Get Started button
            bottom: 40,
            left: 20,
            right: 20,
            child: _currentPage == _onboardingPages.length - 1
                ? ElevatedButton(
                    onPressed: _completeOnboarding,
                    child: const Text('Commencer'),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        onPressed: _completeOnboarding,
                        child: const Text('Passer'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          _pageController.nextPage(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeIn,
                          );
                        },
                        child: const Text('Suivant'),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(BuildContext context, Map<String, String> pageData) {
    return SingleChildScrollView( // Added SingleChildScrollView
      padding: const EdgeInsets.all(40.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            pageData['image']!,
            height: 200,
          ),
          const SizedBox(height: 40),
          Text(
            pageData['title']!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
          ),
          const SizedBox(height: 20),
          Text(
            pageData['description']!,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.white70,
                ),
          ),
        ],
      ),
    );
  }

  Widget _buildDot(int index, BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4.0),
      height: 10.0,
      width: 10.0,
      decoration: BoxDecoration(
        color: _currentPage == index ? Theme.of(context).primaryColor : Colors.grey,
        borderRadius: BorderRadius.circular(5.0),
      ),
    );
  }
}