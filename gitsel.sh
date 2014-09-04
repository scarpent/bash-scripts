#!/bin/bash

 usage="\ngitsel.sh: git sel(ect) -- a git command line helper\n\n"
usage+="prompt: command [filenum]\n"

usage+="\nAn interactive helper for some common git activities. You get a\n"
usage+="git status listing with numbered files. You can then choose the\n"
usage+="file number along with a command to run on the selected file\n"
usage+="(\$file). Enter multiple numbers separated by spaces to select\n"
usage+="more than one file, or no number to select all files. Some\n"
usage+="commands apply to all files, regardless of whether a number is\n"
usage+="entered (e.g. commit).\n"

usage+="\nThe format is flexible, as shown in the examples below.\n"

usage+="\nUses the git status -s \"short format,\" which shows status for\n"
usage+="staged/working files by column and color coding. The column\n"
usage+="header \"sw\" indicates staged vs working file status.\n"

usage+="\nSadly, files with spaces in the name aren't handled. There's\n"
usage+="just too much pain for not enough gain.\n"

usage+="\ncommands:\n"

usage+="\ta\tgit add \$file\n"
usage+="\tc\tcopy \$file path to the clipboard\n"
usage+="\t\t\t(currently assumes Mac OSX pbcopy)\n"
usage+="\tcommit\tgit commit staged files\n"
usage+="\td\tgit diff \$file (will show staged diff, too!)\n"
usage+="\tdt\tgit difftool \$file (also: t)\n"
usage+="\tdiscard\tgit checkout -- \$file (also: dis)\n"
usage+="\tl\tgit log \$file (also: log)\n"
usage+="\t\t\t(15 lines w/ pretty formatting)\n"
usage+="\tpull\tgit pull\n"
usage+="\tpush\tgit push\n"
usage+="\tr\trefresh status (also: refresh)\n"
usage+="\trm\tremove file (note: normal rm, not git rm)\n"
usage+="\tun\tgit reset HEAD \$file (also: unstage)\n"

usage+="\nexamples:\n"
usage+="\t2d\trun git diff on file #2\n"
usage+="\tt3\trun git difftool on file #3\n"
usage+="\tdt 3 4\trun git difftool on files #3 and #4\n"
usage+="\ta 1\trun git add on file #1\n"
usage+="\t1 2 c\tcopy file #1 and #2 paths to clipboard\n"
usage+="\tc\tcopy all file paths to clipboard\n"
usage+="\t3\tno command chosen; echoes the selected file\n"
usage+="\trm\tremove all files (you'll be prompted to confirm!)\n"
usage+="\tdiscard\tdiscard all working changes (again prompted)\n"

if [[ "$1" =~ -?-h(elp)? ]]; then
    echo -e $usage
    exit 0
fi

user_input=$@

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
    git status -sb | sed -n '1 p'

    if [[ $(git status -s | wc -l) -eq 0 ]]; then
        echo "${cyan}working directory clean${normal}"
    else
        echo -e "     sw"   # staging / working
    fi

    # show the files!
    #
    # git status --porcelain a more future-proof version of -s for scripting
    #
    # nl -n rn -w4 -s" "
    #       -n    rn is default right-adjusted w/ suppressed leading zeros
    #       -w4   line number uses 4 chars
    #       -s" " separator between number and line is a space
    # sed to replace parts with color:
    #       ^(\s+[0-9]+\s)      the number (no color)
    #       ([^?])              staging status (green)
    #       (.)                 working status (red)
    #       (.+)$               file (no color)
    #
    #       if file is new and not in git, the status will be ??, in which
    #       case the [^?] will cause a non-match, so no coloring
    git status --porcelain | nl -n rn -w4 -s" " | sed -r "s/^(\s+[0-9]+\s)([^?])(.)(.+)$/\1${green}\2${red}\3${normal}\4/"

    echo
    read -ep "Command? (h/help, q/quit): " user_input
    history -s $user_input

    # replace non-numbers with spaces, trim, and replace spaces with | separators
    # so will end up with single # or a group of #s like 2|3|1
    the_numbers=$(echo "$user_input" | sed -r -e 's/[^0-9]/ /g' -e 's/^\s+|\s+$//g' -e 's/\s+/|/g')
    the_command=$(echo "$user_input" | sed 's/[^a-z]//g')

    if [[ "$user_input" == "" ]]; then
        exit 0  # hitting "enter" means we want to quit
    fi

    if [[ "$the_command" =~ ^(commit|push|pull)$ ]]; then
        # these will always work, even if a bad number is given
        the_numbers=""
    fi

    # no number means all numbers
    if [[ "$the_numbers" == "" ]]; then

        # let's be careful about destructive commands
        if [[ "$the_command" =~ ^(rm|dis(card)?)$ ]]; then
            echo
            read -p "Are you SURE you want to run ${red}$the_command on ALL files${normal} (yes to confirm)? " -r
            if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
                echo -e "${cyan}caution wins the day${normal}"
                continue
            fi
        fi

        the_numbers="[0-9]+"  # all files
        all_selected=true
    else
        # they might have manually selected all files, of course, but:
        all_selected=false
    fi

    # get list of files
    #
    # use nl again to get listing with standard format to match our numbers
    # against and then cut the line number and status off
    # nl to set numbered format we can match with following egrep and then cut
    # egrep selects on single num, e.g. (2), or multiple, e.g. (1|3|7),
    #       or ([0-9]+) for all; (important to wrap with parens!)
    # cut takes filename from expected point after statuses
    # paste turns into a single line with space delimiters
    # sed handles situation of renames indicated by "->"; we'll just remove so
    #       each file is specified
    #
    files=$(git status --porcelain | nl -n rn -w6 -s" " | egrep "^\s+(${the_numbers})\s" | cut -c11- | paste -d" " -s | sed 's/\s->//g')

    if [[ "$files" == "" && "$all_selected" != "true" ]]; then
        echo "${red}no file selected${normal}"
        continue
    fi

    if [[ "$all_selected" == "true" ]]; then
        status="selected:${normal} all files"
        if [[ "$the_command" != "rm" && "$the_command" != "c" ]]; then
            files="."
        fi
    else
        status="selected:${normal} $files"
    fi


    command_to_display=""

    # ----------------------------------------------------------------- git add
    if [[ "$the_command" == "a" ]]; then
        git add --all $files
        command_to_display="add "

    # ------------------------------------------------------- copy to clipboard
    elif [[ "$the_command" == "c" ]]; then
        echo -n "$files" | pbcopy  # pbcopy is a mac osx the_command
        status="selected file path(s) copied to clipboard:${normal} $files"

    # -------------------------------------------------------------- git commit
    elif [[ "$the_command" == "commit" ]]; then
        git commit
        command_to_display="commit "
        status="staged files"

    # ---------------------------------------------------------------- git diff
    elif [[ "$the_command" == "d" ]]; then
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
    elif [[ "$the_command" =~ ^d?t$ ]]; then
        if [[ $(git diff --cached $files | wc -l) -gt 0 ]]; then
            echo "${cyan}difftool on ${red}staged${cyan} file${normal}"
            git difftool --cached  $files
        fi
        if [[ $(git diff $files | wc -l) -gt 0 ]]; then
            echo "${cyan}difftool on ${red}working${cyan} file${normal}"
            git difftool $files
        fi
        command_to_display="difftool "

    # ----------------------------------------------- discard (git checkout --)
    elif [[ "$the_command" =~ ^dis(card)?$ ]]; then
        git checkout -- $files
        command_to_display="discard changes for "

    # -------------------------------------------------------------------- help
    elif [[ "$the_command" =~ ^h(elp)?$ ]]; then
        echo -e $usage
        continue

    # ----------------------------------------------------------------- git log
    elif [[ "$the_command" =~ ^l(og)?$ ]]; then
        git log --graph --pretty=format:"%Cred%h%Creset -%C(bold cyan)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset" --abbrev-commit -15 $files
        command_to_display="log "

    # ---------------------------------------------------------------- git pull
    elif [[ "$the_command" == "pull" ]]; then
        git pull
        command_to_display="pull "
        status=""

    # ---------------------------------------------------------------- git push
    elif [[ "$the_command" == "push" ]]; then
        git push
        command_to_display="push "
        status=""

    # -------------------------------------------------------------------- quit
    elif [[ "$the_command" =~ ^q(uit)?$ ]]; then
        exit 0

    # ----------------------------------------------------------------- refresh
    elif [[ "$the_command" =~ ^r(efresh)?$ ]]; then
        continue

    # ---------------------------------------------------------------------- rm
    elif [[ "$the_command" == "rm" ]]; then
        rm $files
        command_to_display="remove "

    # --------------------------------------------- unstage (git reset -q HEAD)
    elif [[ "$the_command" =~ ^un(stage)?$ ]]; then
        git reset -q HEAD $files
        command_to_display="unstage "

    # ----------------------------------------------------------------- unknown
    elif [[ "$the_command" != "" ]]; then
        echo "${red}unknown command:${normal} $the_command"
    fi

    echo "${cyan}${command_to_display}${status}${normal}"

    continue
done
