# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

# User specific environment
if ! [[ "$PATH" =~ "$HOME/.local/bin:$HOME/bin:" ]]
then
    PATH="$HOME/.local/bin:$HOME/bin:$PATH"
fi
export PATH

# Uncomment the following line if you don't like systemctl's auto-paging feature:
# export SYSTEMD_PAGER=

# User specific aliases and functions

alias lal='ls -al'
alias lrtl='ls -rtl'
alias hh='history | grep -i '
alias symfony='php bin/console'
alias sqldev='mysql --user=toba3789_root --password'

#export PATH=$PATH:$HOME/.symfony5/bin/:/opt/alt/alt-nodejs16/root/usr/bin/
export PATH=$PATH:/opt/alt/alt-nodejs16/root/usr/bin/
export DEV=~/DEV/bomerle
export PROD=~/PROD/bomerle



