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
# Run from $DIR so relative texture paths (./textures/) resolve correctly.
# timeout exit 124 = ran for full duration = PASS (windowed app, no user input to quit).
# Any other non-zero immediate exit = crash / parse error = FAIL.
run_valid()
{
	local label="$1"
	local map="$2"
	(cd "$DIR" && timeout 3s xvfb-run -a "$BINARY" "$map") >/dev/null 2>&1
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
# Run from $DIR so relative texture paths resolve correctly.
run_invalid()
{
	local label="$1"
	shift
	local stderr_out
	stderr_out="$(mktemp)"
	(cd "$DIR" && "$BINARY" "$@") >/dev/null 2>"$stderr_out"
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
run_valid "hidden_a_file (.a.cub)"          "maps/valid/.a.cub"
run_valid "hidden_cub_file (.cub.cub)"      "maps/valid/.cub.cub"
run_valid "double_xpm_extension"            "maps/valid/double_xpm_extension.cub"
run_valid "leading_zero_in_colour"          "maps/valid/leading_zero_in_colour.cub"
run_valid "multiple_extensions.cub.cub"     "maps/valid/multiple_extensions.cub.cub"
run_valid "nl_between_info"                 "maps/valid/nl_between_info.cub"
run_valid "subject_minimal_map"             "maps/valid/subject_minimal.cub"
run_valid "big_map"                         "maps/valid/big_map.cub"
run_valid "elements_in_mixed_order"         "maps/valid/elements_in_mixed_order.cub"
run_valid "colours_at_max_boundary"         "maps/valid/colours_at_max_boundary.cub"
run_valid "colours_at_min_boundary"         "maps/valid/colours_at_min_boundary.cub"
run_valid "map_with_spaces"                 "maps/valid/map_with_spaces.cub"
run_valid "rectangular_map"                 "maps/valid/rectangular.cub"
run_valid "space_in_filename"               "maps/valid/space in filename.cub"
run_valid "space_in_texture"                "maps/valid/space_in_texture.cub"
run_valid "diagonal_wall_edge"              "maps/valid/diagonal_wall_edge.cub"

echo ""
echo "=== Invalid maps ==="
run_invalid "wrong_xpm_extension"              "maps/invalid/invalid_xpm_extension.cub"
run_invalid "file_doesnt_exist"                "no.cub"
run_invalid "empty_file"                       "maps/invalid/empty.cub"
run_invalid "no_map"                           "maps/invalid/no_map.cub"
run_invalid "wrong_extension_cubb"             "maps/invalid/invalid_extension.cubbb"
run_invalid "no_args"
run_invalid "empty_arg"                        ""
run_invalid "hidden_file_in_folder"            "maps/invalid/.cub"
run_invalid "hidden_file"                      ".cub"
run_invalid "empty_xpm_file"                   "maps/invalid/empty_xpm_file.cub"
run_invalid "linked_hidden_file_xpm"           "maps/invalid/link_xpm_file.cub"
run_invalid "invalid_char_in_map"              "maps/invalid/invalid_char_in_map.cub"
run_invalid "wrong_extension_txt"              "maps/invalid/invalid_extension.txt"
run_invalid "misplaced_info"                   "maps/invalid/misplaced_info.cub"
run_invalid "missing_texture"                  "maps/invalid/missing_texture.cub"
run_invalid "only_map"                         "maps/invalid/only_map.cub"
run_invalid "player_out_of_map"                "maps/invalid/player_out_of_map.cub"
run_invalid "random_content"                   "maps/invalid/random_content.cub"
run_invalid "space_in_colour"                  "maps/invalid/space_in_color.cub"
run_invalid "blank_line_in_map"                "maps/invalid/blank_line_in_map.cub"
run_invalid "multiple_maps"                    "maps/invalid/multiple_maps.cub"
run_invalid "random_word_arg"                  "lalalala"
run_invalid "multiple_map_args" \
	"maps/valid/subject_minimal.cub" "maps/valid/subject_minimal.cub"
run_invalid "multiple_map_args_in_one_arg" \
	"maps/valid/subject_minimal.cub maps/valid/subject_minimal.cub"
run_invalid "extra_commas_in_colour"           "maps/invalid/extra_commas_in_colour.cub"
run_invalid "out_of_range_rgb_value"           "maps/invalid/out_of_range_rgb_value.cub"
run_invalid "empty_rgb_value"                  "maps/invalid/empty_rgb_value.cub"
run_invalid "no_space_after_element_colour"    "maps/invalid/no_space_after_element_colour.cub"
run_invalid "no_space_after_element_texture"   "maps/invalid/no_space_after_element_texture.cub"
run_invalid "negative_rgb_value"               "maps/invalid/negative_rgb_value.cub"
run_invalid "overflow_rgb_value"               "maps/invalid/overflow_rgb_value.cub"
run_invalid "no_player"                        "maps/invalid/no_player.cub"
run_invalid "multiple_players"                 "maps/invalid/multiple_players.cub"
run_invalid "map_unclosed_on_top"              "maps/invalid/map_unclosed_on_top.cub"
run_invalid "map_unclosed_on_bottom"           "maps/invalid/map_unclosed_on_bottom.cub"
run_invalid "unclosed_map_edge_case"           "maps/invalid/unclosed_map_edge_case.cub"
run_invalid "map_unclosed_left"                "maps/invalid/map_unclosed_left.cub"
run_invalid "map_unclosed_right"               "maps/invalid/map_unclosed_right.cub"
run_invalid "missing_colour"                   "maps/invalid/missing_colour.cub"
run_invalid "more_rgb_values_in_colour"        "maps/invalid/more_rgb_values_in_colour.cub"
run_invalid "less_rgb_values_in_colour"        "maps/invalid/less_rgb_values_in_colour.cub"
run_invalid "non_numeric_colour_component"     "maps/invalid/non_numeric_colour_component.cub"
run_invalid "double_texture"                   "maps/invalid/double_texture.cub"
run_invalid "unknown_texture_identifier"       "maps/invalid/unknown_texture_identifier.cub"

echo ""
TOTAL=$((PASS + FAIL))
echo "Results: $PASS/$TOTAL passed"
if [ "$FAIL" -eq 0 ]; then
	echo "All tests passed!"
	exit 0
else
	exit 1
fi
