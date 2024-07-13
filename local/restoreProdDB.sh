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
feedback() 
{
        FEEDBACK="`date` : $1"
        if [ ! -z $2 ]
        then
          echo $1
          echo
        fi
}

echo; ls -l $1/*.sql
echo; DB=`./ask.sh "Which one ? "`
TARGET=`./ask.sh "Target DB ? " "$2"`
./log.sh "Restore $DB to $TARGET"
./feedback.sh "PROD DB restored in local environment" "Y"
echo; ANSWER=`./ask.sh "Back to menu <CR>"`
