#!/bin/bash
#
# Utility linux-gnu Bash functions.
# Fonctions means functions in french.
# Any question?
# Ask me at lpenaud@zaclys.net
#

########################################################################
# Call xdg-open to open file by the user default software.
# Arguments:
#   File to open
########################################################################
function open () {
  xdg-open $@
}

########################################################################
# Print the graphical user clipboard content.
# Outputs:
#   Graphical user clipboard content to STDOUT.
########################################################################
function clipout () {
  xclip -selection clipboard -out
}

########################################################################
# Put contents into the graphical user clipboard.
# Inputs:
#   Read STDIN to put it in the graphical user clipboard.
########################################################################
function clipin () {
  xclip -selection clipboard -in
}

fonction::test_impl xdg-open xclip
