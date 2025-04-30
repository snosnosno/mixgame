import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(const PLOGameApp());
}

class PLOGameApp extends StatelessWidget {
  const PLOGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: PLOGamePage(),
    );
  }
}

class PLOGamePage extends StatefulWidget {
  const PLOGamePage({super.key});

  @override
  _PLOGamePageState createState() => _PLOGamePageState();
}

class _PLOGamePageState extends State<PLOGamePage> {
  List<String> deck = [];
  List<List<String>> playerHands = [];
  List<String> communityCards = [];

  void generateDeck() {
    List<String> suits = ['S', 'H', 'D', 'C'];
    List<String> ranks = [
      '2',
      '3',
      '4',
      '5',
      '6',
      '7',
      '8',
      '9',
      '10',
      'J',
      'Q',
      'K',
      'A'
    ];
    deck = [];
    for (var suit in suits) {
      for (var rank in ranks) {
        deck.add('$rank$suit');
      }
    }
    deck.shuffle(Random());
  }

  void dealCards(int playerCount) {
    generateDeck();
    playerHands = [];
    for (int i = 0; i < playerCount; i++) {
      playerHands.add(deck.sublist(0, 4));
      deck.removeRange(0, 4);
    }
    communityCards = deck.sublist(0, 5);
  }

  @override
  void initState() {
    super.initState();
    dealCards(3); // 기본 3명
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PLO Random Deal')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text('Community Cards: $communityCards',
                style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: playerHands.length,
                itemBuilder: (context, index) {
                  return Text('Player ${index + 1}: ${playerHands[index]}',
                      style: const TextStyle(fontSize: 18));
                },
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  dealCards(3); // 다시 배분
                });
              },
              child: const Text('Deal Again'),
            )
          ],
        ),
      ),
    );
  }
}
