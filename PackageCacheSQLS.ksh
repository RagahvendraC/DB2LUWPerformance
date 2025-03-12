#!/bin/ksh
###########################################################################################################################
# SCRIPT: PackageCacheSQLS.ksh
# AUTHOR: Raghavendra Chiyodu
# DATE  :05/03/2014
# Version : v1.0
#
# PURPOSE:
#          This script Displays the TOP 20 SQL Statements from the package cache based on different criterias
#
# Usage:                        [-I<Get the instance name>]
#                               [-D<Database name to connect to>]
#                               [-M<Mail id to which the logfile details would be sent>
#
 USAGE="
 Usage:  PackageCacheSQLS.ksh       [-I<Get the instance name>(mandatory)]
                                [-D<Database name to connect to>(mandatory)]
                                [-M<Mail id to which the logfile details would be sent>
      "
#
# Sample: ./PackageCacheSQLS.ksh   -i db2pr1 -d PR1  -m "rchiyodu@in.ibm.com"
#######################################################################################################################

#set -x
if [ -f $HOME/sqllib/db2profile ]; then
    . $HOME/sqllib/db2profile
fi

# Parse Input
   while getopts :h:I:i:D:d:M:m: OPT ; do
        case $OPT in
        h) echo "${USAGE}"
           exit 0
                ;;
        [Ii])LINSTNAME=`echo "${OPTARG}"`
                                ;;
        [Dd])LSTDATABASENAME=`echo "${OPTARG}"`
                                ;;
        [Mm])LMAILID=`echo "${OPTARG}"`
                                ;;
        *)      # Display the usage string
                echo "${USAGE}" 1>&2
                exit 1                ;;
        esac
   done

   shift `expr ${OPTIND} - 1`
#Make the validation for the instance name
   if test -z "${LINSTNAME}"
      then
        echo "${USAGE}"
        exit 1
        fi
        if [ "${LINSTNAME}" != $DB2INSTANCE ];then
        echo "Incorrect Instance name provided"
        echo "${USAGE}"
        exit 1
        fi


#Make Sure that the threeshold Value is entered
   if test -z "${LSTDATABASENAME}"
      then
        echo "${USAGE}"
        exit 1
        fi

        DBCHECK=`db2 list active databases |grep "${LSTDATABASENAME}" |wc -l`
if [ $DBCHECK -eq 0 ]; then
        tput bold
        echo "Incorrect Database Name Provided"
        tput rmso
        echo "${USAGE}"
        exit 1
 db2 connect to "${LSTDATABASENAME}" > /dev/null
        if test $? -gt 0
        then
        tput bold
        echo "Unable to connect to database. Check the Database Name provided as input"
        tput rmso
        exit 1
        fi
fi

#Make Sure that the threeshold Value is entered
   if test -z "${LMAILID}"
         then
        echo "${USAGE}"
        exit 1
   fi


echo "Please find the Top 10 SQL's in the database based on Total Execution Time,Average Execution Time,Average CPU Time,Number of Executions, Number of Sorts">SQLRankpkg.out

echo "#######################################################################################################################################################\n\n">>SQLRankpkg.out

#Get the TOP 20 SQLS by the Rows Read and Rows Written values

echo " 1) Top 20 SQL's in the package cache based on Rows Selectivity with Rows Read and Rows Written\n\n">>SQLRanKpkg.out

echo "&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&">>SQLRankpkg.out

db2 "select MEMBER,ROWS_READ,ROWS_RETURNED,case when ROWS_RETURNED = 0 then null else ROWS_READ / ROWS_RETURNED end as "Read / Returned",TOTAL_SECTION_SORTS,SORT_OVERFLOWS,TOTAL_SECTION_SORT_TIME,
case when TOTAL_SECTION_SORTS = 0 then null else TOTAL_SECTION_SORT_TIME / TOTAL_SECTION_SORTS end as "Time / sort",NUM_EXECUTIONS,substr(STMT_TEXT,1,40) as stmt_text from table(mon_get_pkg_cache_stmt(null,null,null,-2)) as t order by rows_read desc fetch first 20 rows only">>SQLRankpkg.out
      if test $? -gt 0 ; then
         echo "Error in getting TOP 20 SQL's by Rows Read/Rows Returned">>SQLRankpkg.out
      fi
              if test $? -gt 0 ; then 
                     echo "Error in getting the Top 20 SQL's in the database">>SQLRankpkg.out
              fi

#Get the Top 20 SQLS by Total CPU time and the Number of Executions

echo " 2) Top 20 SQL's in the package cache based on the Total CPU Time and Number of Executions">>SQLRankpkg.out

echo"&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&">>SQLRankpkg.out

db2 "select MEMBER,TOTAL_ACT_TIME,TOTAL_CPU_TIME,(TOTAL_CPU_TIME+500) / 1000 as "TOTAL_CPU_TIME",TOTAL_SECTION_SORT_PROC_TIME,NUM_EXECUTIONS,substr(STMT_TEXT,1,40) as stmt_text from table(mon_get_pkg_cache_stmt(null,null,null,-2)) as t order by TOTAL_CPU_TIME desc fetch first 20 rows only">>SQLRankpkg.out
               if test $? -gt 0 ; then
                       echo "No Top 20 SQLS Found by Toal Cpu Time and Number of Executions">>SQLRankpkg.out
              fi

#Get the Top 20 SQLS by the criteria of sort overflows

echo " 3) Top 20 SQL's in the package cache that has sort overflows\n\n">>SQLRankpkg.out

echo"&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&">>SQLRankpkg.out


db2 "select MEMBER, ROWS_READ / NUM_EXEC_WITH_METRICS as "ROWS_READ / exec",ROWS_RETURNED / NUM_EXEC_WITH_METRICS as "ROWS_RETURNED / exec",
case when ROWS_RETURNED = 0 then null else ROWS_READ / ROWS_RETURNED end as "Read / Returned",TOTAL_SECTION_SORTS / NUM_EXEC_WITH_METRICS as "TOTAL_SECTION_SORTS / exec",
SORT_OVERFLOWS / NUM_EXEC_WITH_METRICS as "SORT_OVERFLOWS / exec",TOTAL_SECTION_SORT_TIME / NUM_EXEC_WITH_METRICS as "TOTAL_SECTION_SORT_TIME / exec",
case when TOTAL_SECTION_SORTS = 0 then null else TOTAL_SECTION_SORT_TIME / TOTAL_SECTION_SORTS end as "Time / sort",
NUM_EXEC_WITH_METRICS,substr(STMT_TEXT,1,40) as STMT_TEXT from table(mon_get_pkg_cache_stmt(null,null,null,-2)) as t
where NUM_EXEC_WITH_METRICS > 0 order by ROWS_READ / NUM_EXEC_WITH_METRICS desc fetch first 20 rows only">>SQLRankpkg.out
       if test $? -gt 0 ; then
             echo "No Top 20 SQLS that has sort overflows">>SQLRankpkg.out
       fi
               if test $? -gt 0 ; then
                    echo "There is no data for the Top 20 SQL's that has sort overflows">>SQLRankpkg.out
               fi

#Get the Top 20 SQLS by actual times

echo " 4) Top 20 SQL's in the package cache based on actual times \n\n">>SQLRankpkg.out

echo"&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&">>SQLRankpkg.out

db2 "select MEMBER,TOTAL_ACT_TIME / NUM_EXEC_WITH_M_EMETRICS as "TOTAL_ACT_TIME / exec",TOTAL_CPU_TIME / NUM_EXEC_WITH_METRICS as "TOTAL_CPU_TIME / exec",
(TOTAL_CPU_TIME+500) / NUM_EXEC_WITH_METRICS / 1000 as "TOTAL_CPU_TIME / exec (ms)",TOTAL_SECTION_SORT_PROC_TIME / NUM_EXEC_WITH_METRICS as "TOTAL_SECTION_SORT_PROC_TIME / exec",
NUM_EXEC_WITH_METRICS,substr(STMT_TEXT,1,40) as STMT_TEXT from table(mon_get_pkg_cache_stmt(null,null,null,-2)) as t
where NUM_EXEC_WITH_METRICS > 0 order by TOTAL_CPU_TIME / NUXEC_WITH_METRICS desc fetch first 20 rows only">>SQLRankpkg.out
               if test $? -gt 0 ; then
                        echo "No Top 10 SQLs Found based on actual times">>SQLRankpkg.out
               fi
                      if test $? -gt 0 ; then
                          echo "There are no top10 sqls found in the database based on actual times">>SQLRankpkg.out
                      fi
#Get the Top 20 SQLS by Lock-wait times

echo "5 ) Top 20 SQL's in the package cache based on the Loc-wait times\n\n">>SQLRankpkg.out

echo"&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&&">>SQLRankpkg.out

db2 "select MEMBER,TOTAL_ACT_TIME / NUM_EXEC_WITH_METRICS as "TOTAL_ACT_TIME / exec",TOTAL_ACT_WAIT_TIME / NUM_EXEC_WITH_METRICS as "TOTAL_ACT_WAIT_TIME / exec",
LOCK_WAIT_TIME / NUM_EXEC_WITH_METRICS as "LOCK_WAIT_TIME / exec",(FCM_SEND_WAIT_TIME+FCM_RECV_WAIT_TIME) / NUM_EXEC_WITH_METRICS as "FCM wait time / exec",
LOCK_TIMEOUTS / NUM_EXEC_WITH_METRICS as "LOCK_TIMEOUTS / exec",LOG_BUFFER_WAIT_TIME / NUM_EXEC_WITH_METRICS as "LOG_BUFFER_WAIT_TIME / exec",
LOG_DISK_WAIT_TIME / NUM_EXEC_WITH_METRICS as "LOG_DISK_WAIT_TIME / exec",(TOTAL_SECTION_SORT_TIME-TOTAL_SECTION_SORT_PROC_TIME) / num_executions as "Sort wait time / exec",NUM_EXEC_WITH_METRICS,substr(STMT_TEXT,1,40) as STMT_TEXT from table(mon_get_pkg_cache_stmt(null,null,null,-2)) as t
where NUM_EXEC_WITH_METRICS > 0 order by TOTAL_ACT_WAIT_TIME / NUM_EXEC_WITH_METRICS desc fetch first 20 rows only">>SQLRankpkg.out
     if test $? -gt 0 ; then
              echo "No TOP 10 SQL's found by Lock-wait times">>SQLRankpkg.out
     fi

                 if test $? -gt 0 ; then 
                      echo "There is no Top 10 SQL's found based on Lock-wait times in the database">>SQLRankpkg.out
                 fi

cat SQLRankpkg.out | mailx -s "Top 10 Rank SQLS in the database  "${LSTDATABASENAME}"  " "${LMAILID}"

echo "########################################################################################################################################################">>SQLRankpkg.out

         


