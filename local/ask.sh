#---------------------------------------------------------------------------------------
#    ask.sh
#
#    Oct 12 2013  Initial
#    jan 06 2017  Initial
#---------------------------------------------------------------------------------------
# A S K 
# $1 is a prompt string
# $2 is a default answer
# $3 is a possible answer. In that case, $2 and $3 are the only accepted answers
#---------------------------------------------------------------------------------------
if [ $# -eq 1 ]
then
   echo -n "$1" >&2
   read TMPVAR
   echo $TMPVAR
elif [ $# -eq 2 ]
then
   echo -n "$1 [$2] "  >&2
   read TMPVAR
   if [ -z "$TMPVAR" ]
   then 
        echo $2
   else
        echo $TMPVAR
   fi
elif [ $# -eq 3 ]
then
   defaultanswer=`echo $2 | tr a-z A-Z`
   alternative=`echo $3 | tr a-z A-Z`
   while true
   do
        echo -n "$1 [$2/$3] " >&2
        read TMPVAR
        if [ -z "$TMPVAR" ]
        then
             echo $2
             break
        else
             answer=`echo $TMPVAR | tr a-z A-Z`
             [ "$answer" = "$defaultanswer" ]  && break
             [ "$answer" = "$alternative" ]  && break
             if [ "$answer" = "X" ]
             then
                  kill -9 0
             fi
        fi
   done
   echo $TMPVAR
fi
