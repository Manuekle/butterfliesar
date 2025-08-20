import 'package:flutter/material.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late Animation<double> _scale;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, String>> onboardingData = [
    {
      'title': 'Descubre el Mundo de las Mariposas',
      'description':
          'Explora diferentes especies de mariposas en realidad aumentada y aprende sobre su hábitat y características únicas.',
      'icon': '🦋',
    },
    {
      'title': 'Experiencia Inmersiva',
      'description':
          'Observa las mariposas desde todos los ángulos en tu entorno real con tecnología AR.',
      'icon': '👁️',
    },
    {
      'title': 'Aprende Jugando',
      'description':
          'Datos interesantes y características interactivas para una experiencia educativa única.',
      'icon': '📚',
    },
  ];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutQuart));
    _scale = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() {
      _currentPage = page;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final primaryColor = isDark ? Colors.white : Colors.black;
    final backgroundColor = isDark ? Colors.black : Colors.white;
    final surfaceColor = isDark ? Colors.grey[900] : Colors.grey[50];

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Skip Button
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: primaryColor.withOpacity(0.8),
                ),
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/hub'),
                child: const Text('SALTAR'),
              ),
            ),

            // PageView for onboarding slides
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: onboardingData.length,
                onPageChanged: _onPageChanged,
                itemBuilder: (context, index) {
                  return FadeTransition(
                    opacity: _fade,
                    child: SlideTransition(
                      position: _slide,
                      child: ScaleTransition(
                        scale: _scale,
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Icon
                              Container(
                                padding: const EdgeInsets.all(24),
                                decoration: BoxDecoration(
                                  color: surfaceColor,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.05),
                                      blurRadius: 10,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Text(
                                  onboardingData[index]['icon']!,
                                  style: TextStyle(
                                    fontSize: 40,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 40),
                              // Title
                              Text(
                                onboardingData[index]['title']!,
                                style: TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 24,
                                  fontWeight: FontWeight.w700,
                                  color: primaryColor,
                                  height: 1.3,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 16),
                              // Description
                              Text(
                                onboardingData[index]['description']!,
                                style: TextStyle(
                                  fontFamily: 'Geist',
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: primaryColor.withOpacity(0.7),
                                  height: 1.6,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            // Page Indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                onboardingData.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _currentPage == index ? 20.0 : 8.0,
                  height: 3.0,
                  margin: const EdgeInsets.symmetric(horizontal: 2.0),
                  decoration: BoxDecoration(
                    color: _currentPage == index
                        ? primaryColor
                        : primaryColor.withOpacity(0.2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),

            // Navigation Buttons
            Padding(
              padding: const EdgeInsets.all(32.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back Button (only show if not on first page)
                  if (_currentPage > 0)
                    TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: primaryColor.withOpacity(0.7),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 16,
                        ),
                      ),
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('ATRÁS'),
                    )
                  else
                    const SizedBox(width: 80), // For proper alignment
                  // Next/Get Started Button
                  TextButton(
                    style: TextButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: isDark ? Colors.black : Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(0),
                      ),
                    ),
                    onPressed: _currentPage < onboardingData.length - 1
                        ? () {
                            _pageController.nextPage(
                              duration: const Duration(milliseconds: 300),
                              curve: Curves.easeInOut,
                            );
                          }
                        : () => Navigator.pushReplacementNamed(context, '/hub'),
                    child: Text(
                      _currentPage < onboardingData.length - 1
                          ? 'SIGUIENTE'
                          : 'COMENZAR',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
