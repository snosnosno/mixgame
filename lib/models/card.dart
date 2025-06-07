enum Rank {
  two,
  three,
  four,
  five,
  six,
  seven,
  eight,
  nine,
  ten,
  jack,
  queen,
  king,
  ace
}

enum Suit { spades, hearts, diamonds, clubs }

class Card {
  final Rank rank;
  final Suit suit;

  Card(this.rank, this.suit);

  factory Card.fromString(String cardStr) {
    if (cardStr.length < 2) throw Exception('Invalid card string');

    String rankStr = cardStr.substring(0, cardStr.length - 1);
    String suitStr = cardStr.substring(cardStr.length - 1);

    Rank rank;
    switch (rankStr) {
      case 'A':
        rank = Rank.ace;
        break;
      case 'K':
        rank = Rank.king;
        break;
      case 'Q':
        rank = Rank.queen;
        break;
      case 'J':
        rank = Rank.jack;
        break;
      case '10':
        rank = Rank.ten;
        break;
      default:
        rank = Rank.values[int.parse(rankStr) - 2];
    }

    Suit suit;
    switch (suitStr) {
      case 'S':
        suit = Suit.spades;
        break;
      case 'H':
        suit = Suit.hearts;
        break;
      case 'D':
        suit = Suit.diamonds;
        break;
      case 'C':
        suit = Suit.clubs;
        break;
      default:
        throw Exception('Invalid suit');
    }

    return Card(rank, suit);
  }
}
