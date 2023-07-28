#!/usr/bin/python

import sys

# Inspired by https://raw.githubusercontent.com/ryanoasis/nerd-fonts/master/bin/scripts/test-fonts.sh

reset_color = '\033[0m'
bg_color_border = '\033[48;5;8m'


def print_top_line(length):
    top_line_start = f'{bg_color_border}╔═══'
    top_line_middle = "═══╦═══"
    top_line_end = f'═══╗{reset_color}'

    print(top_line_start + (top_line_middle * (length - 1)) + top_line_end)


def print_bottom_line(length):
    bottom_line_start = f'{bg_color_border}╚═══'
    bottom_line_middle = '═══╩═══'
    bottom_line_end = f'═══╝{reset_color}'

    print(bottom_line_start + (bottom_line_middle * (length - 1)) + bottom_line_end)


def print_middle_line(length):
    line_start = f'{bg_color_border}╠═══'
    line_middle = '═══╬═══'
    line_end = f'═══╣{reset_color}'

    print(line_start + (line_middle * (length - 1)) + line_end)


def print_codes_line(code_color, char_color, chunk, line_length):
    bar = f'{bg_color_border}║{reset_color}'
    underline = '\033[4m'

    header_line = [(f'{n:x}', chr(n)) for n in chunk]
    # add fillers to array to maintain table:
    header_line.extend([('', ' ')] * (line_length - len(chunk)))

    all_codes = bar
    all_chars = bar
    for (code, char) in header_line:
        all_codes += f'{code_color}{" " * (5 - len(code))}{underline}{code}{reset_color}{code_color} {bar}'
        all_chars += f'{char_color}  {char}   {bar}'

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
            print_middle_line(line_length)

        if color_code == bg_color_code_alt:
            color_code = bg_color_code
            color_char = bg_color_char
        else:
            color_code = bg_color_code_alt
            color_char = bg_color_char_alt

        print_codes_line(color_code, color_char, chunk, line_length)

    print_bottom_line(line_length)


def list_to_ranges(lst):
    if len(lst) % 2 != 0:
        raise ValueError('This is expected to be an even number of items')
    ranges = []
    for previous, current in zip(lst[::2], lst[1::2]):
        ranges.extend([i for i in range(previous, current)])
    return ranges


def main(args):
    categories = {
        'ASCII': [32, 128],
        'Nerd Fonts - Pomicons': [0xe000, 0xe00e],
        'Nerd Fonts - Powerline': [0xe0a0, 0xe0a3, 0xe0b0, 0xe0b4],
        'Nerd Fonts - Powerline Extra': [0xe0a3, 0xe0a4, 0xe0b4, 0xe0c9, 0xe0cc, 0xe0d3, 0xe0d4, 0xe0d5],
        'Nerd Fonts - Symbols original': [0xe5fa, 0xe62c],
        'Nerd Fonts - Devicons': [0xe700, 0xe7c6],
        'Nerd Fonts - Font awesome': [0xf000, 0xf2e1],
        'Nerd Fonts - Font awesome extension': [0xe200, 0xe2aa],
        'Nerd Fonts - Octicons': [0xf400, 0xf4a9, 0x2665, 0x2666, 0x26A1, 0x26A2, 0xf27c, 0xf27d],
        'Nerd Fonts - Font Logos': [0xf300, 0xf330],
        'Nerd Fonts - Font Power Symbols': [0x23fb, 0x23ff, 0x2b58, 0x2b59],
        'Nerd Fonts - Material Design Icons (first few)': [0xf0001, 0xf0011],
        'Nerd Fonts - Weather Icons': [0xe300, 0xe3ec]
    }

    for name, range_list in categories.items():
        print(name)
        print_unicode_range(list_to_ranges(range_list))
        print()

    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
