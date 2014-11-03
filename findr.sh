#!/bin/bash

 usage="\nfindr.sh: Helper to make regex find commands easier.\n\n"
usage+="  usage: findr.sh [-a] [-n] [-p] [-s] [find args] expression\n\n"
usage+="\t-a\tsearch all filesystems (default is -xdev/-mount)\n"
usage+="\t-n\tadd line numbers to results\n"
usage+="\t-p\tpreview mode; just show the resulting find command\n"
usage+="\t-s\tsave results to ~/.findr_results (w/o line numbers)\n"

usage+="\n\t\tyou can't combine params as you do, e.g. -ap\n"

# use line numbering and saving to ~/.findr_results with fcp bash function
# and: alias findr='findr.sh -n -s'

preview=false
# use "nowarn" to avoid warning, e.g. if -mount used after -type f
xdev="-nowarn -mount "
print_line_numbers=false
save_results=false
results_file=~/.findr_results
line_to_clipboard=false
line_echo=false
line_number=1s

# would like to use getopts, but need to "pass through" find options
while [ -n "$1" ]; do
    if [[ "$1" =~ -?-h(elp)? ]]; then
        echo -e $usage
        exit 0
    elif [[ "$1" == "-a" ]]; then
        xdev=""
    elif [[ "$1" == "-n" ]]; then
        print_line_numbers=true
    elif [[ "$1" == "-p" ]]; then
        preview=true
    elif [[ "$1" == "-s" ]]; then
        save_results=true
    elif [[ $# -eq 1 ]]; then
        regex=$1
    else
        args+=" $1"
    fi
    shift
done

# reminder: adding $regex to $args didn't seem to work right
args+="${xdev}-regextype posix-egrep -iregex"
regex="^.*${regex}[^/]*$"

if [[ "$preview" == "true" ]]; then
    echo "find $args ""'""$regex""'" >&2
elif [[ "$print_line_numbers" == "false" && "$save_results" == "false" ]]; then
    find $args "$regex"
elif [[ "$print_line_numbers" == "true" && "$save_results" == "false" ]]; then
    find $args "$regex" | nl -n rn -w4 -s" "
elif [[ "$print_line_numbers" == "false" && "$save_results" == "true" ]]; then
    find $args "$regex" | tee $results_file
else  # save to file and print line numbers
    find $args "$regex" | tee $results_file | nl -n rn -w4 -s" "
fi
