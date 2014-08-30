#!/bin/bash

 usage="\ngitsel.sh: git sel(ect) -- a git command line helper\n\n"
usage+="prompt: command [filenum]\n"

usage+="\nAn interactive helper for some common git activities. You get a\n"
usage+="git status listing with numbered files. You can then choose the\n"
usage+="file number along with a command to run on the selected file\n"
usage+="(\$file). Enter multiple files separated by spaces, or 0 for all\n"
usage+="files. Some commands apply to all files, regardless of whether\n"
usage+="a number is entered (e.g. commit). If no number is given for a\n"
usage+="command that requires a file, the first file will be chosen.\n"

usage+="\nThe format is flexible, as shown in the examples below.\n"

usage+="\nUses the git status -s \"short format,\" which shows status for\n"
usage+="staged/working files by column and color coding. The column\n"
usage+="header \"sw\" indicates staged vs working file status.\n"

usage+="\nSadly, files with spaces in the name aren't handled. There's\n"
usage+="just too much pain for not enough gain.\ns"

usage+="\ncommands:\n"

usage+="\ta\tgit add \$file\n"
usage+="\tc\tcopy \$file path to the clipboard\n"
usage+="\t\t\t(currently assumes Mac OSX pbcopy)\n"
usage+="\tcommit\tgit commit staged files\n"
usage+="\td\tgit diff \$file (will show staged diff, too!)\n"
usage+="\tdt\tgit difftool \$file (alsso: t)\n"
usage+="\tdis\tgit checkout -- \$file (also: discard)\n"
usage+="\tl\tgit log \$file (also: log)\n"
usage+="\t\t\t(15 lines w/ pretty formatting)\n"
usage+="\tpull\tgit pull\n"
usage+="\tpush\tgit push\n"
usage+="\tr\trefresh status (also: refresh)\n"
usage+="\trm\tremove a file (note: normal rm, not git rm)\n"
usage+="\tun\tgit reset HEAD \$file (also: unstage)\n"

usage+="\nexamples:\n"
usage+="\t2d\trun git diff on file #2\n"
usage+="\tt3\trun git difftool on file #3\n"
usage+="\tdt 3 4\trun git difftool on files #3 and #4\n"
usage+="\ta 1\trun git add on file #1\n"
usage+="\t1 2 c\tcopy file #1 and #2 paths to clipboard\n"
usage+="\t0 c\tcopy all file paths to clipboard\n"
usage+="\t3\tno command chosen; echoes the selected file\n"

if [[ "$1" =~ -?-h(elp)? ]]; then
    echo -e $usage
    exit 0
fi

user_command=$@

# crude check to see if we're in a git rep
git_status=$(git status -s)
if [ $? -ne 0 ]; then
    exit 1
fi

# for colorization
start="\033"
red=$(echo -e "${start}[0;31m")
green=$(echo -e "${start}[0;32m")
cyan=$(echo -e "${start}[0;36m")
normal=$(echo -e '\033[0m')

while true
do
    # show branch and tracking info
    git status -b | sed -n '1 p'

    if [[ $(git status -s | wc -l) -eq 0 ]]; then
        echo "${cyan}working directory clean${normal}"
    else
        echo -e "     sw"   # staging / working
    fi

    # --porcelain a more future-proof version of -s for scripting
    #git status --porcelain | nl
    # nl -n rn -w4 -s" "
    #       -n    rn is default right-adjusted w/ suppressed leading zeros
    #       -w4   line number uses 4 chars
    #       -s" " separator between number and line is a space
    # colorize
    git status --porcelain | nl -n rn -w4 -s" " | sed -r "s/^( +[0-9]+ )([^?])(.)(.+)$/\1${green}\2${red}\3${normal}\4/"

    echo
    read -p "Command? (h/help, q/quit): " user_command

    # replace non-numbers with spaces, trim, and replace spaces with | separators
    # so will end up with single # or a group of #s like 2|3|1
    the_number=$(echo "$user_command" | sed -r -e 's/[^0-9]/ /g' -e 's/^\s+|\s+$//g' -e 's/\s+/|/g')
    the_letter=$(echo "$user_command" | sed 's/[^a-z]//g')

    if [[ "$user_command" == "" ]]; then
        exit 0  # hitting "enter" means we want to quit
    fi

    if [[ "$the_number" == "" ]]; then
        the_number=1  # default file selection
    fi

    if [[ "$the_number" =~ 0+ ]]; then
        the_number="[0-9]+"  # all files
    fi

    #echo "cmd= $user_command, num = $the_number, letter = $the_letter"

    # use nl again to get a listing with a format we can match our numbers
    # against and then cut the line number and status off
    files=$(git status --porcelain | nl -n rn -w6 -s" " | egrep "^\s+($the_number)\s+" | cut -c11- | paste -d" " -s)

    status="selected:${normal} $files"
    command_to_display=""

    # ----------------------------------------------------------------- git add
    if [[ "$the_letter" == "a" ]]; then
        git add --all $files
        command_to_display="add "

    # ------------------------------------------------------- copy to clipboard
    elif [[ "$the_letter" == "c" ]]; then
        echo -n "$files" | pbcopy  # pbcopy is a mac osx the_letter
        status="selected file path(s) copied to clipboard:${normal} $files"

    # -------------------------------------------------------------- git commit
    elif [[ "$the_letter" == "commit" ]]; then
        git commit
        command_to_display="commit "
        status="staged files"

    # ---------------------------------------------------------------- git diff
    elif [[ "$the_letter" == "d" ]]; then
        if [[ $(git diff --cached $files | wc -l) -gt 0 ]]; then
            echo "${cyan}diff on ${red}staged${cyan} file${normal}"
            git diff --cached $files
        fi
        if [[ $(git diff $files | wc -l) -gt 0 ]]; then
            echo "${cyan}diff on ${red}working${cyan} file${normal}"
            git diff $files
        fi
        command_to_display="diff "

    # ------------------------------------------------------------ git difftool
    elif [[ "$the_letter" =~ ^d?t$ ]]; then
        if [[ $(git diff --cached $files | wc -l) -gt 0 ]]; then
            echo "${cyan}difftool on ${red}staged${cyan} file${normal}"
            git difftool --cached  $files
        fi
        if [[ $(git diff $files | wc -l) -gt 0 ]]; then
            echo "${cyan}difftool on ${red}working${cyan} file${normal}"
            git difftool $files
        fi
        command_to_display="difftool "

    # -------------------------------------------------------------------- help
    elif [[ "$the_letter" =~ ^h(elp)?$ ]]; then
        echo -e $usage
        continue

    # ----------------------------------------------- discard (git checkout --)
    elif [[ "$the_letter" =~ ^dis(card)?$ ]]; then
        git checkout -- $files
        command_to_display="discard changes for "

    # ----------------------------------------------------------------- git log
    elif [[ "$the_letter" =~ ^l(og)?$ ]]; then
        git log --graph --pretty=format:"%Cred%h%Creset -%C(bold cyan)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit -15 "$file"

    # ---------------------------------------------------------------- git pull
    elif [[ "$the_letter" == "pull" ]]; then
        git pull
        command_to_display="pull "
        status=""

    # ---------------------------------------------------------------- git push
    elif [[ "$the_letter" == "push" ]]; then
        git push
        command_to_display="push "
        status=""

    # -------------------------------------------------------------------- quit
    elif [[ "$the_letter" =~ ^q(uit)?$ ]]; then
        exit 0

    # ----------------------------------------------------------------- refresh
    elif [[ "$the_letter" =~ ^r(efresh)?$ ]]; then
        continue

    # ---------------------------------------------------------------------- rm
    elif [[ "$the_letter" == "rm" ]]; then
        rm $files
        command_to_display="remove "

    # --------------------------------------------- unstage (git reset -q HEAD)
    elif [[ "$the_letter" =~ ^un(stage)?$ ]]; then
        git reset -q HEAD $files
        command_to_display="unstage "

    # ----------------------------------------------------------------- unknown
    elif [[ "$the_letter" != "" ]]; then
        echo "${red}unknown command:${normal} $the_letter"
    fi

    echo "${cyan}${command_to_display}${status}${normal}"

    continue
done
