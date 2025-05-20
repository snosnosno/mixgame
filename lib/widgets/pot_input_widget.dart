import 'package:flutter/material.dart';

class PotInputWidget extends StatelessWidget {
  final TextEditingController controller;
  final VoidCallback onSubmit;

  const PotInputWidget({
    Key? key,
    required this.controller,
    required this.onSubmit,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: MediaQuery.of(context).size.width / 2 - 150,
      bottom: MediaQuery.of(context).size.height * 0.15,
      child: Container(
        width: 300,
        decoration: BoxDecoration(
          color: Colors.white.withAlpha((0.65 * 255).round()),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha((0.1 * 255).round()),
              blurRadius: 6,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  hintText: 'Enter POT! amount',
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.transparent,
                ),
                style: const TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                keyboardType: TextInputType.number,
                onSubmitted: (_) => onSubmit(),
              ),
              const SizedBox(height: 10),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  onPressed: onSubmit,
                  child: const Text('Submit'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ResultMessageWidget extends StatelessWidget {
  final String message;

  const ResultMessageWidget({
    Key? key,
    required this.message,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).size.height * 0.25,
      left: 0,
      right: 0,
      child: Center(
        child: Text(
          message,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

class NextGameButton extends StatelessWidget {
  final VoidCallback onPressed;

  const NextGameButton({
    Key? key,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      bottom: MediaQuery.of(context).size.height * 0.15,
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.deepPurpleAccent.withAlpha((0.65 * 255).round()),
            borderRadius: BorderRadius.circular(18),
          ),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 18),
              textStyle: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            onPressed: onPressed,
            child: const Text('Next Game'),
          ),
        ),
      ),
    );
  }
} 