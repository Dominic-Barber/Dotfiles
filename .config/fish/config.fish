# Remove the default interactive greeting
set -U fish_greeting ""

# Initialize Starship prompt
starship init fish | source

# Handy Aliases
alias ls="ls --color=auto"
alias ll="ls -la"
alias grep="grep --color=auto"
alias l="ls"
# Web Dev Aliases
alias dev="npm run dev"
alias build="npm run build"
alias lint="npm run lint"

# Git Aliases
alias gs="git status"
alias ga="git add ."
alias gc="git commit -m"


function fish_greeting
    fastfetch
    # cbonsai -l -m "Welcome back, Dominic."
end

function config
   git --git-dir=$HOME/.dotfiles/ --work-tree=$HOME $argv
end


# Added by Antigravity CLI installer
set -gx PATH "/home/barberdj/.local/bin" $PATH
