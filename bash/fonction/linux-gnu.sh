#!/bin/bash

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
