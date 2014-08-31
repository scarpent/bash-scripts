#!/bin/bash

 usage="\nfindr.sh: Helper to make regex find commands easier.\n\n"
usage+="  usage: findr.sh [-a] [-ec] [-n] [-p] [-s] [find args] expression\n\n"
usage+="\t-a\tsearch all filesystems (default is -xdev/-mount)\n"
usage+="\t-n\tadd line numbers to results\n"
usage+="\t-p\tpreview mode; just show the resulting find command\n"
usage+="\t-s\tsave results to ~/.findr_results (w/o line numbers)\n"

usage+="\n\t\tyou can't combine params as you do, e.g. -ap,"
usage+="\n\t\t*except* for in the funny business to follow:\n"

usage+="\n\t-cN\tcopy only line number N of results to clipboard;\n"
usage+="\t\tusing mac osx pbcopy\n"
usage+="\t-eN\techo only line number N of results\n"

usage+="\n\t\t-c copy or -e echo only line number N of results,\n"
usage+="\t\tfrom ~/.findr_results if it exists and no regex is\n"
usage+="\t\tprovided, otherwise from a new search\n"

usage+="\n\t\tyou can combine these params, e.g. -ec2, but -c will\n"
usage+="\t\talways echo so that the e is unnecessary; N must be\n"
usage+="\t\tadded with no preceding space, but can be ommitted\n"
usage+="\t\tfor a default value of 1\n"

usage+="\n\t\t-c or -e will suppress line numbers and saving to\n"
 usage+="\t\t~/.findr_results, even if -n or -s is specified\n"

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
    elif [[ "$1" =~ ^-(e?c|ce?|ec?|c?e)([0-9]+)?$ ]]; then
        if [[ "$1" =~ e ]]; then
            line_echo=true
        fi
        if [[ "$1" =~ c ]]; then
            line_to_clipboard=true
        fi
        line_number=$(echo "$1" | sed 's/[^0-9]//g')
        if [[ "$line_number" =~ ^$|0+ ]]; then
            line_number=1
        fi
    elif [[ $# -eq 1 ]]; then
        regex=$1
    else
        args+=" $1"
    fi
    shift
done

function echo_copy_result {
    echo $result
    if [[ "$line_to_clipboard" == "true" ]]; then
        # -n to suppress newline
        echo -n "$result" | pbcopy
    fi
}

if [[ "$line_echo" == "true" || "$line_to_clipboard" == "true" ]]; then
    # printf to suppress newline when copying to clipboard
    awk_param="NR==$line_number {printf}"

    if [[ -e "$results_file" && "$regex" == "" ]]; then
        result=$(awk "$awk_param" "$results_file")
        echo_copy_result
        exit 0
    fi
fi

# reminder: adding $regex to $args didn't seem to work right
args+="${xdev}-regextype posix-egrep -iregex"
regex="^.*${regex}[^/]*$"

if [[ "$preview" == "true" ]]; then
    echo "find $args ""'""$regex""'" >&2
elif [[ "$line_echo" == "true" || "$line_to_clipboard" == "true" ]]; then
    result=$(find $args "$regex" | awk "$awk_param")
    echo_copy_result
elif [[ "$print_line_numbers" == "false" && "$save_results" == "false" ]]; then
    find $args "$regex"
elif [[ "$print_line_numbers" == "true" && "$save_results" == "false" ]]; then
    find $args "$regex" | nl -n rn -w4 -s" "
elif [[ "$print_line_numbers" == "false" && "$save_results" == "true" ]]; then
    find $args "$regex" | tee $results_file
else  # save to file and print line numbers
    find $args "$regex" | tee $results_file | nl -n rn -w4 -s" "
fi
