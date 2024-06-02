git_prompt() {
    local branch_name="$(git symbolic-ref HEAD 2> /dev/null | awk -F'/' '{print $NF}')"

    if [ -z "$branch_name" ]; then
        return
    fi

    echo " ($branch_name)"
}

pwd_prompt() {
    local final_pwd=$(echo ${PWD/#$HOME/\~} |
    sed 's#.*\/\([^/]*\)/\([^/]*\)/\([^/]*\)/\([^/]*\)$#…\/\2/\3/\4#')

    if [ ${#final_pwd} -gt 30 ]; then
        final_pwd=…${final_pwd: -30}
    fi

    echo $final_pwd
}

local venv='$(virtualenv_prompt_info)'
local pwd='%{$FG[035]%}$(pwd_prompt)%{$reset_color%}'
local git='%{$FG[245]%}$(git_prompt)%{$reset_color%}'
local return='%(?.. %{$fg[red]%}[%?]%{$reset_color%})'
local final_prompt='> '

ZSH_THEME_VIRTUALENV_PREFIX="%{$FG[022]%}["
ZSH_THEME_VIRTUALENV_SUFFIX="]%{$reset_color%} "

PROMPT="${venv}${pwd}${git}${return}${final_prompt}"

