import 'package:bantuin/UI/opening/opening2.dart';
import 'package:flutter/material.dart';


import 'dart:async';

class OpeningAnimationScreen extends StatefulWidget {
  const OpeningAnimationScreen({super.key});

  @override
  State<OpeningAnimationScreen> createState() => _OpeningAnimationScreenState();
}

class _OpeningAnimationScreenState extends State<OpeningAnimationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;


  final Duration _durasiAnimasi = const Duration(seconds: 3);


  final double _posisiAwal =
      1000.0; 
  final double _posisiAkhir =
      -350.0; 

  

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(duration: _durasiAnimasi, vsync: this);

    
    _animation = Tween<double>(
      begin: _posisiAwal,
      end: _posisiAkhir,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    
    _controller.forward();

  
    Timer(_durasiAnimasi + const Duration(milliseconds: 1000), () {
     
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const OnboardingScreen1()),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return Stack(
            children: [
              
              Positioned(
                
                top: _animation.value,
                left: 0,
                right: 0,
                child: child!, 
              ),
            ],
          );
        },
       
        child: Image.asset(
          'assets/images/animasi.png', 
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}
