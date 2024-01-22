#!/bin/bash
#
# Pure Bash utilities to merge CSV files.
#

########################################################################
# Merge all csv files.
# Omit the first line of every file except the first,
# so the csv header is not repeated.
# Arguments:
#  Input CSV files...
# Outputs:
#  Empty string if no input files otherwise the csv lines.
########################################################################
function csv::merge () {
  if [ $# -eq 0 ]; then
    return 0
  fi
  csv::header "${1}"
  while [ $# -ne 0 ]; do
    csv::records "${1}"
    shift
  done
}

########################################################################
# Print only the first line.
# Arguments:
#  Input CSV file.
# Outputs:
#  First line of the file.
########################################################################
function csv::header () {
  local -a records
  mapfile -t -n 1 records < "${1}"
  printf "%s\n" "${records[@]}"
}

########################################################################
# Print all files expect the first one.
# Arguments:
#  Input CSV file.
# Outputs:
#  All lines expect the first one.
########################################################################
function csv::records () {
  local -a records
  mapfile -t -s 1 records < "${1}"
  printf "%s\n" "${records[@]}"
}
