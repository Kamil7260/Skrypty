import sys

def evaluate_board(board):
    winning_combinations = [(0, 1, 2), (3, 4, 5), (6, 7, 8),
                            (0, 3, 6), (1, 4, 7), (2, 5, 8),
                            (0, 4, 8), (2, 4, 6)]

    for (x, y, z) in winning_combinations:
        if board[x] == board[y] == board[z] == 'O':
            return 10
        if board[x] == board[y] == board[z] == 'X':
            return -10

    return 0

def is_moves_left(board):
    return any(s not in ['X', 'O'] for s in board)

def minmax(board, depth, is_maximizing_player):
    score = evaluate_board(board)

    if score == 10 or score == -10:
        return score

    if not is_moves_left(board):
        return 0

    if is_maximizing_player:
        best = -float('inf')

        for i in range(len(board)):
            if board[i] not in ['X', 'O']:
                board[i] = 'O'
                best = max(best, minmax(board, depth + 1, False))
                board[i] = str(i + 1)

        return best
    else:
        best = float('inf')

        for i in range(len(board)):
            if board[i] not in ['X', 'O']:
                board[i] = 'X'
                best = min(best, minmax(board, depth + 1, True))
                board[i] = str(i + 1)

        return best

def best_move(board):
    best_val = -float('inf')
    best_move = -1

    for i in range(len(board)):
        if board[i] not in ['X', 'O']:
            board[i] = 'O'
            move_val = minmax(board, 0, False)
            board[i] = str(i + 1)

            if move_val > best_val:
                best_val = move_val
                best_move = i

    return best_move

if __name__ == "__main__":
    current_board = sys.argv[1].split(',')
    move = best_move(current_board)
    print(move)