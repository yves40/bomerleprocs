#---------------------------------------------------------------------------------------
#   admin.sh
#
#   Jul 12 2024 Initial
#---------------------------------------------------------------------------------------
#   Params
#---------------------------------------------------------------------------------------
version="admin.sh, 1.00"
#---------------------------------------------------------------------------------------
#   Some parameters
#---------------------------------------------------------------------------------------
LOG="/tmp/O2ratoon-admin.log"
LOCALTARGETDB="todelete"
LOCALWEBDIR="$HOME/bomerleprod"
LOCALBACKUPDIR="$HOME/bomerleprocs/backups"
FEEDBACK="-"
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
}
#---------------------------------------------------------------------------------------
#   Check command line input
#   No longer used
#---------------------------------------------------------------------------------------
checkCommandlineInput()
{
    if [ -z $1 ]; then
        SOURCEDATABASE=`./ask.sh "Give the mysql target database name : " "todelete"` 
    else
        SOURCEDATABASE=$1
    fi
    log "The target database is : $SOURCEDATABASE"
    if [ -z $2 ]; then
      log 'No second parameter specified'
    fi
    if [ -z $3 ]; then
      log 'No second parameter specified'
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
  if [ "$FEEDBACK" = "-" ]
  then
    echo `date`
  else
    echo $FEEDBACK
    FEEDBACK="-"
  fi
  echo
  echo  
  echo "-------------------------------------------------------------------------------"
  echo " L O C A L    A C T I O N S"
  echo "-------------------------------------------------------------------------------"
  echo
  echo "  rpdb        Restore PROD DB in local mysql"
  echo "  rpi         Restore PROD images in local WEB environment"
  echo
  echo
  echo "-------------------------------------------------------------------------------"
  echo " L O G S"
  echo "-------------------------------------------------------------------------------"
  echo
  echo "  val         View actions log"
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
                feedback "PROD DB restored in local environment"
                echo
                ;;
    'rpi')      echo
                log "Restoring the PROD images in $LOCALWEBDIR/images"
                feedback "PROD images restored in local environment"
                echo
                ;;    
    'val')      echo
                less $LOG
                echo
                ;;    
    *)          feedback "Unknown command"
                echo
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
  ANSWER=`./ask.sh "Enter a command listed above, return to exit "`
  if [ -z $ANSWER ]; 
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
