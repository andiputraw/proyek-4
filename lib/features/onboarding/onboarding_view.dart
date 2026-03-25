import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:logbook_app_001/features/auth/login_view.dart';
import 'package:logbook_app_001/features/onboarding/onboarding_controller.dart';

class OnboardingView extends StatefulWidget {
  const OnboardingView({super.key});

  @override
  State<OnboardingView> createState() => _OnboardingState();
}

class _OnboardingState extends State<OnboardingView> {
  final OnboardingController _controller = OnboardingController();

  void _handleContinue() {
    if (_controller.step >= 2) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginView()),
      );
      return;
    }

    _controller.incrementStep();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Preload all onboarding images into memory so they swap instantly
    precacheImage(const AssetImage("assets/images/Emilie_1.png"), context);
    precacheImage(const AssetImage("assets/images/Emilie_2.png"), context);
    precacheImage(const AssetImage("assets/images/Emilie_3.png"), context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Onboarding")),
      body: Padding(
        padding: const EdgeInsetsGeometry.only(
          left: 20,
        ), // Note: might want EdgeInsets.symmetric(horizontal: 20) instead to keep it centered!
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Constrain the size and set how it should fit
              Image.asset(
                "assets/images/Emilie_${(_controller.step % 3) + 1}.png",
                height: 200, // Adjust this number to fit your design
                width: double.infinity,
                fit: BoxFit.contain, // Prevents stretching
              ),
              const SizedBox(height: 20), // Added a little breathing room
              TextButton(
                onPressed: () => setState(() => _handleContinue()),
                child: const Text("Lanjut"),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4.0,
                      vertical: 20.0,
                    ),
                    width: 12.0,
                    height: 12.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _controller.step == index
                          ? Colors.blue
                          : Colors.grey,
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
