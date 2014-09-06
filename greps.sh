#!/bin/bash

usage="grep helper\n"
usage+="\nusage: greps [-Ilp] [-e dir] PATTERN\n\n"
usage+="searches on all files/dirs (*), so don't specify this\n\n"
usage+="options:\n"
usage+="\t-e\texclude dir\n"
usage+="\t-I\tcase sensitive search\n"
usage+="\t-l\tlist filename only\n"
usage+="\t-p\tshow path"

show_path=""
ignore_case="-i"
sedi="i" # sed ignore case
list_filenames_only=""
exclude_dirs=""
recursive="-R"

while getopts ":Ilpe:" opt
do
    case $opt in
        e  ) exclude_dirs+="--exclude-dir=$OPTARG "   ;;
        I  ) ignore_case=""; sedi=""                  ;;
        l  ) list_filenames_only="-l"                 ;;
        p  ) show_path="-p"                           ;;
        \? ) echo -e $usage
             exit 1
    esac
done
shift $(($OPTIND - 1))

#echo $ignore_case $sedi $list_filenames_only $show_path $exclude_dirs

if [[ "$1" == "" ]]; then
    echo -e $usage
    exit 1
fi

if [[ "$2" != "" ]]; then
    echo -e "there can be only one search pattern\n"
    echo -e $usage
    exit 1
fi

searchfor="$*"

# http://stackoverflow.com/questions/8715295/need-help-coloring-replacing-arbitrary-strings-using-bash-and-sed
normal=$(tput sgr0)
red=$(tput setaf 1)
green=$(tput setaf 2)
cyan=$(tput setaf 6)
filecolor=$cyan
replace=$red

grep_options="-E $ignore_case $recursive $exclude_dirs $list_filenames_only"

if [[ "$list_filenames_only" = "-l" ]]; then
    if [[ "$show_path" = "-p" ]]; then
        grep $grep_options "$searchfor" *
    else
        grep $grep_options "$searchfor" * | sed -r 's|^.+/||'
    fi
else
    if [[ "$show_path" = "-p" ]]; then
        grep $grep_options "$searchfor" * | sed -r -e 's/\s+/ /g' -e "s/(^[^:]*+:)/${filecolor}\1${normal}/g$sedi" -e "s/($searchfor)/${replace}\1${normal}/g$sedi"
    else
        grep $grep_options "$searchfor" * | sed -r -e 's/\s+/ /g' -e 's/^[^:]*\///' -e "s/(^[^:]+:)/${filecolor}\1${normal}/g$sedi" -e "s/($searchfor)/${replace}\1${normal}/g$sedi"
    fi
fi