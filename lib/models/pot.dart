import 'player.dart';

class Pot {
  int total = 0;
  Map<Player, int> allInAmounts = {};

  void addBet(Player player, int amount) {
    total += amount;
    if (player.isAllIn) {
      allInAmounts[player] = amount;
    }
  }
} 