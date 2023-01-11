# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# fnm
export PATH="/Users/joanserna/Library/Application Support/fnm:$PATH"
# export CHROME_BIN="/Applications/Google Chrome Dev.app"
export CHROME_BIN="/Applications/Google Chrome Dev.app/Contents/MacOS/Google Chrome Dev"

eval "`fnm env`"
alias vim="nvim"

# fnm
export PATH="/Users/joanserna/Library/Application Support/fnm:$PATH"
eval "$(fnm env --use-on-cd)"
source /opt/homebrew/opt/powerlevel10k/powerlevel10k.zsh-theme

plugins=( 
  git
)
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh


# Load Angular CLI autocompletion.
# source <(ng completion script)
