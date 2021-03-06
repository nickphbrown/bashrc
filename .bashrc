# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
	. /etc/bashrc
fi

#if [ -f ~/.bashrc ]; then
#	. ~/.bashrc
#fi

#################################################################
#################################################################
#################################################################

####################################
# pushing bash prompt remotely:
# https://superuser.com/questions/221001/pushing-my-ps1-prompt-over-ssh
#ssh -t user@host "remote='$PS1' bash -i"
#Then, at the prompt:
#PS1=$remote
#####################
# guides
# http://jakemccrary.com/blog/2015/05/03/put-the-last-commands-run-time-in-your-bash-prompt/
# see https://github.com/nojhan/liquidprompt
# http://www.askapache.com/linux/bash-power-prompt/
# history guide: https://www.digitalocean.com/community/tutorials/how-to-use-bash-history-commands-and-expansions-on-a-linux-vps
# see http://brettterpstra.com/2009/11/17/my-new-favorite-bash-prompt/
# generate hostname color depending on name:
# https://serverfault.com/questions/221108/different-color-prompts-for-different-machines-when-using-terminal-ssh
# https://www.maketecheasier.com/more-useful-and-interesting-bash-prompts/ # megafancyprompt

# colors:
# http://bitmote.com/index.php?post/2012/11/19/Using-ANSI-Color-Codes-to-Colorize-Your-Bash-Prompt-on-Linux
# http://blog.taylormcgann.com/tag/prompt-color/
#################################################################
#################################################################
#################################################################
### To optimize gedit calls from the terminal.

function gedit(){ command gedit "$@" &>/dev/null & }

function Ngedit(){ command gedit --new-window "$@" &>/dev/null & }

function terminator(){ command terminator --geometry=945x1200+0+0 "$@" &>/dev/null & }

function colsw(){ 
        ## switches theme color set by $THEME_VAR vals range from - 0 to 9
        cp ~/.bashrc ~/.bashrc_OG ### create failsafebackup first
        local CURRCOL=`grep "THEME_VAR=" ~/.bashrc | grep -v sed | tr '=' ' ' | awk '{print $2}'`
        cat ~/.bashrc | sed "s/THEME_VAR=${CURRCOL}/THEME_VAR=${1}/" > ~/.bashrc_temp && cp ~/.bashrc_temp ~/.bashrc
        source ~/.bashrc
}        

function cproot(){ 
        ## copies .bashrc to root
        sudo cp ~/.bashrc /root/
        #source ~/.bashrc
} 

function cpcol(){ 
        ## copies .bashrc to remote host specified by $1 commandline arg
        rsync -av ~/.bashrc ${1}:~/ 
}    
##################################
### git branch functions
# check https://github.com/magicmonty/bash-git-prompt
# http://stackoverflow.com/questions/2657935/checking-for-a-dirty-index-or-untracked-files-with-git
# https://github.com/jimeh/git-aware-prompt/blob/master/prompt.sh

#############################
function virtualenv_info(){
    # Get Virtual Env
    if [[ -n "$VIRTUAL_ENV" ]]; then
        # Strip out the path and just leave the env name
        venv="${VIRTUAL_ENV##*/}"
    else
        # In case you don't have one activated
        venv=''
    fi
    [[ -n "$venv" ]] && echo "${BARCOL}──${TXTCOL}[${HIRed}venv: $venv${TXTCOL}]"
}


#############################
function find_git_branch() {
  # Based on: http://stackoverflow.com/a/13003854/170413
  local branch=$(git rev-parse --abbrev-ref HEAD 2> /dev/null)
  if [[ ! -z "$branch" ]]; then
    if [[ "$branch" == "HEAD" ]]; then
      branch_fmt="${RED}!detached"
    else
      branch_fmt="${TXTCOL}${branch}"
    fi
    git_branch="${branch_fmt}"
  else
    git_branch=""
  fi
  echo $git_branch
}


#############################                
function get_git_commid() {
    ### get current commit hash 
    curr_commitid=`git rev-parse --short HEAD 2> /dev/null`                    
    ### get previous commit hash
    prev_commitid=`git rev-list --max-count=2 --abbrev-commit HEAD  | tail -1`
    echo "${BARCOL}──${TXTCOL}[c~${curr_commitid}]${BARCOL}──${TXTCOL}[p~${prev_commitid}]"
}


#############################                
function parse_git() {
    
    ### first check to see if we are in a git branch
    git_str=$(find_git_branch)    
    if [[ ! -z "$git_str" ]]; then        
        ### now check for git dirty state        
        git_str="${BARCOL}──${TXTCOL}[$(git_com_diff) ${git_str}$(find_git_dirty)"
        
        ### add git stats if applicable
        git_str="${git_str}$(find_git_stats)"  
        
        ### add final closing bracket
        git_str="${git_str}${TXTCOL}]"  
        
        ### add short commitid string
        #git_str="${git_str}$(get_git_commid)"

        ### Final echo that PS prompt sees 
        echo $git_str
    else
        echo ""    
    fi    
}


#############################
function find_git_dirty() {
    gdirtstr=$(git status 2> /dev/null | tail -n1 | sed 's/,//' | awk '{print $1, $2, $3}')
    if [[ ${gdirtstr} == "nothing to commit" ]]
          then
          dirty_state=""            
    elif [[ ${gdirtstr} == "" ]]
          then
          dirty_state=""
    else
          dirty_state='\[\033[01;38;5;221m\]*'
    fi     
    echo $dirty_state
}

#############################
function git_com_diff() {
    ### Check how far git branch is relative to origin
    gbranchrel=`git status 2> /dev/null | grep "Your branch is"`
    gup=`echo $gbranchrel 2> /dev/null | grep ahead`
    gdown=`echo $gbranchrel 2> /dev/null | grep behind`
    grelN=`echo $gbranchrel | sed -nr 's/.*by ([0-9]+) commit?[a-z]./\1/p'`
  
    ### uniode symbols at : http://panmental.de/symbols/
    gupdown=""
    if [[ $gup != "" ]]; then              
          gupdown="${grelN}↑"
    fi
    
    if [[ $gdown != "" ]]; then              
          gupdown="${grelN}↓"
    fi    
    echo $gupdown
}    

#############################
function find_git_stats() {                   	     
      ##########################################                    
      gporcelain=`git status --porcelain 2> /dev/null`                  
      untrN=`echo $gporcelain | tr ' ' '\n' | grep -w '??' | wc -l` # untracked
      addN=`echo $gporcelain | tr ' ' '\n' | grep -w '^A' | wc -l`  # added            
      modN=`echo $gporcelain | tr ' ' '\n' | grep -w '^M' | wc -l`  # modified                          
      commN=`echo $gporcelain | tr ' ' '\n' | grep -w '^AM' | wc -l`  # added & modified?                 
      delN=`echo $gporcelain | tr ' ' '\n' | grep -w '^D' | wc -l`  # deleted                

      ### Build up visible legend & git stats depending on what is appropriate
      
      gitlegend=""
      gitstats_str=""
      if [[ $untrN != "0" ]]; then
            gitlegend="${gitlegend}${TEAL}u"
            gitstats_str="${gitstats_str}${TEAL}${untrN}"                
      fi
      
      if [[ $addN != "0" ]]; then
            gitlegend="${gitlegend}${LBLUE}a"
            gitstats_str="${gitstats_str}${LBLUE}${addN}"                
      fi        
      
      if [[ $modN != "0" ]]; then
            gitlegend="${gitlegend}${MAGENTA}m"
            gitstats_str="${gitstats_str}${MAGENTA}${modN}"                
      fi                      

      if [[ $commN != "0" ]]; then
            gitlegend="${gitlegend}${HIGreen}c"
            gitstats_str="${gitstats_str}${HIGreen}${commN}"                
      fi       
      
      if [[ $delN != "0" ]]; then
            gitlegend="${gitlegend}${RED}d"
            gitstats_str="${gitstats_str}${RED}${delN}"                
      fi 
      
      ### add "/" charcaters between numbers - WIP
      #gitstats_str=`echo $gitstats_str > /dev/null | sed "s/${gitlegend}/&{gitlegend}\//g"` # | sed 's/\/$//'`
      gitlegend="${gitlegend}${SLATE}: "
      
      
      ### removes the ":" between gitlegend and gitstats_str
      if [[ $gitstats_str == "" ]]; then
            joined_gitstats=""
      else
            joined_gitstats=" ${gitlegend}${gitstats_str}"      
      fi  	             
      echo "${gupdown}${TXTCOL}${gbranchstr}${dirty_state}${joined_gitstats}"                    	     
}
     

##################################
### last command timer
function timer_start {
  timer=${timer:-$SECONDS}
}

function timer_stop {
  timer_show=$(($SECONDS - $timer))
  unset timer
}

#trap 'timer_start' DEBUG

##################################
### returns the last 2 fields of the working directory
pwdtail () { 
    pwd | awk -F/ '{nlast = NF -1;print $nlast"/"$NF}'
}
#################################################################
#################################################################
#################################################################

# User specific aliases and functions
HISTSIZE=5000
HISTFILESIZE=10000
shopt -s histappend

color_prompt=yes
if [ "$color_prompt" = yes ]; then

#PS1='${debian_chroot:+($debian_chroot)}\n\[\033[01;38;5;221m\]┌──\[\033[38;5;202m\][\u]\[\033[38;5;221m\]──\[\033[38;5;202m\][\H]\[\033[35m\]\[\033[38;5;221m\]──\[\033[38;5;202m\][speed: ${timer_show}s]\[\033[38;5;221m\]──\[\033[38;5;202m\][git:$(parse_git)\[\033[01;38;5;221m\]$(parse_git_dirty)\[\033[38;5;202m\]]     \n\[\033[38;5;221m\]│\[\033[37m\] > \w\n\[\033[38;5;221m\]└──\[\033[38;5;202m\]`date +"%H:%M"`\[\033[1;38;5;221m\]──\\$\[\033[00m\] ' 

function prompt_command() {
        ###################################################
        ### identify success/fail status of last command
        ### DO NOT MOVE THIS COMMAND: must be first!
        local last_status=$?
        ###################################################
        ###################################################  
        #timer_stop
        ###################################################

        local MORANGE="\[\033[38;5;202m\]"
        local DORANGE="\[\033[38;5;221m\]"
        local YELLOW="\[\033[01;38;5;221m\]"        
        local TEAL="\[\033[0;5;36m\]"
        local BCYAN="\[\033[1;5;36m\]"
        local LBLUE="\[\033[0;1;34m\]"
        local VBLUE="\[\033[0;5;34m\]"
        local VLBLUE="\[\033[1;5;34m\]"        
        local GRAY="\[\033[0;37m\]"
        local DKGRAY="\[\033[1;30m\]"
        local WHITE="\[\033[1;37m\]"
        local TERGREEN="\[\033[00m\]"    
        local RED="\[\033[1;5;31m\]"    
        local CHATREU="\[\033[1;5;32m\]"    
        local LGREEN="\[\033[1;2;32m\]"   
        local SLATE="\[\033[1;2;37m\]"            
        local LYELLOW="\[\033[1;33m\]"      
        local LMAGENTA="\[\033[1;35m\]"      
        local MAGENTA="\[\033[1;5;35m\]"          
        ###
        # High Intensty
        local HIBlack="\[\033[0;90m\]" 
        local HIRed="\[\033[0;5;91m\]"  
        local HIGreen="\[\033[0;92m\]"  
        local HIYellow="\[\033[0;5;93m\]"  
        local HIBlue="\[\033[0;94m\]"
        local HIPurple="\[\033[0;95m\]"  
        local HICyan="\[\033[0;96m\]"  
        local HIWhite="\[\033[0;97m\]"                           
        
        local TITLEBAR=`pwdtail`
        local TTY_VAR=`tty 2> /dev/null | awk -F/ '{nlast = NF 0;print $nlast$NF": "}'`    

        ###################################################  
        ### Setup if else for different color themes
        # Turn the prompt symbol red if the user is root
        THEME_VAR=0                
  
        if [[ THEME_VAR -eq 0 ]]; then 
                ### local color
                local BARCOL="${DORANGE}"
                local TXTCOL="${MORANGE}"       
        elif [[ THEME_VAR -eq 1 ]]; then 
                local BARCOL="${LBLUE}"
                local TXTCOL="${TEAL}"      
        elif [[ THEME_VAR -eq 2 ]]; then 
                local BARCOL="${BCYAN}"
                local TXTCOL="${SLATE}"
        elif [[ THEME_VAR -eq 3 ]]; then 
                local BARCOL="${SLATE}"
                local TXTCOL="${CHATREU}"        
        elif [[ THEME_VAR -eq 4 ]]; then 
                local BARCOL="${LBLUE}"
                local TXTCOL="${LMAGENTA}"                                                                       
        elif [[ THEME_VAR -eq 5 ]]; then 
                local BARCOL="${LGREEN}"
                local TXTCOL="${CHATREU}"      
        elif [[ THEME_VAR -eq 6 ]]; then 
                local BARCOL="${VBLUE}"
                local TXTCOL="${VLBLUE}"   
        elif [[ THEME_VAR -eq 7 ]]; then 
                local BARCOL="${HIRed}"
                local TXTCOL="${HIYellow}"    
        elif [[ THEME_VAR -eq 8 ]]; then 
                local BARCOL="${HIPurple}"
                local TXTCOL="${HIBlue}"       
        elif [[ THEME_VAR -eq 9 ]]; then 
                local BARCOL="${TERGREEN}"
                local TXTCOL="${HICyan}"                                                                  
        else
                local BARCOL="${DORANGE}"
                local TXTCOL="${MORANGE}"        
                echo -e '\n\nbash color prompt idx not recognised!!\n Default theme will be set...\n\n\n'
                ### switch to default local color
                colsw 0 # switch back to 0                 
        fi    
        
        ###################################################
        ### root stuff
        if [[ $(id -u) -eq 0 ]]; then  
                ### root color
                local BARCOL="${MORANGE}"
                local TXTCOL="${RED}"  
                local ENDBIT="#" 
        else
                local ENDBIT="$"         
        fi # root bit 

				###################################################
				### set virtual environment if applicable

        # disable the default virtualenv prompt change                                                                                                                                                 
        export VIRTUAL_ENV_DISABLE_PROMPT=1                                             
                                                                                
        VIRTENV=$(virtualenv_info)


        ###################################################
        ### set color coded error string for prompt depending on success of last command
        if [[ $last_status == "0" ]]; then 
                ERRPROMPT="\[\033[1;5;32m\]${ENDBIT} "
        else
                ERRPROMPT='\[\033[1;5;31m\]X '
        fi 

        ###################################################
        ### set titlebar
        echo -ne '\033]2;'${TTY_VAR}${TITLEBAR}'\007' 



        
PS1="${debian_chroot:+($debian_chroot)}\n\
${YELLOW}${BARCOL}┌──\
${TXTCOL}[\u]\
${BARCOL}──\
${TXTCOL}[\H]\
${BARCOL}──\
${TXTCOL}[speed: ${timer_show}s]\
$(parse_git)\
${VIRTENV}
${BARCOL}│${DKGRAY}${TTY_VAR}${WHITE}> \w \
\n${BARCOL}└──\
${TXTCOL}`date +"%H:%M"`\
${BARCOL}──\
${ERRPROMPT}${TERGREEN}" 
}

# switch to export history to all terminals
exp_history="no"
if [ "$exp_history" = "yes" ]; then
PROMPT_COMMAND="prompt_command; history -a; history -c; history -r"
else
#trap 'timer_start' DEBUG        
#timer_stop;
PROMPT_COMMAND="prompt_command"
fi
#

else
    #PS1='${debian_chroot:+($debian_chroot)}\n\[\033[01;35m\]┌──\[\033[33m\][\u]\[\033[35m\]──\[\033[33m\][\H]\[\033[35m\]\[\033[35m\]──\[\033[33m\][last: ${timer_show}s]\n│\[\033[37m\] '
    #PS1='${debian_chroot:+($debian_chroot)}\u@\h:\w\$ '
#    PS1="\n\[\033[1;30m\][$$:$PPID - \j:\!\[\033[1;30m\]]\[\033[0;36m\] \T \
#\[\033[1;30m\][\[\033[1;34m\]\u@\H\[\033[1;30m\]:\[\033[0;37m\]${SSH_TTY:-o} \
#\[\033[0;32m\]+${SHLVL}\[\033[1;30m\]] \[\033[1;37m\]\w\[\033[0;37m\] \n\$ "
#PROMPT_COMMAND="FUNCpromptCommand"
PS1="[\d \t \u@\h:\w ] $ "
fi


#################################################################
#################################################################
#################################################################
#if [ "$TERM" != "dumb" ]; then
#    [ -e "$HOME/.dircolors" ] && DIR_COLORS="$HOME/.dircolors"
#    [ -e "$DIR_COLORS" ] || DIR_COLORS=""
#    eval "`dircolors -b $DIR_COLORS`"
#fi
#####

alias ssh1='eval $(ssh-agent -s) && ssh-add'

alias venv1='source ~/venvs/py35/bin/activate'

alias F5='source ~/.bashrc'


#################################################################
#################################################################
#################################################################
###https://superuser.com/questions/195781/sudo-is-there-a-command-to-check-if-i-have-sudo-and-or-how-much-time-is-left
### The command below will show a colored indication that you have sudo granted, so you remember to do a sudo -k
function FUNCpromptCommand () { 
    sudo -n uptime 2>/dev/null 1>/dev/null
  local bSudoOn=`if(($?==0));then echo true; else echo false; fi`

    history -a; # append to history at each command issued!!!
    local width=`tput cols`;
    local half=$((width/2))
    local dt="[EndAt:`date +"%Y/%m/%d-%H:%M:%S.%N"`]";
  if $bSudoOn; then dt="!!!SUDO!!!$dt"; fi
    local sizeDtHalf=$((${#dt}/2))
    #printf "%-${width}s" $dt |sed 's" "="g'; 
    echo
    output=`printf "%*s%*s" $((half+sizeDtHalf)) "$dt" $((half-sizeDtHalf)) "" |sed 's" "="g';`

    local colorLightRed="\e[1;31m"
  local colorNoColor="\e[0m"
    if $bSudoOn; then
        echo -e "${colorLightRed}${output}${colorNoColor}"
    else
        echo -e "${output}"
    fi
}


# The next line updates PATH for the Google Cloud SDK.
#if [ -f '/home/nick.brown/programs/google-cloud-sdk/path.bash.inc' ]; then source '/home/nick.brown/programs/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
#if [ -f '/home/nick.brown/programs/google-cloud-sdk/completion.bash.inc' ]; then source '/home/nick.brown/programs/google-cloud-sdk/completion.bash.inc'; fi

# The next line enables shell command completion for git.
if [ -f '/usr/share/bash-completion/completions/git' ]; then source '/usr/share/bash-completion/completions/git'; fi

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/home/nick-brown/google-cloud-sdk/path.bash.inc' ]; then source '/home/nick-brown/google-cloud-sdk/path.bash.inc'; fi

# The next line enables shell command completion for gcloud.
if [ -f '/home/nick-brown/google-cloud-sdk/completion.bash.inc' ]; then source '/home/nick-brown/google-cloud-sdk/completion.bash.inc'; fi
