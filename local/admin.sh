#---------------------------------------------------------------------------------------
#   admin.sh
#---------------------------------------------------------------------------------------
#   Params
#---------------------------------------------------------------------------------------
version="admin.sh, Sep 26 2024 : 1.30 "
#---------------------------------------------------------------------------------------
#   Some parameters
#---------------------------------------------------------------------------------------
LOCALTARGETDB="$LOCALTARGETDB"  # Get it from parent shell
LOCALWEBDIR="$HOME/bomerleprod"
LOCALBACKUPDIR="$HOME/bomerleprocs/backups"
LOCALPROCSDIR="$HOME/bomerleprocs/local"
lastcommand=""
DATESIGNATURE=`date +"%Y-%m-%d"`
PROD=PROD/bomerle
DEV=DEV/bomerle
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
if [ ! -f $O2LOGS ]
then
  touch $O2LOGS
  log "Log file initialized for Ratoon admin"
fi
#---------------------------------------------------------------------------------------
#   Some utility routine
#---------------------------------------------------------------------------------------
# Logger
#---------------------------------------------------------------------------------------
log() 
{
        echo "`date` : $version $1" >> $O2LOGS
        echo "`date` : $1"
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
  echo 
  echo 
  echo "-------------------------------------------------------------------------------"
  echo " L O C A L    A C T I O N S"
  echo "-------------------------------------------------------------------------------"
  echo "  10 / List the available PROD DB backups"
  echo "  11 / List the available PROD images backups"
  echo "  12 / List all DB and images backups"
  echo
  echo "  20 / Restore PROD DB in local mysql"
  echo "  21 / Restore PROD images in local WEB environment"
  echo "  22 / Restore PROD DB & images in local WEB environment"
  echo
  echo 
  echo "-------------------------------------------------------------------------------"
  echo " R E M O T E   A C T I O N S"
  echo "-------------------------------------------------------------------------------"
  echo "  O2switch PROD to LOCAL"; echo
  echo "  50 / Get a copy of the PROD database"
  echo "  51 / Get a copy of all PROD images"
  echo "  52 / Get a full copy of PROD site ( DB and images )"; echo
  echo "  LOCAL to O2switch DEV"; echo
  echo "  60 / Copy local PROD images backup to DEV"
  echo "  61 / Copy local PROD DB backup to DEV"
  echo "  62 / Push full local DEV to O2switch DEV"
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
    '10')
                echo; ls -l $LOCALBACKUPDIR/*.sql
                ;;
    '11')
                echo; ls -l $LOCALBACKUPDIR/*.gz
                ;;
    '12')
                echo; ls -l $LOCALBACKUPDIR
                ;;
    '20')       RestoreDB "PROD"
                ;;
    '21')       RestoreProdImages
                ;;    
    '22')       RestoreFullPROD
                ;;    
    '50')
                getPRODDBcopy
                ;;
    '51')
                getPRODImagescopy
                ;;
    '52')       getPRODFull
                ;;
    '60')       pushImagesToDEV
                ;;
    '61')       pushDBToDEV
                ;;
    '62')       pushFullDev
                ;;
    'log')      echo
                less $O2LOGS
                ;;    
    'x')        echo;echo "Latest actions";echo
                tail -n 10 $O2LOGS
                exit 0
                ;;    
    *)          log "Unknown command"
                ;;
  esac
  echo; ANSWER=`./ask.sh "Back to menu <CR> "`
}
#---------------------------------------------------------------------------------------
#   S U B   R O U T I N E S
#---------------------------------------------------------------------------------------
#   Push PROD DB backup to O2switch DEV
#   $1 'noninteractive' means confirmation has been already done
#---------------------------------------------------------------------------------------
pushDBToDEV() {
  echo
  if [ -z $1 ]
  then
    ANSWER=`./ask.sh "Proceed to copy PROD DB backup on O2switch DEV ? Y/N <CR> " "N"`
  else
    ANSWER='Y'
  fi
  if [ `echo $ANSWER | tr A-Z a-z` == "y" ] 
  then
    initdir=$(pwd)
    DBFILE=""
    TARGET=""
    initdir=`pwd`
    cd $LOCALBACKUPDIR
    echo; ls -l *PROD*.sql
    while [ "$DBFILE" = "" ]
    do
      echo; DBFILE=`$LOCALPROCSDIR/ask.sh "Which sql file ? "`
      if ! [ -f $DBFILE ]
      then
        echo "Please provide a valid file location "
        echo $DBFILE
        DBFILE=""
      fi
    done
    # Now proceed
    log "Copy PROD DB backup to O2switch DEV"
    DATESIGNATURE=`date +"%Y-%m-%d"`
    scp $DBFILE $O2USER@$O2HOST:BACKUP/$DATESIGNATURE-FROM-LOCAL-DB.sql
    log "Copy of PROD DB backup to O2switch DEV done: $DBFILE"
    log "Restore of PROD DB backup to DEV DB"
    ssh -x "$O2USER@$O2HOST" <<-EOF
    ls -l ~/BACKUP/$DATESIGNATURE-FROM-LOCAL-DB.sql
    mysql -u $SQLUSER --password=$SQLPASS $SQLDEVDB
      set autocommit=0;
      source ~/BACKUP/$DATESIGNATURE-FROM-LOCAL-DB.sql;
      commit;
      exit
EOF
    log "Restore of PROD DB backup to DEV DB done"
    cd $initdir
  fi
}
#---------------------------------------------------------------------------------------
#   Push PROD images backup to O2switch DEV
#   $1 'noninteractive' means confirmation has been already done
#---------------------------------------------------------------------------------------
pushImagesToDEV() {
  echo
  if [ -z $1 ]
  then
    ANSWER=`./ask.sh "Proceed to copy local PROD images backup on O2switch DEV ? Y/N <CR> " "N"`
  else
    ANSWER='Y'
  fi
  if [ `echo $ANSWER | tr A-Z a-z` == "y" ] 
  then
    echo; ls -l $LOCALBACKUPDIR/*.gz; echo; echo
    # Choose the compressed archive
    GZFILE=""
    while [ "$GZFILE" = "" ]
    do
      echo; GZFILE=`./ask.sh "Which archive file ? "`
      if ! [ -f $GZFILE ]
      then
        echo "Please provide a valid file location "
        echo $GZFILE
        GZFILE=""
      fi
    done
    # Now proceed
    initdir=$(pwd)
    log "Copy PROD images backup to O2switch DEV"
    DATESIGNATURE=`date +"%Y-%m-%d"`
    scp $GZFILE $O2USER@$O2HOST:BACKUP/$DATESIGNATURE-FROM-LOCAL-ALLIMAGES.tar.gz
    log "Copy PROD images backup to O2switch DEV: Done"
    log "Copy of PROD images backup to O2switch DEV"
    ssh -x "$O2USER@$O2HOST" <<-EOF
    ls -l ~/BACKUP/*FROM*.gz
    cd $DEV/public
    tar xvf ~/BACKUP/$DATESIGNATURE-FROM-LOCAL-ALLIMAGES.tar.gz
EOF
    echo;log "Copy of PROD images backup to O2switch DEV: done: $GZFILE"
    cd $initdir
  fi
}
#---------------------------------------------------------------------------------------
#   Restore PROD DB backup 
#   $1 is the DB type : PROD or DEV
#   $2 'noninteractive' means confirmation has been already done
#---------------------------------------------------------------------------------------
RestoreDB() {
  echo;echo
  if [ -z $2 ]
  then
    ANSWER=`./ask.sh "Proceed to DB restore in local environment ? Y/N <CR> " "N"`
  else
    echo "Restoring PROD DB in local environment"
    ANSWER='Y'
  fi
  if [ `echo $ANSWER | tr A-Z a-z` == "y" ] 
  then
    DBFILE=""
    TARGET=""
    initdir=`pwd`
    cd $LOCALBACKUPDIR
    echo; ls -l *$1*.sql
    while [ "$DBFILE" = "" ]
    do
      echo; DBFILE=`$LOCALPROCSDIR/ask.sh "Which sql file ? "`
      if ! [ -f $DBFILE ]
      then
        echo "Please provide a valid file location "
        echo $DBFILE
        DBFILE=""
      fi
    done
    while [ "$TARGET" = "" ]
    do
      echo; TARGET=`$LOCALPROCSDIR/ask.sh "Target DB ? " "$LOCALTARGETDB"`
    done
    # Ensure we do not have special MYSQL export directive on line 1
    # If so remove it
    grep 99999 $DBFILE > todelete
    if [ $? == 0 ]
    then
      echo "************ Stripped"
      tail -n +2 $DBFILE > "$DBFILE.strip"
      cp "$DBFILE.strip" $DBFILE
      rm "$DBFILE.strip"
    fi
    rm todelete
    # Restore the SQL file into the target DB
    echo
    echo
    echo "Restore now : $DBFILE"
    mysql --user=$MSQLUSER --password=$MSQLPASSWORD $TARGET  << EOF
      set autocommit=0;
      source $DBFILE ;
      commit;
      exit
EOF
    #rm todelete.sh
    export LOCALTARGETDB="$TARGET"
    cd $initdir
  fi
}
#---------------------------------------------------------------------------------------
#   Restore PROD images 
#   $1 'noninteractive' means confirmation has been already done
#---------------------------------------------------------------------------------------
RestoreProdImages () {
  echo
  if [ -z $1 ]
  then
    ANSWER=`./ask.sh "Proceed to images restore ? Y/N <CR> " "N"`
  else
    echo "Restoring PROD images in local environment"
    ANSWER='Y'
  fi
  if [ `echo $ANSWER | tr A-Z a-z` == "y" ] 
  then
    echo; ls -l $LOCALBACKUPDIR/*.gz; echo; echo
    # Choose the compressed archive
    GZFILE=""
    while [ "$GZFILE" = "" ]
    do
      echo; GZFILE=`./ask.sh "Which archive file ? "`
      if ! [ -f $GZFILE ]
      then
        echo "Please provide a valid file location "
        echo $GZFILE
        GZFILE=""
      fi
    done
    # Now proceed
    initdir=$(pwd)
    cd $LOCALWEBDIR/public
    log "Restoring the PROD images in $LOCALWEBDIR/public/images"
    tar xzvf $GZFILE
    cd $initdir
    log "PROD images restored in local environment"
  fi
}
#---------------------------------------------------------------------------------------
#   Push local dev environment to o2 
#---------------------------------------------------------------------------------------
pushFullDev() {
  echo;echo
  ANSWER=`./ask.sh "Proceed to Push local dev environment to o2 ? Y/N <CR> " "N"`
  if [ `echo $ANSWER | tr A-Z a-z` == "y" ] 
  then
    pushImagesToDEV "nointeractive"  
    pushDBToDEV "nointeractive"  
  fi
}
#---------------------------------------------------------------------------------------
#   Get full PROD 
#---------------------------------------------------------------------------------------
RestoreFullPROD() {
  echo;echo
  ANSWER=`./ask.sh "Proceed to restore full PROD locally ? Y/N <CR> " "N"`
  if [ `echo $ANSWER | tr A-Z a-z` == "y" ] 
  then
    RestoreProdImages "nointeractive"
    RestoreDB "PROD" "nointeractive" 
  fi
}
#---------------------------------------------------------------------------------------
#   Get Full PROD site copy 
#---------------------------------------------------------------------------------------
getPRODFull() {
  echo;echo
  ANSWER=`./ask.sh "Proceed to full PROD copy (images and DB) ? Y/N <CR> " "N"`
  if [ `echo $ANSWER | tr A-Z a-z` == "y" ] 
  then
    getPRODDBcopy "nointeractive"
    getPRODImagescopy "nointeractive"
    echo; ls -l $LOCALBACKUPDIR/*PROD*;echo
  fi
}
#---------------------------------------------------------------------------------------
#   Get PROD images 
#   $1 'noninteractive' means confirmation has been already done
#---------------------------------------------------------------------------------------
getPRODImagescopy () {
  echo;echo
  if [ -z $1 ]
  then
    ANSWER=`./ask.sh "Proceed to PROD images copy ? Y/N <CR> " "N"`
  else
    ANSWER='Y'
  fi
  if [ `echo $ANSWER | tr A-Z a-z` == "y" ] 
  then
    ssh -x "$O2USER@$O2HOST" <<-EOF
      echo;echo;echo "File root will be : $DATESIGNATURE"
      DATESIGNATURE=`date +"%Y-%m-%d"`
      if [ -f BACKUP/$DATESIGNATURE-PROD-ALLIMAGES.tar.gz ]
      then
        rm BACKUP/$DATESIGNATURE-PROD-ALLIMAGES.tar.gz
      fi
      echo;echo "Backup all PROD images";echo
      initdir=$(pwd)
      cd $PROD/public
      tar czvf ~/BACKUP/$DATESIGNATURE-PROD-ALLIMAGES.tar.gz images
      cd $initdir
EOF
    scp $O2USER@$O2HOST:BACKUP/$DATESIGNATURE-PROD-ALLIMAGES.tar.gz ~/bomerleprocs/backups
  fi
}
#---------------------------------------------------------------------------------------
#   Get PROD db
#   $1 'noninteractive' means confirmation has been already done
#---------------------------------------------------------------------------------------
getPRODDBcopy () {
  echo;echo
  if [ -z $1 ]
  then
    ANSWER=`./ask.sh "Proceed to PROD DB copy ? Y/N <CR> " "N"`
  else
    ANSWER='Y'
  fi
  if [ `echo $ANSWER | tr A-Z a-z` == "y" ] 
  then
    ssh -x "$O2USER@$O2HOST" <<-EOF
      echo;echo;echo "File root will be : $DATESIGNATURE"
      echo; ls -l ~/BACKUP
      DATESIGNATURE=`date +"%Y-%m-%d"`
      if [ -f BACKUP/$DATESIGNATURE-toba3789_PRODbomerle.sql ]
      then
        rm BACKUP/$DATESIGNATURE-toba3789_PRODbomerle.sql
      fi
      echo;echo "Connect as $SQLUSER on $SQLPRODDB";echo
      mysqldump -u $SQLUSER --password=$SQLPASS --result-file=BACKUP/$DATESIGNATURE-$SQLPRODDB.sql $SQLPRODDB
EOF
    scp $O2USER@$O2HOST:BACKUP/$DATESIGNATURE-$SQLPRODDB.sql ~/bomerleprocs/backups
  fi
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
