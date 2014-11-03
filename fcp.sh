#!/bin/bash

# works with cached results of findr.sh, using gitsel.sh parsing

fcp() {
    # replace non-numbers with spaces, trim, and replace spaces with | separators
    # so will end up with single # or a group of #s like 2|3|1
    the_numbers=$(echo "$@" | sed -r -e 's/[^0-9]/ /g' -e 's/^\s+|\s+$//g' -e 's/\s+/|/g')
    # no number means all numbers
    if [[ "$the_numbers" == "" ]]; then
        the_numbers="[0-9]+"  # all files
    fi
    files=$(nl -n rn -w6 -s" " ~/.findr_results | egrep "^\s+(${the_numbers})\s" | cut -c10- | paste -d" " -s)
    echo -e "$files"
    echo -n "$files" | pbcopy  # pbcopy is a mac osx the_command
}