class Player {
  String name;
  int chips;
  List<String> hand;
  bool isFolded;
  bool isAllIn;
  int bet;

  Player({
    required this.name,
    required this.chips,
    required this.hand,
    this.isFolded = false,
    this.isAllIn = false,
    this.bet = 0,
  });
}
