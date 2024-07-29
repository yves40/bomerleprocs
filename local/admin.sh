#---------------------------------------------------------------------------------------
#   admin.sh
#---------------------------------------------------------------------------------------
#   Params
#---------------------------------------------------------------------------------------
version="admin.sh, Jul 29 2024 : 1.07 "
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
  echo "  10 ListDBbackups        List the available PROD DB backups"
  echo "  11 ListImagesbackups    List the available PROD images backups"
  echo "  12 ListAllbackups       List all DB and images backups"
  echo
  echo "  20 RestoreProdDB        Restore PROD DB in local mysql"
  echo "  21 RestoreProdImages    Restore PROD images in local WEB environment"
  echo
  echo "-------------------------------------------------------------------------------"
  echo " L O G S"
  echo "-------------------------------------------------------------------------------"
  echo "  log                  View actions log"
  echo
  echo
}
#---------------------------------------------------------------------------------------
#   Start requested action 
#---------------------------------------------------------------------------------------
parsecommand() {
  command=`echo $1 | tr A-Z a-z`
  case "$command" in 
    '20')     
                echo
                ./restoreProdDB.sh $LOCALBACKUPDIR $LOCALTARGETDB
                tdb=$(cat todelete.data); rm todelete.data
                feedback "PROD DB restored in local database : $tdb" "y"
                LOCALTARGETDB="$tdb"
                export LOCALTARGETDB="$tdb"
                ;;
    '21')
                echo
                log "Restoring the PROD images in $LOCALWEBDIR/images"
                echo; ls -l $LOCALBACKUPDIR/*.zip
                log "Unzipping LOCALBACKUPDIR/PROD-some-jpg-jpeg.zip"
                unzip -x $LOCALBACKUPDIR/PROD-some-jpg-jpeg.zip -d $LOCALWEBDIR -o
                log "Unzipping LOCALBACKUPDIR/PROD-webp-gif-svg.zip"
                unzip -x $LOCALBACKUPDIR/PROD-webp-gif-svg.zip -d $LOCALWEBDIR -o
                feedback "PROD images restored in local environment"
                ;;    
    '10')
                echo; ls -l $LOCALBACKUPDIR/*.sql
                ;;
    '11')
                echo; ls -l $LOCALBACKUPDIR/*.zip
                ;;
    '12')
                echo; ls -l $LOCALBACKUPDIR
                ;;
    'log')      echo
                less $O2logs
                ;;    
    *)          feedback "Unknown command"
                ;;
  esac
  echo; ANSWER=`./ask.sh "Back to menu <CR> "`
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
  ANSWER=`./ask.sh "Enter a command listed above or <CR> exit : "`
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
