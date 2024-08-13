#---------------------------------------------------------------------------------------
#   admin.sh
#---------------------------------------------------------------------------------------
#   Params
#---------------------------------------------------------------------------------------
version="admin.sh, Aug 13 2024 : 1.20 "
#---------------------------------------------------------------------------------------
#   Some parameters
#---------------------------------------------------------------------------------------
LOCALTARGETDB="$LOCALTARGETDB"  # Get it from parent shell
LOCALWEBDIR="$HOME/bomerleprod"
LOCALBACKUPDIR="$HOME/bomerleprocs/backups"
FEEDBACK=""
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
  echo "[ $version ]";echo
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
  echo "  10 / List the available PROD DB backups"
  echo "  11 / List the available PROD images backups"
  echo "  12 / List all DB and images backups"
  echo
  echo "  20 / Restore PROD DB in local mysql"
  echo "  21 / Restore PROD images in local WEB environment"
  echo
  echo 
  echo "-------------------------------------------------------------------------------"
  echo " R E M O T E   A C T I O N S"
  echo "-------------------------------------------------------------------------------"
  echo "  50 / Get a copy of the PROD database"
  echo "  51 / Get a copy of all PROD images"
  echo "  52 / Get a full copy of PROD site ( DB and images )"
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
    '50')
                getPRODDBcopy
                ;;
    '51')
                getPRODImagescopy
                ;;
    '52')       getPRODFull
                ;;
    'log')      echo
                less $O2LOGS
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
#   S U B   R O U T I N E S
#---------------------------------------------------------------------------------------
#   Restore PROD DB backup 
#   $1 is the DB type : PROD or DEV
#---------------------------------------------------------------------------------------
RestoreDB() {
  echo;echo
  ANSWER=`./ask.sh "Proceed ? Y/N <CR> " "N"`
  if [ `echo $ANSWER | tr A-Z a-z` == "y" ] 
  then
    DBFILE=""
    TARGET=""
    initdir=`pwd`
    echo; ls -l $LOCALBACKUPDIR/*$1*.sql
    while [ "$DBFILE" = "" ]
    do
      echo; DBFILE=`./ask.sh "Which sql file ? "`
      if ! [ -f $DBFILE ]
      then
        echo "Please provide a valid file location "
        echo $DBFILE
        DBFILE=""
      fi
    done
    while [ "$TARGET" = "" ]
    do
      echo; TARGET=`./ask.sh "Target DB ? " "$LOCALTARGETDB"`
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

    export LOCALTARGETDB="$TARGET"
    cd $initdir
  fi
}
#---------------------------------------------------------------------------------------
#   Restore PROD images 
#---------------------------------------------------------------------------------------
RestoreProdImages () {
  echo
  ANSWER=`./ask.sh "Proceed ? Y/N <CR> " "N"`
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
    feedback "Restoring the PROD images in $LOCALWEBDIR/public/images"
    tar xzvf $GZFILE
    cd $initdir
    feedback "PROD images restored in local environment"
  fi
}
#---------------------------------------------------------------------------------------
#   Get Full PROD site copy 
#---------------------------------------------------------------------------------------
getPRODFull() {
  echo;echo
  ANSWER=`./ask.sh "Proceed ? Y/N <CR> " "N"`
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
    ANSWER=`./ask.sh "Proceed ? Y/N <CR> " "N"`
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
    ANSWER=`./ask.sh "Proceed ? Y/N <CR> " "N"`
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
#---------------------------------------------------------------------------------------
#   Summary 
#---------------------------------------------------------------------------------------
echo ""
echo ""
echo ""
feedback "Exit admin.sh for O2-Ratoon site"
