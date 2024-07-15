#---------------------------------------------------------------------------------------
#   restoreProdDB.sh
#
#   Jul 13 2024 Initial
#---------------------------------------------------------------------------------------
#   Params
#---------------------------------------------------------------------------------------
version="restoreProdDB.sh, Jul 13 2024 : 1.00 "
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
echo; ls -l $1/*.sql
while [ "$DBFILE" = "" ]
do
  echo; DBFILE=`./ask.sh "Which sql file ? "`
done
while [ "$TARGET" = "" ]
do
  echo; TARGET=`./ask.sh "Target DB ? " "$2"`
done
log "Restore export file $DBFILE to $TARGET database"
echo "$TARGET" > todelete.data
