#!/bin/ksh
############################################################################################################
#Author : Raghavendra Chiyodu
#Script : Db2_Memory_Check.ksh 
#Description : This script can be used to check the Db2 Memory sets and Db2 Memory Pools details 
############################################################################################################
db2 connect to $1>>/dev/null
      if test $? -gt 0 ; then
          echo "Error in connecting to the database"
      fi

#Get the Memory Pool metrics for the instance and the database
echo "Retrieve memory Pool metrics for the current instance and the currently connected database" 
db2 "SELECT varchar(memory_set_type, 20) AS set_type,varchar(memory_pool_type,20) AS pool_type,varchar(db_name, 20) AS dbname,memory_pool_used,FROM TABLE( 
       MON_GET_MEMORY_POOL(NULL, CURRENT_SERVER, -2))"       
         if test $? -gt 0 ; then
            echo "Error in getting the Memory Set metrics details" 
         fi


#Retrieve memory set metrics for the current instance and the currently connected database. 
echo "Retrieve memory set metrics for the current instance and the currently connected database"
db2 "SELECT varchar(memory_set_type, 20) as set_type,varchar(db_name, 20) as dbname,memory_set_used,memory_set_used_hwm from TABLEMON_GET_MEMORY_SET(NULL, CURRENT_SERVER, -2))"    
        if test $? -gt 0 ; then
            echo "Error in getting the Memory Set metrics" 
        fi

db2 connect reset