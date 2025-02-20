import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

/// The root widget that shows the main menu.
class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Tetris',
      theme: ThemeData.dark(),
      home: MainMenu(),
    );
  }
}

/// A simple main menu with buttons for Easy and Hard modes.
class MainMenu extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tetris Main Menu'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: Text('Shopping'),
                  content: Text('In-game shop coming soon!'),
                  actions: [
                    TextButton(
                      child: Text('Close'),
                      onPressed: () => Navigator.pop(context),
                    )
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Tetris', style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold)),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => TetrisGame(difficulty: 'Easy')));
              },
              child: Text('Start Easy Mode'),
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                Navigator.push(context, MaterialPageRoute(builder: (_) => TetrisGame(difficulty: 'Hard')));
              },
              child: Text('Start Hard Mode'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Your Tetris game widget modified to accept a difficulty parameter.
class TetrisGame extends StatefulWidget {
  final String difficulty;
  TetrisGame({Key? key, this.difficulty = 'Easy'}) : super(key: key);

  @override
  _TetrisGameState createState() => _TetrisGameState();
}

class _TetrisGameState extends State<TetrisGame> {
  static const int rowCount = 20; /// Number of rows in the game grid
  static const int colCount = 10; /// Number of columns in the game grid
  late List<List<int>> grid;
  late List<List<int>> currentTetromino; /// The currently falling tetromino shape
  late int currentRow, currentCol;
  Timer? _timer; /// Timer for controlling the automatic movement of tetrominoes
  bool isGameOver = false;
  int score = 0;
  int speed = 500;
  int money = 0; // Money the player has collected
  Color tetrominoColor = Colors.blue;
  late String difficulty; // Set from widget.difficulty
  Set<Point> collectedCoins = {}; // Set to keep track of collected coins

  @override
  void initState() {
    super.initState();
    difficulty = widget.difficulty; // Use the passed difficulty
    startNewGame();
  }

  void startNewGame() {
    setState(() {
      grid = List.generate(rowCount, (_) => List.filled(colCount, 0));
      isGameOver = false;
      score = 0;
      money = 0; /// Reset money on new game
      collectedCoins.clear(); /// Clear collected coins on new game
      _setSpeed(); /// Set the speed based on difficulty or other parameters
      spawnTetromino();
      if (_timer != null && _timer!.isActive) {
        _timer!.cancel(); /// Cancel the old timer if it's still running
      }
      _timer = Timer.periodic(Duration(milliseconds: speed), (timer) {
        moveDown();
      });
    });
  }

  void _setSpeed() {
    if (difficulty == 'Easy') {
      speed = 700; // Slower speed for Easy mode
    } else if (difficulty == 'Hard') {
      speed = 300; // Faster speed for Hard mode
    }
  }

  void spawnTetromino() {
    final tetrominos = [
      [[1, 1, 1], [0, 1, 0]], // T shape
      [[1, 1, 0], [0, 1, 1]], // Z shape
      [[0, 1, 1], [1, 1, 0]], // S shape
      [[1, 1], [1, 1]],       // O shape
      [[1, 1, 1, 1]],         // I shape
      [[1, 0, 0], [1, 1, 1]],  // L shape
      [[0, 0, 1], [1, 1, 1]],  // J shape
    ];
    final colors = [
      Colors.red, Colors.green, Colors.blue, Colors.yellow,
      Colors.orange, Colors.purple, Colors.cyan,
    ];
    final random = Random();
    final shapeIndex = random.nextInt(tetrominos.length);
    currentTetromino = tetrominos[shapeIndex];
    tetrominoColor = colors[shapeIndex];
    currentRow = 0;
    currentCol = colCount ~/ 2 - 1;
    drawTetromino();
    spawnCoin(); // Spawn one coin when Tetromino is placed
  }

  void drawTetromino() {
    setState(() {
      for (int r = 0; r < currentTetromino.length; r++) {
        for (int c = 0; c < currentTetromino[r].length; c++) {
          if (currentTetromino[r][c] == 1) {
            grid[currentRow + r][currentCol + c] = 2;
          }
        }
      }
    });
  }

  void moveDown() {
    if (isGameOver) return;
    setState(() {
      // Check for coin collection during movement
      _checkForCoinCollection();

      // Move the Tetromino down
      if (!canMove(currentRow + 1, currentCol)) {
        placeTetromino();
        clearFullRows();
        spawnTetromino();
        if (!canMove(currentRow, currentCol)) {
          isGameOver = true;
          _timer?.cancel();
        }
      } else {
        clearTetromino();
        currentRow++;
        drawTetromino();
      }
    });
  }

  void clearTetromino() {
    for (int r = 0; r < rowCount; r++) {
      for (int c = 0; c < colCount; c++) {
        if (grid[r][c] == 2) {
          grid[r][c] = 0;
        }
      }
    }
  }

  bool canMove(int row, int col) {
    for (int r = 0; r < currentTetromino.length; r++) {
      for (int c = 0; c < currentTetromino[r].length; c++) {
        if (currentTetromino[r][c] == 1) {
          int newRow = row + r;
          int newCol = col + c;
          if (newRow >= rowCount || newCol < 0 || newCol >= colCount || grid[newRow][newCol] == 1) {
            return false;
          }
        }
      }
    }
    return true;
  }

  void placeTetromino() {
    for (int r = 0; r < currentTetromino.length; r++) {
      for (int c = 0; c < currentTetromino[r].length; c++) {
        if (currentTetromino[r][c] == 1) {
          grid[currentRow + r][currentCol + c] = 1;
        }
      }
    }
  }

  void _checkForCoinCollection() {
    // Check if any part of the Tetromino overlaps with a coin
    for (int r = 0; r < currentTetromino.length; r++) {
      for (int c = 0; c < currentTetromino[r].length; c++) {
        if (currentTetromino[r][c] == 1) {
          int coinRow = currentRow + r;
          int coinCol = currentCol + c;

          if (coinRow >= 0 && coinRow < rowCount && coinCol >= 0 && coinCol < colCount) {
            // If there's a coin, collect it and increase money
            if (grid[coinRow][coinCol] == 3 && !collectedCoins.contains(Point(coinRow, coinCol))) {
              setState(() {
                money += 10; // Increase money by 10
                collectedCoins.add(Point(coinRow, coinCol)); // Mark coin as collected
                grid[coinRow][coinCol] = 0; // Remove the coin from the grid
              });
            }
          }
        }
      }
    }
  }

  void clearFullRows() {
    List<int> fullRows = [];
    for (int r = 0; r < rowCount; r++) {
      if (grid[r].every((cell) => cell == 1)) {
        fullRows.add(r);
      }
    }

    for (var row in fullRows) {
      grid.removeAt(row);
      grid.insert(0, List.filled(colCount, 0)); // Insert an empty row at the top
      score += 10; // Increment score for clearing a row
    }
  }

  void moveLeft() {
    setState(() {
      if (canMove(currentRow, currentCol - 1)) {
        clearTetromino();
        currentCol--;
        drawTetromino();
      }
    });
  }

  void moveRight() {
    setState(() {
      if (canMove(currentRow, currentCol + 1)) {
        clearTetromino();
        currentCol++;
        drawTetromino();
      }
    });
  }

  void rotate() {
    setState(() {
      List<List<int>> rotatedTetromino = List.generate(
          currentTetromino[0].length, (i) => List.filled(currentTetromino.length, 0));
      for (int r = 0; r < currentTetromino.length; r++) {
        for (int c = 0; c < currentTetromino[r].length; c++) {
          rotatedTetromino[c][currentTetromino.length - 1 - r] = currentTetromino[r][c];
        }
      }
      if (canMove(currentRow, currentCol)) {
        clearTetromino();
        currentTetromino = rotatedTetromino;
        drawTetromino();
      }
    });
  }

  void changeDifficulty(String mode) {
    setState(() {
      difficulty = mode;
      startNewGame(); // Restart the game with the new difficulty
    });
  }

  void spawnCoin() {
    // Spawn a single coin after a Tetromino is placed
    Random random = Random();
    int row = random.nextInt(rowCount);
    int col = random.nextInt(colCount);

    // Ensure the coin doesn't spawn on a filled cell or Tetromino
    while (grid[row][col] != 0) {
      row = random.nextInt(rowCount);
      col = random.nextInt(colCount);
    }

    grid[row][col] = 3; // Place a coin at the random location
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Tetris - Score: $score Money: $money'),
        actions: [
          IconButton(
            icon: Icon(Icons.shopping_cart),
            onPressed: () {
              // Shopping dialog example
              showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    title: Text('Shopping'),
                    content: Text('Here you can add in-game purchases or items.'),
                    actions: <Widget>[
                      TextButton(
                        child: Text('Close'),
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Difficulty selector inside game (optional)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () => changeDifficulty('Easy'),
                child: Text('Easy'),
              ),
              SizedBox(width: 10),
              ElevatedButton(
                onPressed: () => changeDifficulty('Hard'),
                child: Text('Hard'),
              ),
            ],
          ),
          Expanded(
            child: Center(
              child: GridView.builder(
                itemCount: rowCount * colCount,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: colCount,
                ),
                itemBuilder: (context, index) {
                  int row = index ~/ colCount;
                  int col = index % colCount;
                  return Container(
                    margin: EdgeInsets.all(1),
                    decoration: BoxDecoration(
                      color: grid[row][col] == 1 || grid[row][col] == 2
                          ? tetrominoColor
                          : grid[row][col] == 3
                          ? Colors.yellow // Coin color
                          : Colors.black,
                      shape: grid[row][col] == 3
                          ? BoxShape.circle // Make coin circular
                          : BoxShape.rectangle,
                    ),
                  );
                },
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(icon: Icon(Icons.arrow_left), onPressed: moveLeft),
              IconButton(icon: Icon(Icons.rotate_right), onPressed: rotate),
              IconButton(icon: Icon(Icons.refresh), onPressed: startNewGame),
              IconButton(icon: Icon(Icons.arrow_right), onPressed: moveRight),
            ],
          ),
        ],
      ),
    );
  }
}
