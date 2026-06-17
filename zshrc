# Auto-start tmux on terminal open (before p10k to avoid instant-prompt conflicts)
if [[ -z "$TMUX" && "$TERM_PROGRAM" != "vscode" ]]; then
  exec tmux new-session -A -s main
fi

# Enable Powerlevel10k instant prompt — must stay near the top.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ── PATH ─────────────────────────────────────────────────────────────
typeset -U path  # auto-deduplicate
path=(/opt/homebrew/bin $HOME/.local/bin $path)
export PATH

# ── Prompt ───────────────────────────────────────────────────────────
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

# ── Completions (cached — only regenerate if dump is >24h old) ───────
autoload -Uz compinit
fpath=($HOME/.docker/completions $fpath)
if [[ -n ${ZDOTDIR:-~}/.zcompdump(#qN.mh+24) ]]; then
  compinit
else
  compinit -C
fi

# ── Node (fnm) ───────────────────────────────────────────────────────
if [[ -x /opt/homebrew/opt/fnm/bin/fnm ]]; then
  path=(/opt/homebrew/opt/fnm/bin $path)
  eval "$(fnm env --use-on-cd)"
fi

# ── Aliases ──────────────────────────────────────────────────────────
alias vim="nvim"

# ── Tools ────────────────────────────────────────────────────────────
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh

# ── AWS tunnel helpers ───────────────────────────────────────────────
llc-preprod() {
  aws ssm start-session \
    --profile pre-prod \
    --target $(aws ec2 describe-instances --profile pre-prod \
      --filters "Name=tag:Name,Values=preprod-bd-jumpbox" "Name=instance-state-name,Values=running" \
      --query "Reservations[0].Instances[0].InstanceId" --output text) \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters '{"host":["pre-prod-llc.cqnq4i64svcr.us-east-1.rds.amazonaws.com"],"portNumber":["5432"],"localPortNumber":["5472"]}'
}

db-preprod() {
  aws ssm start-session \
    --profile pre-prod \
    --target $(aws ec2 describe-instances --profile pre-prod \
      --filters "Name=tag:Name,Values=preprod-bd-jumpbox" "Name=instance-state-name,Values=running" \
      --query "Reservations[0].Instances[0].InstanceId" --output text) \
    --document-name AWS-StartPortForwardingSessionToRemoteHost \
    --parameters '{"host":["pre-prod-digital.cqnq4i64svcr.us-east-1.rds.amazonaws.com"],"portNumber":["5432"],"localPortNumber":["5441"]}'
}

# ── Google Cloud SDK ─────────────────────────────────────────────────
[[ -f "$HOME/Downloads/google-cloud-sdk/path.zsh.inc" ]] && \
  source "$HOME/Downloads/google-cloud-sdk/path.zsh.inc"
[[ -f "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc" ]] && \
  source "$HOME/Downloads/google-cloud-sdk/completion.zsh.inc"

# ── Plugins (syntax-highlighting must be last) ────────────────────────
ZSH_AUTOSUGGEST_USE_ASYNC=true
source /opt/homebrew/share/zsh-autosuggestions/zsh-autosuggestions.zsh
source /opt/homebrew/share/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh
