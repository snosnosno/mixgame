class ScoreSystem {
  Map<int, int> scores = {
    2: 0,
    3: 0,
    4: 0,
    5: 0,
    6: 0,
  };

  Map<int, int> highScores = {
    2: 0,
    3: 0,
    4: 0,
    5: 0,
    6: 0,
  };

  Map<int, int> attempts = {
    2: 0,
    3: 0,
    4: 0,
    5: 0,
    6: 0,
  };

  bool addScore(int playerCount, int score) {
    if (scores.containsKey(playerCount)) {
      scores[playerCount] = scores[playerCount]! + 1;

      if (score > (highScores[playerCount] ?? 0)) {
        highScores[playerCount] = score;
        return true;
      }
    }
    return false;
  }

  void addAttempt(int playerCount) {
    if (attempts.containsKey(playerCount)) {
      attempts[playerCount] = attempts[playerCount]! + 1;
    }
  }

  int getScore(int playerCount) {
    return scores[playerCount] ?? 0;
  }

  int getHighScore(int playerCount) {
    return highScores[playerCount] ?? 0;
  }

  double getAccuracy(int playerCount) {
    int totalAttempts = attempts[playerCount] ?? 0;
    if (totalAttempts == 0) return 0.0;
    int correctAnswers = getScore(playerCount);
    return (correctAnswers / totalAttempts) * 100;
  }

  void reset() {
    scores = {
      2: 0,
      3: 0,
      4: 0,
      5: 0,
      6: 0,
    };
    attempts = {
      2: 0,
      3: 0,
      4: 0,
      5: 0,
      6: 0,
    };
  }
}
