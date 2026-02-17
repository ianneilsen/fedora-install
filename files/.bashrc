# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]; then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# PATHS
export PATH="$HOME/.local/bin:$HOME/go/bin:/usr/local/go/bin:/usr/local/bin:$PATH"
export GOPATH=$HOME/go

source <(kubectl completion bash)
complete -o default -F __start_kubectl k
#complete -F __start_kubectl k

source /usr/share/bash-completion/bash_completion

# User specific aliases and functions
if [ -d ~/.bashrc.d ]; then
    for rc in ~/.bashrc.d/*; do
        if [ -f "$rc" ]; then
            . "$rc"
        fi
    done
fi
unset rc

# alias standard
alias ll='ls -alF'
alias la='ls -A'
alias l='ls -CF'
alias grep='grep --color=auto'
alias gst='git status'
alias gct='git commit -m "'
alias k=kubectl
# Enhanced bash history settings
export HISTSIZE=10000
export HISTFILESIZE=10000
export HISTTIMEFORMAT='%F %T '
export HISTCONTROL=ignoredups:erasedups
shopt -s histappend
PROMPT_COMMAND='history -a'

# git terminal prompt
source ~/.git-prompt.sh

GIT_PS1_SHOWDIRTYSTATE=1
GIT_PS1_SHOWUPSTREAM="auto"
GIT_PS1_SHOWCOLORHINTS=1
# Add this to ~/.bashrc
parse_git_info() {
    local branch=$(git symbolic-ref --short HEAD 2>/dev/null)
    if [ -n "$branch" ]; then
        local upstream=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null)
        if [ -n "$upstream" ]; then
            echo " ($branch → $upstream)"
        else
            echo " ($branch)"
        fi
    fi
}

PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[01;33m\]$(parse_git_info __git_ps1 )\[\033[00m\]\n\$ '

# Two-line prompt for readability
#PS1='\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w\[\033[01;33m\]$(__git_ps1 " (%s)")\[\033[00m\]\n\$ '
