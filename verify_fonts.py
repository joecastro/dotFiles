#!/usr/bin/env python3

import sys

# Inspired by https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/bin/scripts/test-fonts.sh

RESET_COLOR = '\033[0m'
BG_COLOR_BORDER = '\033[48;5;8m'

EMOJI_TESTSET = sorted([
    '😀', '😁', '😂', '😃', '😅', '😆', '😉', '😊', '😋', '😎', '😍', '😘', '😗', '😙', '😚', '🙂',
    '🤩', '🥳', '😇', '🤠', '🤡', '🤥', '🤫', '🤭', '🧐', '🤓', '😈', '👿', '👹', '👺', '💀', '👻',
    '👽', '👾', '🤖', '💩', '😺', '😸', '😹', '😻', '😼', '😽', '🙀', '😿', '😾', '🙈', '🙉', '🙊',
    '💋', '💌', '💘', '💝', '💖', '💗', '💓', '💞', '💕', '💟', '💔', '🧡', '💛', '💚', '💙', '💜',
    '🤎', '🖤', '🤍', '💯', '💢', '💥', '💫', '💦', '💨', '💣', '💬', '💭',
    '💤', '🤗', '🤔', '😐', '😑', '😶', '🙄', '😏', '😣', '😥', '😮', '🤐', '😯', '😪', '😫', '😴',
    '😌', '😛', '😜', '😝', '🤤', '😒', '😓', '😔', '😕', '🙃', '🤑', '😲', '🙁', '😖', '😞', '😟',
    '😤', '😢', '😭', '😦', '😧', '😨', '😩', '🤯', '😬', '😰', '😱', '😳', '🤪', '😵', '😡', '😠',
    '🤬', '😷', '🤒', '🤕', '🤢', '🤮', '🤧'
], key=ord)

NF_EXAMPLAR_TESTSET = ['', '', '', '', '', '󰀲', '', '', '', '', '󱂵', '']
NF_CHESS_TESTSET = ['♚', '♛', '♜', '♝', '♞', '♟', '♔', '♕', '♖', '♗', '♘', '♙']

CELL_WIDTH = 6
HALF_BAR = '═' * (int)(CELL_WIDTH / 2)

def print_top_line(length):
    top_line_start = f'{BG_COLOR_BORDER}╔{HALF_BAR}'
    top_line_middle = f'{HALF_BAR}╦{HALF_BAR}'
    top_line_end = f'{HALF_BAR}╗{RESET_COLOR}'

    print(top_line_start + (top_line_middle * (length - 1)) + top_line_end)


def print_bottom_line(length):
    bottom_line_start = f'{BG_COLOR_BORDER}╚{HALF_BAR}'
    bottom_line_middle = f'{HALF_BAR}╩{HALF_BAR}'
    bottom_line_end = f'{HALF_BAR}╝{RESET_COLOR}'

    print(bottom_line_start + (bottom_line_middle * (length - 1)) + bottom_line_end)


def print_middle_line(length, next_line_length):
    line_start = f'{BG_COLOR_BORDER}╠{HALF_BAR}'
    line_middle = f'{HALF_BAR}╬{HALF_BAR}'
    line_end = f'{HALF_BAR}╣{RESET_COLOR}'

    bottom_line_middle = f'{HALF_BAR}╩{HALF_BAR}'
    bottom_line_end = f'{HALF_BAR}╝{RESET_COLOR}'

    if next_line_length == length:
        print(line_start + (line_middle * (length - 1)) + line_end)
    else:
        print(line_start + (line_middle * next_line_length), end='')
        print((bottom_line_middle * (length - next_line_length - 1)) + bottom_line_end)


def print_codes_line(code_color, char_color, chunk, line_length):
    vertical_bar = f'{BG_COLOR_BORDER}║{RESET_COLOR}'
    underline = '\033[4m'

    header_line = [(f'{n:x}', chr(n)) for n in chunk]
    # add fillers to array to maintain table:
    header_line.extend([('', ' ')] * (line_length - len(chunk)))

    all_codes = vertical_bar
    all_chars = vertical_bar
    for (code, char) in header_line:
        leftpad_code = (int)((CELL_WIDTH - len(code)) / 2)
        rightpad_code = CELL_WIDTH - len(code) - leftpad_code
        # Emoji characters print with variable width in different fonts,
        # but generally it works to treat them as double-wide.
        char_width = 2 if char in EMOJI_TESTSET else 1
        leftpad_char = (int)((CELL_WIDTH - char_width) / 2)
        rightpad_char = CELL_WIDTH - char_width - leftpad_char
        all_codes += f'{code_color}{" " * (leftpad_code)}{underline}{code}{RESET_COLOR}{code_color}{" " * rightpad_code}{vertical_bar}'
        all_chars += f'{char_color}{" " * leftpad_char}{char}{" " * rightpad_char}{vertical_bar}'

    print(f'{all_codes}\n{all_chars}')


# Given a range of numbers print all unicode code-points.
def print_unicode_range(seq, wrap_at=16):
    # Use alternating colors to see which symbols extend outside the bounding boxes.
    bg_color_code_alt = '\033[48;5;246m'
    bg_color_code = '\033[48;5;240m'
    bg_color_char_alt = '\033[48;5;66m'
    bg_color_char = '\033[48;5;60m'

    sequence = []
    sequence.extend(seq)

    chunked_sequences = [sequence[i * wrap_at:(i + 1) * wrap_at]
                         for i in range((len(sequence) + wrap_at - 1) // wrap_at)]

    # If there's only one line, then let the table display narrower
    line_length = len(chunked_sequences[0])

    print_top_line(line_length)

    color_code = bg_color_code_alt
    color_char = bg_color_char_alt
    first = True

    for chunk in chunked_sequences:
        if first:
            first = False
        else:
            print_middle_line(line_length, len(chunk))

        if color_code == bg_color_code_alt:
            color_code = bg_color_code
            color_char = bg_color_char
        else:
            color_code = bg_color_code_alt
            color_char = bg_color_char_alt

        print_codes_line(color_code, color_char, chunk, len(chunk))

    print_bottom_line(len(chunked_sequences[-1]))


def list_to_ranges(lst):
    if len(lst) % 2 != 0:
        raise ValueError('This is expected to be an even number of items')
    ranges = []
    for previous, current in zip(lst[::2], lst[1::2]):
        ranges.extend([i for i in range(previous, current)])
    return ranges


def convert_symbols_to_ranges(symbols):
    filtered_symbols = [c for c in symbols if len(c) == 1]
    if len(filtered_symbols) != len(symbols):
        print(f'Warning: {len(symbols) - len(filtered_symbols)} symbols were filtered out')
        print(f'Filtered out symbols: {", ".join([c for c in symbols if len(c) != 1])}')
    return list(sum([(ord(c), ord(c)+1) for c in filtered_symbols], ()))


def main():
    categories = {
        # 'ASCII control codes': [0, 32, 127, 128],
        'ASCII': [32, 127],
        'Emoji': convert_symbols_to_ranges(EMOJI_TESTSET),
        'Nerd Fonts - Pomicons': [0xe000, 0xe00a],
        'Nerd Fonts - Powerline + Extras': [0xe0a0, 0xE0A4, 0xE0B0, 0xE0C0, 0xE0C0, 0xE0C9, 0xE0CC, 0xE0D0, 0xE0D0, 0xE0D3, 0xE0D4, 0xe0d5, 0xE0D6, 0xE0D8],
        'Nerd Fonts - Symbols original': [0xe5fa, 0xe62c],
        # 198 icons
        'Nerd Fonts - Devicons': [0xe700, (0xe700 + 198)],
        'Nerd Fonts - Font awesome': [0xf000, 0xf2e1],
        'Nerd Fonts - Font awesome extension': [0xe200, 0xe2aa],
        'Nerd Fonts - Octicons': [0xf400, 0xf4a9, 0x2665, 0x2666, 0x26A1, 0x26A2, 0xf27c, 0xf27d],
        'Nerd Fonts - Font Logos': [0xf300, 0xf330],
        'Nerd Fonts - Font Power Symbols': [0x23fb, 0x23ff, 0x2b58, 0x2b59],
        'Nerd Fonts - Material Design Icons (first few)': [0xf0001, 0xf0031],
        # 228 icons
        'Nerd Fonts - Weather Icons': [0xe300, (0xe300 + 228)],
        'Nerd Fonts - Chess Icons': [0xed5f, 0xed67, 0xe29c, 0xe29d, 0xe25f, 0xe264, 0xf0857, 0xf085d],
        'Nerd Fonts - ZSH Prompt Icons': convert_symbols_to_ranges(NF_EXAMPLAR_TESTSET)
    }

    for name, range_list in categories.items():
        print(name)
        print_unicode_range(list_to_ranges(range_list))
        print()

    return 0


if __name__ == "__main__":
    sys.exit(main())
