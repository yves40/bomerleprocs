#---------------------------------------------------------------------------------------
#   admin.sh
#---------------------------------------------------------------------------------------
#   Params
#---------------------------------------------------------------------------------------
version="admin.sh, Jul 30 2024 : 1.40 "
#---------------------------------------------------------------------------------------
#   Some parameters
#---------------------------------------------------------------------------------------
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
if [ ! -f $LOCALO2LOGS ]
then
  touch $LOCALO2LOGS
  log "ADMIN: Log file $LOCALO2LOGS initialized for Ratoon admin"
fi
#---------------------------------------------------------------------------------------
#   Some utility routine
#---------------------------------------------------------------------------------------
# Logger
#---------------------------------------------------------------------------------------
log() 
{
        echo "`date` : $version $1" >> $LOCALO2LOGS
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
                less $LOCALO2LOGS
                ;;    
    'x')        echo;echo "Latest actions";echo
                tail -n 10 $LOCALO2LOGS
                exit 0
                ;;    
    *)          log "ERR: Unknown command"
                ;;
  esac
  echo; ANSWER=`./ask.sh "Back to menu <CR> "`
}
#---------------------------------------------------------------------------------------
#   S U B   R O U T I N E S
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
    log "TOSWITCH: Copy PROD DB backup to O2switch DEV"
    DATESIGNATURE=`date +"%Y-%m-%d"`
    scp $DBFILE $O2USER@$O2HOST:BACKUP/$DATESIGNATURE-FROM-LOCAL-DB.sql
    log "TOSWITCH: Copy of PROD DB backup to O2switch DEV done: $DBFILE"
    log "ONSWITCH: Restore of PROD DB backup to DEV DB"
    ssh -x "$O2USER@$O2HOST" <<-EOF
    ls -l ~/BACKUP/$DATESIGNATURE-FROM-LOCAL-DB.sql
    mysql -u $REMOTESQLUSER --password=$REMOTESQLPASS $REMOTESQLDEVDB
      set autocommit=0;
      source ~/BACKUP/$DATESIGNATURE-FROM-LOCAL-DB.sql;
      commit;
      exit
EOF
    log "ONSWITCH: Restore of PROD DB backup to DEV DB: Done"
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
    log "TOSWITCH: Copy PROD images backup to O2switch DEV"
    DATESIGNATURE=`date +"%Y-%m-%d"`
    scp $GZFILE $O2USER@$O2HOST:BACKUP/$DATESIGNATURE-FROM-LOCAL-ALLIMAGES.tar.gz
    log "TOSWITCH: Copy PROD images backup to O2switch DEV: Done"
    log "ONSWITCH: Extract PROD images on O2switch DEV"
    ssh -x "$O2USER@$O2HOST" <<-EOF
    ls -l ~/BACKUP/*FROM*.gz
    cd $REMOTEDEV/public
    tar xvf ~/BACKUP/$DATESIGNATURE-FROM-LOCAL-ALLIMAGES.tar.gz
EOF
    echo;
    log "ONSWITCH: Extract PROD images on O2switch DEV: Done: $GZFILE"
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
    log "LOCAL: Restore a PROD DB backup locally"
    mysql --user=$LOCALMSQLUSER --password=$LOCALMSQLPASSWORD $TARGET  << EOF
      set autocommit=0;
      source $DBFILE ;
      commit;
      exit
EOF
    log "LOCAL: Restore a PROD DB backup locally: Done"
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
    log "LOCAL: Restoring the PROD images in $LOCALWEBDIR/public/images"
    tar xzvf $GZFILE
    cd $initdir
    log "LOCAL: Restoring the PROD images: Done"
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
    log "ONSWITCH: Get a copy of PROD images. Build the tar file"
    ssh -x "$O2USER@$O2HOST" <<-EOF
      echo;echo;echo "File root will be : $DATESIGNATURE"
      DATESIGNATURE=`date +"%Y-%m-%d"`
      if [ -f BACKUP/$DATESIGNATURE-PROD-ALLIMAGES.tar.gz ]
      then
        rm BACKUP/$DATESIGNATURE-PROD-ALLIMAGES.tar.gz
      fi
      echo;echo "Backup all PROD images";echo
      initdir=$(pwd)
      cd $REMOTEPROD/public
      tar czvf ~/BACKUP/$DATESIGNATURE-PROD-ALLIMAGES.tar.gz images
      cd $initdir
EOF
    log "ONSWITCH: Get a copy of PROD images. Build the tar file: Done"
    log "LOCAL: Copy PROD images tar file locally"
    scp $O2USER@$O2HOST:BACKUP/$DATESIGNATURE-PROD-ALLIMAGES.tar.gz ~/bomerleprocs/backups
    log "LOCAL: Copy PROD images tar file locally: Done"
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
    log "ONSWITCH: Get a copy of PROD DB. Build the SQL file"
    ssh -x "$O2USER@$O2HOST" <<-EOF
      echo;echo;echo "File root will be : $DATESIGNATURE"
      echo; ls -l ~/BACKUP
      DATESIGNATURE=`date +"%Y-%m-%d"`
      if [ -f BACKUP/$DATESIGNATURE-toba3789_PRODbomerle.sql ]
      then
        rm BACKUP/$DATESIGNATURE-toba3789_PRODbomerle.sql
      fi
      echo;echo "Connect as $SQLUSER on $REMOTESQLPRODDB";echo
      mysqldump -u $REMOTESQLUSER --password=$REMOTESQLPASS --result-file=BACKUP/$DATESIGNATURE-$REMOTESQLPRODDB.sql $REMOTESQLPRODDB
EOF
    log "ONSWITCH: Get a copy of PROD DB. Build the SQL file: Done"
    log "LOCAL: Copy PROD DB sql file locally"
    scp $O2USER@$O2HOST:BACKUP/$DATESIGNATURE-$REMOTESQLPRODDB.sql ~/bomerleprocs/backups
    log "LOCAL: Copy PROD DB sql file locally: Done"
  fi
}
#---------------------------------------------------------------------------------------
#   C H E C K   A L L   R E Q U I R E D   V A R I A B L E S    A R E    S E T 
#---------------------------------------------------------------------------------------
checkEnvironmentVariables()
{
  log 'ADMIN: Check environment variables'
  log 'ADMIN: These variables must be set in your .bashrc file'
  if [ -z $LOCALTARGETDB ]; then
    log "ERR: \$LOCALTARGETDB not set"
    log "INF: Set it to the default mysql DB which will be used"
    exit 1
  fi
  if [ -z $LOCALWEBDIR ]; then
    log "ERR: \$LOCALWEBDIR not set"
    log "INF: Set it to the location of your web project."
    log "INF: For example, \$HOME/bomerleprocs"
    exit 1
  fi
  if [ -z $LOCALBACKUPDIR]; then
    log "ERR: \$LOCALBACKUPDIR not set"
    log "INF: Set it to the location of your backup files."
    log "INF: For example, \$HOME/bomerleprocs/backups"
    exit 1
  fi
  if [ -z $LOCALPROCSDIR ]; then
    log "ERR: \$LOCALPROCSDIR not set"
    log "INF: Set it to the location of the admin shell script."
    log "INF: For example, \$HOME/bomerleprocs/local"
    exit 1
  fi
  if [ -z $LOCALO2LOGS ]; then
    log "ERR: \$LOCALO2LOGS not set"
    log "INF: Set it to the location of complete path of the admin log file."
    log "INF: For example, /tmp/O2ratoon-admin.log"
    exit 1
  fi
  if [ -z $REMOTEPROD ]; then
    log "ERR: \$REMOTEPROD not set"
    log "INF: Set it to the location of the PROD environment ON THE REMOTE SYSTEM."
    log "INF: For example, PROD/bomerle"
    exit 1
  fi
  if [ -z $REMOTEDEV ]; then
    log "ERR: \$REMOTEDEV not set"
    log "INF: Set it to the location of the DEV environment ON THE REMOTE SYSTEM."
    log "INF: For example, DEV/bomerle"
    exit 1
  fi
  # Now some MYSQL env
  if [ -z $LOCALMSQLUSER ]; then
    log "ERR: \$SQLUSER not set"
    log "INF: Set it to user ID managing the local mysql DB."
    exit 1
  fi
  if [ -z $LOCALMSQLPASSWORD ]; then
    log "ERR: \$SQLPASS not set"
    log "INF: Set it to user password managing the mysql DB."
    exit 1
  fi
  if [ -z $REMOTESQLPRODDB ]; then
    log "ERR: \$REMOTESQLPRODDB not set"
    log "INF: Set it to DB name for production data."
    exit 1
  fi
  if [ -z $REMOTESQLDEVDB ]; then
    log "ERR: \$REMOTESQLDEVDB not set"
    log "INF: Set it to DB name for development data."
    exit 1
  fi
}
#---------------------------------------------------------------------------------------
#   S T A R T   H E R E
#---------------------------------------------------------------------------------------
clear
echo ""
echo "$version"
echo ""
checkEnvironmentVariables
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
