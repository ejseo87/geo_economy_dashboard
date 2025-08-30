# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# Path to your Oh My Zsh installation.
export ZSH="$HOME/.oh-my-zsh"

# Theme
ZSH_THEME="powerlevel10k/powerlevel10k"

# Plugins (설치 안 했다면 두 줄 제거하거나 설치하세요)
plugins=(
  git
  zsh-autosuggestions
  zsh-syntax-highlighting
)

source $ZSH/oh-my-zsh.sh

# Load p10k config if available
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh

############################################
# PATH 정리 (Homebrew → System → Local → SDK)
############################################

# 1) Homebrew 우선
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

# 2) 표준 시스템 PATH 보장
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin:$PATH"

# 3) 유저 로컬 바이너리
export PATH="$HOME/.local/bin:$PATH"
export PATH="$HOME/.pub-cache/bin:$PATH"

# 4) Android SDK & Java
export ANDROID_HOME="/Volumes/eva/AndroidDevelopment/sdk"
export PATH="$ANDROID_HOME/platform-tools:$ANDROID_HOME/cmdline-tools/latest/bin:$PATH"

export JAVA_HOME="/opt/homebrew/opt/openjdk@17"
export PATH="$JAVA_HOME/bin:$PATH"

# 5) NVM (Homebrew 설치 경로)
export NVM_DIR="$HOME/.nvm"
[ -s "/opt/homebrew/opt/nvm/nvm.sh" ] && \. "/opt/homebrew/opt/nvm/nvm.sh"
[ -s "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm" ] && \. "/opt/homebrew/opt/nvm/etc/bash_completion.d/nvm"

############################################
# Conda (필요할 때만 활성화 권장)
############################################
# conda base 자동 활성화 비활성화 권장:
#   conda config --set auto_activate_base false
# 이후 필요할 때만 `conda activate <env>` 사용
# >>> conda initialize >>>
# !! Contents within this block are managed by 'conda init' !!
__conda_setup="$('/opt/homebrew/anaconda3/bin/conda' 'shell.zsh' 'hook' 2> /dev/null)"
if [ $? -eq 0 ]; then
    eval "$__conda_setup"
elif [ -f "/opt/homebrew/anaconda3/etc/profile.d/conda.sh" ]; then
    . "/opt/homebrew/anaconda3/etc/profile.d/conda.sh"
fi
unset __conda_setup
# <<< conda initialize <<<

# -- 절대 넣지 마세요: export PATH="$PATH:/opt/homebrew/anaconda3/bin"
# (conda init이 PATH를 관리하므로 위 한 줄은 충돌 원인입니다)

############################################
# Homebrew 재우선 + PATH 중복 제거 (conda init 아래 위치)
############################################
export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"

dedup_path() {
  local OLD_IFS="$IFS"; IFS=':'
  local seen='' out='' x
  for x in $PATH; do
    [[ -z "$x" ]] && continue
    if [[ ":$seen:" != *":$x:"* ]]; then
      seen="$seen:$x"
      out="${out:+$out:}$x"
    fi
  done
  IFS="$OLD_IFS"
  export PATH="$out"
}
dedup_path

############################################
# Aliases
############################################
alias ls="ls -la | grep -v '^\._'"
alias tm='task-master'
alias taskmaster='task-master'
