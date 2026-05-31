#!/usr/bin/env bash
# Bash adaptation of the original C+Criterion test suite.
# Original: VestaManuyko/Cub3D_tester
# Replaces libcriterion with a portable bash test runner.
# Usage: bash test.sh [binary_path]

set -uo pipefail

DIR="$(cd "$(dirname "$0")" && pwd)"
BINARY="${1:-"$DIR/../../cub3D"}"

if [ ! -x "$BINARY" ]; then
	echo "Error: binary not found or not executable: $BINARY" >&2
	exit 1
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

PASS=0
FAIL=0

# Valid map: binary should start without parse error.
# timeout exit 124 = ran for full duration = PASS (windowed app, no user input to quit).
# Any other non-zero immediate exit = crash / parse error = FAIL.
run_valid()
{
	local label="$1"
	local map="$2"
	timeout 3s xvfb-run -a "$BINARY" "$map" >/dev/null 2>&1
	local code=$?
	if [ "$code" -eq 124 ] || [ "$code" -eq 0 ]; then
		printf "  ${GREEN}PASS${NC} valid/%s\n" "$label"
		PASS=$((PASS + 1))
	else
		printf "  ${RED}FAIL${NC} valid/%s (exit %d)\n" "$label" "$code"
		FAIL=$((FAIL + 1))
	fi
}

# Invalid map: binary must exit non-zero and print "Error" as first stderr line.
run_invalid()
{
	local label="$1"
	shift
	local stderr_out
	stderr_out="$(mktemp)"
	"$BINARY" "$@" >/dev/null 2>"$stderr_out"
	local code=$?
	local first_line
	first_line="$(head -1 "$stderr_out")"
	rm -f "$stderr_out"
	if [ "$code" -eq 0 ]; then
		printf "  ${RED}FAIL${NC} invalid/%s (exit should not be 0)\n" "$label"
		FAIL=$((FAIL + 1))
	elif [ "$first_line" != "Error" ]; then
		printf "  ${RED}FAIL${NC} invalid/%s (stderr should start with 'Error', got '%s')\n" \
			"$label" "$first_line"
		FAIL=$((FAIL + 1))
	else
		printf "  ${GREEN}PASS${NC} invalid/%s\n" "$label"
		PASS=$((PASS + 1))
	fi
}

echo "=== Valid maps ==="
run_valid "hidden_a_file (.a.cub)"          "$DIR/maps/valid/.a.cub"
run_valid "hidden_cub_file (.cub.cub)"      "$DIR/maps/valid/.cub.cub"
run_valid "double_xpm_extension"            "$DIR/maps/valid/double_xpm_extension.cub"
run_valid "leading_zero_in_colour"          "$DIR/maps/valid/leading_zero_in_colour.cub"
run_valid "multiple_extensions.cub.cub"     "$DIR/maps/valid/multiple_extensions.cub.cub"
run_valid "nl_between_info"                 "$DIR/maps/valid/nl_between_info.cub"
run_valid "subject_minimal_map"             "$DIR/maps/valid/subject_minimal.cub"
run_valid "big_map"                         "$DIR/maps/valid/big_map.cub"
run_valid "elements_in_mixed_order"         "$DIR/maps/valid/elements_in_mixed_order.cub"
run_valid "colours_at_max_boundary"         "$DIR/maps/valid/colours_at_max_boundary.cub"
run_valid "colours_at_min_boundary"         "$DIR/maps/valid/colours_at_min_boundary.cub"
run_valid "map_with_spaces"                 "$DIR/maps/valid/map_with_spaces.cub"
run_valid "rectangular_map"                 "$DIR/maps/valid/rectangular.cub"
run_valid "space_in_filename"               "$DIR/maps/valid/space in filename.cub"
run_valid "space_in_texture"                "$DIR/maps/valid/space_in_texture.cub"
run_valid "diagonal_wall_edge"              "$DIR/maps/valid/diagonal_wall_edge.cub"

echo ""
echo "=== Invalid maps ==="
run_invalid "wrong_xpm_extension"              "$DIR/maps/invalid/invalid_xpm_extension.cub"
run_invalid "file_doesnt_exist"                "$DIR/no.cub"
run_invalid "empty_file"                       "$DIR/maps/invalid/empty.cub"
run_invalid "no_map"                           "$DIR/maps/invalid/no_map.cub"
run_invalid "wrong_extension_cubb"             "$DIR/maps/invalid/invalid_extension.cubbb"
run_invalid "no_args"
run_invalid "empty_arg"                        ""
run_invalid "hidden_file_in_folder"            "$DIR/maps/invalid/.cub"
run_invalid "hidden_file"                      "$DIR/.cub"
run_invalid "empty_xpm_file"                   "$DIR/maps/invalid/empty_xpm_file.cub"
run_invalid "linked_hidden_file_xpm"           "$DIR/maps/invalid/link_xpm_file.cub"
run_invalid "invalid_char_in_map"              "$DIR/maps/invalid/invalid_char_in_map.cub"
run_invalid "wrong_extension_txt"              "$DIR/maps/invalid/invalid_extension.txt"
run_invalid "misplaced_info"                   "$DIR/maps/invalid/misplaced_info.cub"
run_invalid "missing_texture"                  "$DIR/maps/invalid/missing_texture.cub"
run_invalid "only_map"                         "$DIR/maps/invalid/only_map.cub"
run_invalid "player_out_of_map"                "$DIR/maps/invalid/player_out_of_map.cub"
run_invalid "random_content"                   "$DIR/maps/invalid/random_content.cub"
run_invalid "space_in_colour"                  "$DIR/maps/invalid/space_in_color.cub"
run_invalid "blank_line_in_map"                "$DIR/maps/invalid/blank_line_in_map.cub"
run_invalid "multiple_maps"                    "$DIR/maps/invalid/multiple_maps.cub"
run_invalid "random_word_arg"                  "lalalala"
run_invalid "multiple_map_args" \
	"$DIR/maps/valid/subject_minimal.cub" "$DIR/maps/valid/subject_minimal.cub"
run_invalid "multiple_map_args_in_one_arg" \
	"$DIR/maps/valid/subject_minimal.cub $DIR/maps/valid/subject_minimal.cub"
run_invalid "extra_commas_in_colour"           "$DIR/maps/invalid/extra_commas_in_colour.cub"
run_invalid "out_of_range_rgb_value"           "$DIR/maps/invalid/out_of_range_rgb_value.cub"
run_invalid "empty_rgb_value"                  "$DIR/maps/invalid/empty_rgb_value.cub"
run_invalid "no_space_after_element_colour"    "$DIR/maps/invalid/no_space_after_element_colour.cub"
run_invalid "no_space_after_element_texture"   "$DIR/maps/invalid/no_space_after_element_texture.cub"
run_invalid "negative_rgb_value"               "$DIR/maps/invalid/negative_rgb_value.cub"
run_invalid "overflow_rgb_value"               "$DIR/maps/invalid/overflow_rgb_value.cub"
run_invalid "no_player"                        "$DIR/maps/invalid/no_player.cub"
run_invalid "multiple_players"                 "$DIR/maps/invalid/multiple_players.cub"
run_invalid "map_unclosed_on_top"              "$DIR/maps/invalid/map_unclosed_on_top.cub"
run_invalid "map_unclosed_on_bottom"           "$DIR/maps/invalid/map_unclosed_on_bottom.cub"
run_invalid "unclosed_map_edge_case"           "$DIR/maps/invalid/unclosed_map_edge_case.cub"
run_invalid "map_unclosed_left"                "$DIR/maps/invalid/map_unclosed_left.cub"
run_invalid "map_unclosed_right"               "$DIR/maps/invalid/map_unclosed_right.cub"
run_invalid "missing_colour"                   "$DIR/maps/invalid/missing_colour.cub"
run_invalid "more_rgb_values_in_colour"        "$DIR/maps/invalid/more_rgb_values_in_colour.cub"
run_invalid "less_rgb_values_in_colour"        "$DIR/maps/invalid/less_rgb_values_in_colour.cub"
run_invalid "non_numeric_colour_component"     "$DIR/maps/invalid/non_numeric_colour_component.cub"
run_invalid "double_texture"                   "$DIR/maps/invalid/double_texture.cub"
run_invalid "unknown_texture_identifier"       "$DIR/maps/invalid/unknown_texture_identifier.cub"

echo ""
TOTAL=$((PASS + FAIL))
echo "Results: $PASS/$TOTAL passed"
if [ "$FAIL" -eq 0 ]; then
	echo "All tests passed!"
	exit 0
else
	exit 1
fi
