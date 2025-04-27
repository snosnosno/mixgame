import 'package:flutter_test/flutter_test.dart';
import 'package:random_card/main.dart';

void main() {
  group('Card Tests', () {
    test('Create card from string', () {
      final card = Card.fromString('AS');
      expect(card.rank, equals(Rank.ace));
      expect(card.suit, equals(Suit.spades));

      final card2 = Card.fromString('10H');
      expect(card2.rank, equals(Rank.ten));
      expect(card2.suit, equals(Suit.hearts));
    });

    test('Invalid card string throws exception', () {
      expect(() => Card.fromString('1X'), throwsException);
    });
  });

  group('HandRank Tests', () {
    test('Royal Straight Flush', () {
      final cards = [
        Card.fromString('AS'),
        Card.fromString('KS'),
        Card.fromString('QS'),
        Card.fromString('JS'),
        Card.fromString('10S'),
      ];
      final handRank = HandRank.evaluate(cards);
      expect(handRank.value, equals(10));
      expect(handRank.name, equals('Royal Straight Flush'));
    });

    test('Four of a Kind', () {
      final cards = [
        Card.fromString('AS'),
        Card.fromString('AH'),
        Card.fromString('AD'),
        Card.fromString('AC'),
        Card.fromString('2S'),
      ];
      final handRank = HandRank.evaluate(cards);
      expect(handRank.value, equals(8));
      expect(handRank.name, equals('Four of a Kind'));
    });

    test('High Card', () {
      final cards = [
        Card.fromString('AS'),
        Card.fromString('3H'),
        Card.fromString('5D'),
        Card.fromString('7C'),
        Card.fromString('9S'),
      ];
      final handRank = HandRank.evaluate(cards);
      expect(handRank.value, equals(1));
      expect(handRank.name, equals('High Card'));
    });
  });
} 