#!/usr/bin/env bash

set -euo pipefail

verbose=0
source=""
webhook=""
retention=7
dest=""

Usage() {
    echo "Usage: ${0##*/} -s SOURCE -d DEST -r RETENTION -w WEBHOOK [-v]"
}

while getopts "s:d:r:w:vh" opt; do
 case "$opt" in
 s) source="$OPTARG" ;;
 d) dest="$OPTARG" ;;
 r) retention="$OPTARG" ;;
 w) webhook="$OPTARG" ;;
 v) verbose=1 ;;
 h) Usage; exit 0 ;;
 *) Usage >&2; exit 1 ;;
 esac
done
if [ -z "$source" ] || [ -z "$dest" ] || [ -z "$retention" ]; then
  Usage >&2
 exit 1
fi

if [[ ! "$retention" =~ ^[0-9]+$ ]]; then
  echo "Retention must be an integer" >&2
exit 1
fi

if [[ ! -d "$source" ]]; then
  echo "Source directory does not exist" >&2

  exit 1
fi  

mkdir -p "$dest"