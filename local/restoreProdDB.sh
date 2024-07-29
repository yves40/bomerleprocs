#---------------------------------------------------------------------------------------
#   restoreProdDB.sh
#---------------------------------------------------------------------------------------
#   Params
#---------------------------------------------------------------------------------------
version="restoreProdDB.sh, Jul 29 2024 : 1.04 "
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

DBFILE=""
TARGET=""
initdir=`pwd`
cd $1
echo; ls -l *.sql
cd $initdir
while [ "$DBFILE" = "" ]
do
  echo; DBFILE=`./ask.sh "Which sql file ? "`
  echo $DBFILE
  if ! [ -f $1/$DBFILE ]
  then
    echo "Please provide a valid file location "
    DBFILE=""
  fi
done
while [ "$TARGET" = "" ]
do
  echo; TARGET=`./ask.sh "Target DB ? " "$2"`
done
echo
echo
cd $1
log "mysql --user=$MSQLUSER --password=$MSQLPASSWORD $TARGET"

echo "set autocommit=0;" > todelete.sql
echo "source $DBFILE ;" >> todelete.sql
echo "commit;" >> todelete.sql
echo "exit" >> todelete.sql
cat todelete.sql

mysql --user=$MSQLUSER --password=$MSQLPASSWORD $TARGET < todelete.sql
# mysql --user=$MSQLUSER --password=$MSQLPASSWORD $TARGET  << EOF
# source $DBFILE
# EOF
cd $initdir

log "Restore export file $DBFILE to $TARGET database"
echo "$TARGET" > todelete.data
