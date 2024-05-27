#!/bin/bash

board=(1 2 3 4 5 6 7 8 9)
turn_cnt=1
is_played=true

player_one_symbol="X"
player_two_symbol="O"
save_file="tictactoe_save.txt"

display_help() {
    echo "Gra w kółko i krzyżyk - Pomoc"
    echo "--------------------------------"
    echo "Opcje skryptu:"
    echo "-h, --help - Wyświetl pomoc"
    echo
    echo "Instrukcje gry:"
    echo "1. Wybierz tryb gry:"
    echo "   a. Tryb PvP (Gracz vs Gracz) - wpisz 1"
    echo "   b. Tryb vs PC (Gracz vs Komputer) - wpisz 2"
    echo "2. Podczas gry, wprowadzaj numer pola, aby postawić symbol ('X' lub 'O')."
    echo "3. Gra kończy się, gdy jeden z graczy wygrywa lub remisuje."
    echo "4. Możesz zapisać grę w dowolnym momencie wpisując 'save'."
    echo "5. Możesz wczytać poprzednio zapisaną grę wpisując 'load' na początku gry."
    echo
}

welcome() {
    clear
    echo "Witaj w grze kolko i krzyzyk."
    echo "1. Tryb PvP"
    echo "2. Tryb vs PC"
    echo "3. Wczytaj zapisaną grę"
}

show_board() {
    clear
    echo "${board[0]} | ${board[1]} | ${board[2]} |"
    echo "==========="
    echo "${board[3]} | ${board[4]} | ${board[5]} |"
    echo "==========="
    echo "${board[6]} | ${board[7]} | ${board[8]} |"
}

save_game() {
    echo "${board[*]}" > "$save_file"
    echo "$turn_cnt" >> "$save_file"
    echo "Gra została zapisana."
}

load_game() {
    if [ -f "$save_file" ]; then
        IFS=' ' read -r -a board < <(head -n 1 "$save_file")
        turn_cnt=$(tail -n 1 "$save_file")
        echo "Gra została wczytana."
    else
        echo "Brak zapisanego stanu gry."
        exit 1
    fi
}

check_win() {
    if [[ ${board[$1]} == ${board[$2]} ]] && [[ ${board[$2]} == ${board[$3]} ]]; then
        is_played=false
    fi

    if [[ $is_played == false ]]; then
        if [[ $((turn_cnt % 2)) == 0 ]]; then
            echo "Gracz 1 wygrywa!"
        else
            echo "Gracz 2 wygrywa!"
        fi
        exit
    fi
}

is_won() {
    if [ $is_played == false ]; then return; fi
    check_win 0 1 2
    check_win 3 4 5
    check_win 6 7 8
    check_win 0 4 8
    check_win 2 4 6
    check_win 0 3 6
    check_win 1 4 7
    check_win 2 5 8

    if [ $turn_cnt -gt 9 ]; then
        is_played=false
        echo "Remis!"
        exit
    fi
}

player_chooses() {
    if [[ $(($turn_cnt % 2)) == 0 ]]; then
        player_symbol=$player_two_symbol
        echo -n "Teraz wybiera gracz nr 2..."
    else
        echo -n "Teraz wybiera gracz nr 1..."
        player_symbol=$player_one_symbol
    fi

    read square

    if [ "$square" == "save" ]; then
        save_game
        player_chooses
        return
    fi

    space=${board[($square - 1)]}

    if (($square > 0)) && (($square < 10)); then
        if [[ $space == 'X' ]] || [[ $space == 'O' ]]; then
            echo "Zajeteanie!"
            player_chooses
            return
        fi
        board[($square - 1)]=$player_symbol
        ((turn_cnt = turn_cnt + 1))
    else
        echo "Cos nie tak kolego"
        player_chooses
        return
    fi

    space=${board[($square - 1)]}
}

minmax() {
    local current_directory="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    local board_string="${board[0]},${board[1]},${board[2]},${board[3]},${board[4]},${board[5]},${board[6]},${board[7]},${board[8]}"
    best_move=$(python3 "$current_directory/minmax.py" "$board_string")
    echo "$best_move"
}

player_vs_PC() {
    local square
    if [[ $(($turn_cnt % 2)) == 0 ]]; then
        player_symbol=$player_two_symbol
        echo "Ruch komputera..."
        square=$(minmax)
        ((square+=1))
    else
        player_symbol=$player_one_symbol
        echo -n "Teraz wybiera gracz nr 1... "
        read square
    fi

    if [ "$square" == "save" ]; then
        save_game
        player_vs_PC
        return
    fi

    space=${board[($square-1)]}

    if ((square >= 1 && square <= 9)); then
        if [[ $space == 'X' ]] || [[ $space == 'O' ]]; then
            echo "To pole jest już zajęte!"
            if [[ $player_symbol == $player_one_symbol ]]; then
                player_vs_PC
            fi
            return
        fi
        board[($square-1)]=$player_symbol
        ((turn_cnt=turn_cnt+1))
    else
        echo "Nieprawidłowy ruch, spróbuj ponownie."
        if [[ $player_symbol == $player_one_symbol ]]; then
            player_vs_PC
        fi
        return
    fi
}

main() {

    if [ "$1" == "-h" ] || [ "$1" == "--help" ]; then
        display_help
        exit 0
    fi

    welcome
    read choice
    if ((choice == 1)); then
        pvp_game
    elif ((choice == 2)); then
        pvc_game
    elif ((choice == 3)); then
        load_game
        if [ "$mode" == "pvp" ]; then
            pvp_game
        else
            pvc_game
        fi
    fi
}

pvp_game() {
    clear
    show_board
    while $is_played; do
        player_chooses
        show_board
        is_won
    done
}

pvc_game() {
    clear
    show_board
    while $is_played; do
        player_vs_PC
        show_board
        is_won
    done
}

main $1
