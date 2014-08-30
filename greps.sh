#!/bin/bash

usage="grep helper\n"
usage="usage: greps [-Ilp] [-e dir] PATTERN\n\n"
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
NORMAL=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
CYAN=$(tput setaf 6)
FILECOLOR=$CYAN
REPLACE=$RED

grep_options="-E $ignore_case $recursive $exclude_dirs $list_filenames_only"

if [[ "$list_filenames_only" = "-l" ]]; then
    if [[ "$show_path" = "-p" ]]; then
        grep $grep_options "$searchfor" *
    else
        grep $grep_options "$searchfor" * | sed -r 's|^.+/||'
    fi
else
    if [[ "$show_path" = "-p" ]]; then
        grep $grep_options "$searchfor" * | sed -r 's/\s+/ /g' | sed -r "s/(^[^:]*+:)/$FILECOLOR\1$NORMAL/g$sedi" | sed -r "s/($searchfor)/$REPLACE\1$NORMAL/g$sedi"
    else
        grep $grep_options "$searchfor" * | sed -r 's/\s+/ /g' | sed -r 's/^[^:]*\///' | sed -r "s/(^[^:]+:)/$FILECOLOR\1$NORMAL/g$sedi" | sed -r "s/($searchfor)/$REPLACE\1$NORMAL/g$sedi"
    fi
fi