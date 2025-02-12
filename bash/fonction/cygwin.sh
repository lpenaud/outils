#!/bin/bash
#
# Utility linux-gnu Bash functions.
# Fonctions means functions in french.
# Any question?
# Ask me at lpenaud@zaclys.net
#

########################################################################
# Call Windows explorer to open file by the user default software.
# Arguments:
#   File to open
########################################################################
function open () {
  explorer.exe "${@}"
}

########################################################################
# Print the graphical user clipboard content.
# Outputs:
#   Graphical user clipboard content to STDOUT.
########################################################################
function clipout () {
  cat /dev/clipboard
}

########################################################################
# Put contents into the graphical user clipboard.
# Inputs:
#   Read STDIN to put it in the graphical user clipboard.
########################################################################
function clipin () {
  if [ $# -eq 0 ]; then
    cat - > /dev/clipboard
    return
  fi
  cat "${@}" > /dev/clipboard
}

