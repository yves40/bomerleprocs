#---------------------------------------------------------------------------------------
#   admin.sh
#---------------------------------------------------------------------------------------
#   Params
#---------------------------------------------------------------------------------------
version="admin.sh, Aug 10 2024 : 1.13 "
#---------------------------------------------------------------------------------------
#   Some parameters
#---------------------------------------------------------------------------------------
LOCALTARGETDB="$LOCALTARGETDB"  # Get it from parent shell
LOCALWEBDIR="$HOME/bomerleprod"
LOCALBACKUPDIR="$HOME/bomerleprocs/backups"
FEEDBACK=""
lastcommand=""
DATESIGNATURE=`date +"%Y-%m-%d"`
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
  echo "  10 / ListDBbackups        List the available PROD DB backups"
  echo "  11 / ListImagesbackups    List the available PROD images backups"
  echo "  12 / ListAllbackups       List all DB and images backups"
  echo
  echo "  20 / RestoreProdDB        Restore PROD DB in local mysql"
  echo "  21 / RestoreProdImages    Restore PROD images in local WEB environment"
  echo
  echo 
  echo "-------------------------------------------------------------------------------"
  echo " R E M O T E   A C T I O N S"
  echo "-------------------------------------------------------------------------------"
  echo "  50 / getPRODDBcopy        Get a copy of the PROD database"
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
                echo;echo
                ANSWER=`./ask.sh "Proceed ? Y/N <CR> " "N"`
                if [ `echo $ANSWER | tr A-Z a-z` == "y" ] 
                then
                  ./restoreProdDB.sh $LOCALBACKUPDIR $LOCALTARGETDB
                  tdb=$(cat todelete.data); rm todelete.data
                  feedback "PROD DB restored in local database : $tdb" "y"
                  LOCALTARGETDB="$tdb"
                  export LOCALTARGETDB="$tdb"
                fi
                ;;
    '21')
                echo
                echo; ls -l $LOCALBACKUPDIR/*.zip; echo; echo
                ANSWER=`./ask.sh "Proceed ? Y/N <CR> " "N"`
                if [ `echo $ANSWER | tr A-Z a-z` == "y" ] 
                then
                  log "Restoring the PROD images in $LOCALWEBDIR/images"
                  log "Unzipping LOCALBACKUPDIR/PROD-some-jpg-jpeg.zip"
                  unzip -x $LOCALBACKUPDIR/PROD-some-jpg-jpeg.zip -d $LOCALWEBDIR -o
                  log "Unzipping LOCALBACKUPDIR/PROD-webp-gif-svg.zip"
                  unzip -x $LOCALBACKUPDIR/PROD-webp-gif-svg.zip -d $LOCALWEBDIR -o
                  feedback "PROD images restored in local environment"
                fi
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
    '50')
                echo;echo
                ANSWER=`./ask.sh "Proceed ? Y/N <CR> " "N"`
                if [ `echo $ANSWER | tr A-Z a-z` == "y" ] 
                then
                  getPRODDBcopy
                fi
                ;;
    'log')      echo
                less $O2logs
                ;;    
    'x')        echo
                exit 0
                ;;    
    *)          feedback "Unknown command"
                ;;
  esac
  echo; ANSWER=`./ask.sh "Back to menu <CR> "`
}
#---------------------------------------------------------------------------------------
#   Get a backup of PROD db 
#---------------------------------------------------------------------------------------
getPRODDBcopy () {
  ssh -x "$O2USER@$O2HOST" <<-EOF
    echo;echo;echo "File root will be : $DATESIGNATURE"
    echo; ls -l ~/BACKUP
    DATESIGNATURE=`date +"%Y-%m-%d"`
    if [ -f BACKUP/$DATESIGNATURE-toba3789_PRODbomerle.sql ]
    then
      rm BACKUP/$DATESIGNATURE-toba3789_PRODbomerle.sql
    fi
    echo;env | grep SQL;echo
    echo;echo "Connect as $SQLUSER on $SQLPRODDB";echo
    mysqldump -u $SQLUSER --password=$SQLPASS --result-file=BACKUP/$DATESIGNATURE-$SQLPRODDB.sql $SQLPRODDB
    echo; ls -l ~/BACKUP
EOF
  echo;echo "scp $O2USER@$O2HOST:BACKUP/$DATESIGNATURE-$SQLPRODDB.sql ~/bomerleprocs/backups";echo
  scp $O2USER@$O2HOST:BACKUP/$DATESIGNATURE-$SQLPRODDB.sql ~/bomerleprocs/backups
}
#---------------------------------------------------------------------------------------
#   S T A R T   H E R E
#---------------------------------------------------------------------------------------
clear
echo ""
echo "$version"
echo ""
#---------------------------------------------------------------------------------------
#   menu input
#---------------------------------------------------------------------------------------
while [ 1 ]
do
  menu
  ANSWER=`./ask.sh "Enter a command listed above or X to exit : " "$lastcommand"`
  if [ -z $ANSWER ]
  then
    break
  else
    lastcommand=$ANSWER
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
