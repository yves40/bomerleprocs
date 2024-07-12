#---------------------------------------------------------------------------------------
#   admin.sh
#
#   Jul 12 2024 Initial
#---------------------------------------------------------------------------------------
#   Params
#---------------------------------------------------------------------------------------
version="admin.sh, Jul 12 2024 : 1.02 "
#---------------------------------------------------------------------------------------
#   Some parameters
#---------------------------------------------------------------------------------------
LOG="/tmp/O2ratoon-admin.log"
LOCALTARGETDB="todelete"
LOCALWEBDIR="$HOME/bomerleprod"
LOCALBACKUPDIR="$HOME/bomerleprocs/backups"
FEEDBACK=""
GETINPUT="$HOME/bomerleprocs/local/ask.sh"
#---------------------------------------------------------------------------------------
#   Running under cygwin ?
#---------------------------------------------------------------------------------------
if [ ! -z $OSTYPE ]
then
    if [ $OSTYPE == "cygwin" ]
    then
        alias clear='cmd /c cls'
    fi
fi
#---------------------------------------------------------------------------------------
#   Some utility routine
#---------------------------------------------------------------------------------------
# Logger
#---------------------------------------------------------------------------------------
log() 
{
        echo "`date` : $version $1" >> $LOG
        echo "`date` : $1"
}
feedback() 
{
        FEEDBACK="`date` : $1"
        if [ ! -z $2 ]
        then
          echo $1
          echo
        fi
}
#---------------------------------------------------------------------------------------
#   Main menu 
#---------------------------------------------------------------------------------------
menu()
{
  clear
  echo ""
  echo ""
  echo $version
  echo `date`
  if [ ! "$FEEDBACK" = "" ]
  then
    echo "Latest message : $FEEDBACK"
    FEEDBACK=""
  fi
  echo
  echo  
  echo "-------------------------------------------------------------------------------"
  echo " L O C A L    A C T I O N S"
  echo "-------------------------------------------------------------------------------"
  echo "  rpdb        Restore PROD DB in local mysql"
  echo "  rpi         Restore PROD images in local WEB environment"
  echo
  echo "-------------------------------------------------------------------------------"
  echo " L O G S"
  echo "-------------------------------------------------------------------------------"
  echo "  log         View actions log"
  echo
  echo
}
#---------------------------------------------------------------------------------------
#   Start requested action 
#---------------------------------------------------------------------------------------
parsecommand() {
  command=`echo $1 | tr A-Z a-z`
  case "$command" in 
    'rpdb')     echo
                log "Restoring the PROD db in $LOCALTARGETDB"
                feedback "PROD DB restored in local environment" "Y"
                ANSWER=`./ask.sh "return to menu "`
                ;;
    'rpi')      echo
                log "Restoring the PROD images in $LOCALWEBDIR/images"
                feedback "PROD images restored in local environment" "Y"
                ANSWER=`./ask.sh "return to menu "`
                ;;    
    'log')      echo
                less $LOG
                ANSWER=`./ask.sh "return to menu "`
                ;;    
    *)          feedback "Unknown command"
                ;;
  esac
}
#---------------------------------------------------------------------------------------
#   S T A R T   H E R E
#---------------------------------------------------------------------------------------
#   INIT 
#---------------------------------------------------------------------------------------
clear
echo ""
echo "$version"
echo ""
#---------------------------------------------------------------------------------------
#   Some preliminary questions
#---------------------------------------------------------------------------------------
while [ 1 ]
do
  menu
  ANSWER=`./ask.sh "Enter a command listed above or return to exit : "`
  if [ -z $ANSWER ]
  then
    break
  else
    parsecommand $ANSWER
  fi
done
#---------------------------------------------------------------------------------------
#   Summary 
#---------------------------------------------------------------------------------------
echo ""
echo ""
echo ""
log "Exit admin.sh for O2-Ratoon site"
