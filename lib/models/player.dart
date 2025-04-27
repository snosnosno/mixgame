enum Position { dealer, smallBlind, bigBlind, underTheGun, hijack, cutoff }

class Player {
  String name;
  int chips;
  List<String> hand;
  bool isFolded;
  bool isAllIn;
  int bet;
  Position position;

  Player({
    required this.name,
    required this.chips,
    required this.hand,
    required this.position,
    this.isFolded = false,
    this.isAllIn = false,
    this.bet = 0,
  });

  String get positionName {
    switch (position) {
      case Position.smallBlind:
        return 'SB';
      case Position.bigBlind:
        return 'BB';
      case Position.underTheGun:
        return 'UTG';
      case Position.dealer:
        return 'DEALER';
      case Position.hijack:
        return 'HIJACK';
      case Position.cutoff:
        return 'CO';
    }
  }
}
