#!/bin/bash
case $1 in
    terminal)    v=terminal ;;
    filemanager) v=fileManager ;;
    browser)     v=browser ;;
    editor)      v=editor ;;
    *) exit 1 ;;
esac
grep -m1 "^local $v[[:space:]]*=" "$HOME/.config/hypr/conf/programs.lua" | sed 's/.*"\(.*\)".*/\1/'
