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
  OnboardingController _controller = OnboardingController();

  void _handleContinue() {
    _controller.incrementStep();

    if (_controller.step > 3) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => LoginView()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Onboarding")),
      body: Padding(
        padding: EdgeInsetsGeometry.only(left: 20),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Image.asset("assets/images/${(_controller.step % 3) + 1}.png"),
              Text(
                _controller.step.toString(),
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.w700),
              ),
              TextButton(
                onPressed: () => setState(() => _handleContinue()),
                child: Text("Lanjut"),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(3, (index) {
                  return Container(
                    margin: EdgeInsets.symmetric(
                      horizontal: 4.0,
                      vertical: 20.0,
                    ),
                    width: 12.0,
                    height: 12.0,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Change color based on current index
                      color: 0 == index ? Colors.blue : Colors.grey,
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
