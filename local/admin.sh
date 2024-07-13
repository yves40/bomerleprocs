#---------------------------------------------------------------------------------------
#   admin.sh
#
#   Jul 12 2024 Initial
#---------------------------------------------------------------------------------------
#   Params
#---------------------------------------------------------------------------------------
version="admin.sh, Jul 13 2024 : 1.04 "
#---------------------------------------------------------------------------------------
#   Some parameters
#---------------------------------------------------------------------------------------
LOCALTARGETDB="$LOCALTARGETDB"  # Get it from parent shell
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
        echo "`date` : $version $1" >> $O2logs
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
  echo 
  echo "[ $version ]"
  echo "[ `date` ]"
  echo "[ Selected local target DB : $LOCALTARGETDB]"
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
  echo "  ListDBbackups        List the available PROD DB backups"
  echo "  ListImagesbackups    List the available PROD images backups"
  echo "  ListAllbackups       List all DB and images backups"
  echo "  RestoreProdDB        Restore PROD DB in local mysql"
  echo "  RestoreProdImages    Restore PROD images in local WEB environment"
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
    'restoreproddb')     
                echo
                ./restoreProdDB.sh $LOCALBACKUPDIR $LOCALTARGETDB
                ;;
    'restoreprodimages')
                echo
                log "Restoring the PROD images in $LOCALWEBDIR/images"
                feedback "PROD images restored in local environment"
                echo; ANSWER=`./ask.sh "return to menu "`
                ;;    
    'listdbbackups')
                echo; ls -l $LOCALBACKUPDIR/*.sql
                echo; ANSWER=`./ask.sh "return to menu "`
                ;;
    'listimagesbackups')
                echo; ls -l $LOCALBACKUPDIR/*.zip
                echo; ANSWER=`./ask.sh "return to menu "`
                ;;
    'listallbackups')
                echo; ls -l $LOCALBACKUPDIR
                echo; ANSWER=`./ask.sh "return to menu "`
                ;;
    'log')      echo
                less $O2logs
                ;;    
    *)          feedback "Unknown command"
                ;;
  esac
}
#---------------------------------------------------------------------------------------
#   S T A R T   H E R E
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
