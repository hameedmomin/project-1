#!/bin/ksh
# ==========================================
# OraDBInfo
# Oracle - DB Provide Database Information :
#   - Database Name
#   - Database Version
#   - Archivelog Mode
#   - Database Size
#   - Users list and rights
#   - Tablespaces
#   - Instance parameters
# -----------------------------------------
# Author : Pascal ALBOUY
#   V1.0 : Hypermonitoring checks
#   V1.1 : Modifing script to check DB
#          for Patch project (Fabien MONS)
#   V1.2 : Script improvement (Fabien MONS)
#           - Add Users list & rights
#           - improving report readablity
#           - Add Standby message
#   V1.3 : Script improvement (Fabien MONS)
#           - Add Primary or Standby host server
#           - Add Instance parameters
#           - Add characterset
#           - Add Server name
#   V1.4 : Script improvement (Fabien MONS)
#           - Add Profile for users
#           - Add Admin option for privileges and roles
#   V1.5 : Adding sessions list requested by DB Factory
# -----------------------------------------
# Parameter :
#   $1 : ORACLE_SID of the DB
# ==========================================
#set -x
script=`basename $0`
db=$1

# Extention to use
# ----------------
EXT="txt"
#EXT="lst"

export RetCode=0

check_fs()
{
#-----------------------------------------------------------------------------------
## df -kh or bdf
if [ "$quoi" = "HP-UX" ]
then
nb=`bdf | egrep '100%|99%|98%' | wc -l`
  if [ $nb -gt 0 ]
  then
    FILESYSTEM=" KO "
	RetCode=$RetCode+1
  else
    FILESYSTEM=" OK "
  fi
else
nb=`df -k | egrep '100%|99%|98%' | wc -l`
  if [ $nb -gt 0 ]
  then
    FILESYSTEM=" KO "
	RetCode=$RetCode+1
  else
    FILESYSTEM=" OK "
  fi
fi
#-----------------------------------------------------------------------------------
}

check_listener()
{
#-----------------------------------------------------------------------------------
# Listener actif and service sur Db
listen=`lsnrctl status | grep $db | grep "Service" | wc -l`
if [ $? -eq 0 ] && [ $listen -gt 0 ]
then
#  if [ -f $TNS_ADMIN/sqlnet.ora ]
#  then
#    cat $TNS_ADMIN/sqlnet.ora | sed '1,\$s/TNSNAMES/TNSNAMES,EZCONNECT/'
#  else
#    echo "NAMES.DIRECTORY_PATH= (TNSNAMES,EZCONNECT) " >> $TNS_ADMIN/sqlnet.ora
#  fi
#  listen=`lsnrctl status | grep $db | grep Service | cut -d'"' -f2 | head -1`
#  sqlplus sys@\"$ou:1521/$listen\" as sysdba << EOF
#  exit
#EOF
#  res=$?
#  if [ $res -eq 0 ]
#  then
    LISTENER=" OK "
#  else
#    LISTENER="<td> <font color="red"> KO </font> </td>"
#  fi
else
  LISTENER=" KO "
  RetCode=$RetCode+1
fi
#-----------------------------------------------------------------------------------
}


# looking for database environment
ORAENV_ASK="NO"
HOME=`echo ~`
cd ${HOME}
. ${HOME}/.profile > /dev/null 2>&1
if [ -f ${HOME}/ofa??? ]
then
  # German Database with ofaxxx script
  ofa=`ls -1 $HOME/ofa???|head -1`
  . $ofa ${db} > /dev/null 2>&1
else
  export RAC=${EXPL:-/home/oracle/tools}
  [[ -f ${RAC}/bin/ora_include ]] && . ${RAC}/bin/ora_include
  [[ -f ${RAC}/bin/ostd_include ]] && . ${RAC}/bin/ostd_include
  ora_inst_setenv ${db} 2>/dev/null 1>/dev/null
  if [ $? -ne 0 ]
  then
    if [ -f ${ORACLE_HOME}/bin/oraenv ]
    then
      ORACLE_SID=${db}
      ORAENV_ASK="NO"
      echo " Lancement de ${ORACLE_HOME}/bin/oraenv"
      . ${ORACLE_HOME}/bin/oraenv
    else
      ORACLE_SID=${db}
      ORAENV_ASK="NO"
      echo " Lancement de /usr/local/bin/oraenv"
      . /usr/local/bin/oraenv
    fi
  fi
fi

ou=`uname -n | cut -d'.' -f1`
quoi=`uname -s`
result=/tmp/"$script"_"$db"_"$ou"."$EXT"
>$result
result2=/tmp/"$script"_"$db"_"$ou".lst2
>$result2

#-----------------------------------------------------------------------------------
# Base active
active=`ps -edf | grep pmon | grep $db | wc -l`
res=$?
if [ $res -eq 0 ] && [ $active -eq 1 ]
then
  KO="N"
else
  KO="Y"
  RetCode=$RetCode+1
fi

if [ "$KO" = "Y" ]
then
#--------------
# Base Inactive
#--------------

check_fs
check_listener

echo "Alert : Database is not running" >>$result
echo 'Check FS :'$FILESYSTEM >> $result
echo 'Check Listener Status : '$LISTENER >> $result

else

# -----------
# Base active
# -----------

# Dataguard status
sqlplus -s '/ as sysdba' <<EOF >/tmp/quisuisje$$ 2>&1
set verify off;
set feedback off;
set pagesize 0;
set recsep off;
set tab off;
select 'Database Role:'||DATABASE_ROLE||':'
from V\$DATABASE;
EOF
DB_ROLE=`head -1 /tmp/quisuisje$$ | tail -1 | cut -d':' -f2`
rm -f /tmp/quisuisje$$ 

if [[ ( "$DB_ROLE" = "PRIMARY" ) ]]
then
#-----------------------------------------------------------------------------------
# Database Name
sqlplus -s '/ as sysdba' <<EOF >/tmp/quisuisje$$ 2>&1
set verify off;
set feedback off;
set pagesize 0;
set recsep off;
set tab off;
select 'DATABASE NAME: '||NAME
from V\$DATABASE;
EOF
DB_NAME=`head -1 /tmp/quisuisje$$ | tail -1`
rm -f /tmp/quisuisje$$

echo $DB_NAME >> $result

#-----------------------------------------------------------------------------------
# Server Name
SERVER_NAME=`hostname --fqdn`
echo "SERVER NAME: $SERVER_NAME" >> $result


#-----------------------------------------------------------------------------------
# Look for Release
sqlplus -s '/ as sysdba' <<EOF >/tmp/release$$ 2>&1
set verify off;
set feedback off;
set pagesize 0;
set recsep off;
set tab off;
select 'RELEASE: '||version from v\$instance;
EOF
RELEASE=`head -1 /tmp/release$$ | tail -1`

echo $RELEASE >> $result
rm /tmp/release$$

#-----------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------
# Look for Archivelog mode
sqlplus -s '/ as sysdba' <<EOF >/tmp/archivelog$$ 2>&1
set verify off;
set feedback off;
set pagesize 0;
set recsep off;
set tab off;
select 'ARCHIVELOG MODE: '||LOG_MODE from v\$database;
EOF
ARCHIVELOG=`head -1 /tmp/archivelog$$ | tail -1`

echo $ARCHIVELOG >> $result
rm /tmp/archivelog$$

#-----------------------------------------------------------------------------------
# Look for CHARACTERSET
sqlplus -s '/ as sysdba' <<EOF >/tmp/characterset$$ 2>&1
set verify off;
set feedback off;
set pagesize 0;
set recsep off;
set tab off;
SELECT 'CHARACTERSET: '||VALUE FROM nls_database_parameters where PARAMETER = 'NLS_CHARACTERSET';
EOF
CHARACTERSET=`head -1 /tmp/characterset$$ | tail -1`

echo $CHARACTERSET >> $result
rm /tmp/characterset$$

#-----------------------------------------------------------------------------------
# Look for NATIONAL CHARACTERSET
sqlplus -s '/ as sysdba' <<EOF >/tmp/ncharacterset$$ 2>&1
set verify off;
set feedback off;
set pagesize 0;
set recsep off;
set tab off;
SELECT 'NATIONAL CHARACTERSET: '||VALUE FROM nls_database_parameters where PARAMETER = 'NLS_NCHAR_CHARACTERSET';
EOF
N_CHARACTERSET=`head -1 /tmp/ncharacterset$$ | tail -1`

echo $N_CHARACTERSET >> $result
rm /tmp/ncharacterset$$

#-----------------------------------------------------------------------------------
echo "" >> $result
#echo "Database size :" >> $result
sqlplus -s '/ as sysdba' <<EOF >/tmp/db_size$$ 2>&1
set verify off;
set feedback off;
set pagesize 5;
set recsep off;
set tab off;
col Dbsize heading "Database Size" for a20
col Uspace heading "Used space" for a12
col Fspace heading "Free space" for a12
select round(sum(used.bytes) / 1024 / 1024 / 1024 ) || ' GB' Dbsize
      , round(sum(used.bytes) / 1024 / 1024 / 1024 ) - round(free.p / 1024 / 1024 / 1024) || ' GB' Uspace
      , round(free.p / 1024 / 1024 / 1024) || ' GB' Fspace
from  (select bytes from v\$datafile
     union all
       select bytes from v\$tempfile
     union all
       select bytes from v\$log) used
             ,(select sum(bytes) as p from dba_free_space) free
group by free.p;
EOF
cat /tmp/db_size$$ >> $result
rm /tmp/db_size$$

#-----------------------------------------------------------------------------------
# Users list
echo "" >> $result
echo "" >> $result
echo "Users list :" >> $result
sqlplus -s '/ as sysdba' <<EOF >/tmp/users_list$$ 2>&1
set linesize 200;
set verify off;
set feedback off;
set pagesize 70;
set recsep off;
set tab off;
col uname heading "Username" for a20
col astatus heading "Account status" for a16
col deftbs heading "Default Tablespace" for a30
col temptbs heading "Temporary tablespace" for a30
col profil heading "Profile" for a20
select USERNAME uname, ACCOUNT_STATUS astatus, DEFAULT_TABLESPACE deftbs, TEMPORARY_TABLESPACE temptbs, PROFILE profil from dba_users
where USERNAME not in('SYSTEM','SYS','ORACLE','FLEXERA','DIP','XS\$NULL','ORACLE_OCM','DBSNMP','XDB','ANONYMOUS','CTXSYS','APPQOSSYS','WMSYS','EXFSYS','OUTLN','PATROL');
EOF
cat /tmp/users_list$$ >> $result
rm /tmp/users_list$$
#-----------------------------------------------------------------------------------
# Users rights
echo "" >> $result
echo "Users rights :" >> $result
sqlplus -s '/ as sysdba' <<EOF >/tmp/users_rights$$ 2>&1
set verify off;
set feedback off;
set pagesize 100;
set recsep off;
set tab off;
col uname heading "Username" for a20
col rg heading "Role Granted" for a30
col priv heading "Privilege Granted" for a30
col adminopt heading "Admin option ?" for a15
select GRANTEE uname, GRANTED_ROLE rg, ADMIN_OPTION adminopt from dba_role_privs
where GRANTEE in(select USERNAME from dba_users where USERNAME not in('SYSTEM','SYS','ORACLE','FLEXERA','DIP','XS\$NULL','ORACLE_OCM','DBSNMP','XDB','ANONYMOUS','CTXSYS','APPQOSSYS','WMSYS','EXFSYS','OUTLN','PATROL'))
order by 1;
select GRANTEE uname, PRIVILEGE priv, ADMIN_OPTION adminopt from dba_sys_privs
where GRANTEE in(select USERNAME from dba_users where USERNAME not in('SYSTEM','SYS','ORACLE','FLEXERA','DIP','XS\$NULL','ORACLE_OCM','DBSNMP','XDB','ANONYMOUS','CTXSYS','APPQOSSYS','WMSYS','EXFSYS','OUTLN','PATROL'))
order by 1;
EOF
cat /tmp/users_rights$$ >> $result
rm /tmp/users_rights$$

#-----------------------------------------------------------------------------------
# QUOTA
echo "" >> $result
echo "Quotas :" >> $result
sqlplus -s '/ as sysdba' <<EOF >/tmp/quotas$$ 2>&1
set linesize 200;
set verify off;
set feedback off;
set pagesize 100;
set recsep off;
set tab off;
col uname heading "Username" for a20
col quotasmb heading "Quota in MB" for a70
select username uname, DECODE(max_bytes,-1,'UNLIMITED', max_bytes/1024/1024) || ' ON ' || tablespace_name quotasmb from dba_ts_quotas
where USERNAME not in('SYSTEM','SYS','ORACLE','FLEXERA','DIP','XS\$NULL','ORACLE_OCM','DBSNMP','XDB','ANONYMOUS','CTXSYS','APPQOSSYS','WMSYS','EXFSYS','OUTLN','PATROL')
order by 1,2;
EOF
cat /tmp/quotas$$ >> $result
rm /tmp/quotas$$

#-----------------------------------------------------------------------------------
# Tablespace allocation
echo "" >> $result
echo "" >> $result
echo "Tablespaces for $db :"  >> $result
#echo "" >> $result
sqlplus -s '/ as sysdba' <<EOF >>$result
set linesize 200
set feed off
set pagesize 50
col tbs                                 heading 'Tablespace' format a30;
col max                                 heading 'Max Size(Mo)' format 9999999999999
col avail                               heading 'Available(Mo)' format 999999999999
col avail                               heading 'Available(Mo)' format 999999999999
col used                                heading 'Used (Mo)' format 9999999999
col pused                               heading '%Used' format 999.99
col pfree                               heading '%Free' format 999.99

SELECT A.tablespace_name tbs,
round(C.max_size) max,
round(C.max_size - A.total_size + B.free_size) avail,
round(A.total_size - B.free_size) used,
round((A.total_size - B.free_size) * 100/ C.max_size) pused,
100-round((A.total_size - B.free_size) * 100/ C.max_size) pfree
FROM
(select tablespace_name, sum((bytes/1024)/1024) total_size
from sys.dba_data_files
group by tablespace_name) A,
(select tablespace_name, sum((bytes/1024)/1024) free_size
from sys.dba_free_space
group by tablespace_name ) B,
(select tablespace_name, sum(decode(AUTOEXTENSIBLE, 'YES',maxbytes,bytes)/1024)/1024 max_size
from sys.dba_data_files
group by tablespace_name) C,
(select name from v\$database) D
WHERE A.tablespace_name = B.tablespace_name(+)
AND A.tablespace_name = C.tablespace_name(+)
AND A.tablespace_name not like '%UNDO%'
AND A.tablespace_name not in ('SYSTEM','SYSAUX','PATROL_TBS')
order by 1;
EOF

# UNDO Tablespaces size
sqlplus -s '/ as sysdba' <<EOF >>$result
set linesize 200
set feed off
set pagesize 0
col tbs                                 heading 'Tablespace' format a30;
col max                                 heading 'Max Size(Mo)' format 9999999999999
SELECT A.tablespace_name tbs,
round(C.max_size) max,
'            /           /       /       /'
FROM
(select tablespace_name, sum((bytes/1024)/1024) total_size
from sys.dba_data_files
group by tablespace_name) A,
(select tablespace_name, sum((bytes/1024)/1024) free_size
from sys.dba_free_space
group by tablespace_name ) B,
(select tablespace_name, sum(decode(AUTOEXTENSIBLE, 'YES',maxbytes,bytes)/1024)/1024 max_size
from sys.dba_data_files
group by tablespace_name) C,
(select name from v\$database) D
WHERE A.tablespace_name = B.tablespace_name(+)
AND A.tablespace_name = C.tablespace_name(+)
AND A.tablespace_name like '%UNDO%'
order by 1;
EOF

# Temporary Tablspaces size
sqlplus -s '/ as sysdba' <<EOF >>$result
set linesize 200
set feed off
set pagesize 0
col tbs                                 heading 'Tablespace' format a30;
col max                                 heading 'Max Size(Mo)' format 9999999999999
SELECT df.tablespace_name tbs,
fs.bytes / (1024 * 1024) max,
'            /           /       /       /'
FROM dba_temp_files fs,
(SELECT tablespace_name,bytes_free,bytes_used
FROM v\$temp_space_header
GROUP BY tablespace_name,bytes_free,bytes_used) df
WHERE fs.tablespace_name (+) = df.tablespace_name
AND fs.tablespace_name not like '%PATROL%'
GROUP BY df.tablespace_name,fs.bytes,df.bytes_free,df.bytes_used
ORDER BY 1 DESC;
EOF

#-----------------------------------------------------------------------------------
# Provide FS Information
echo "" >> $result
echo "" >> $result
echo "Filesystems of $ou server :" >> $result
echo "" >> $result
if [ "$quoi" = "HP-UX" ]
then
bdf >> $result
else
df -h >> $result
fi
#-----------------------------------------------------------------------------------
# Dataguard check (synchro, ...)

# Configuration dgmgrl
STATUSDGMGRL=`dgmgrl / "show configuration verbose"|tail -2|head -1`
if [ "$STATUSDGMGRL" != "SUCCESS" ]
then
  ORAERR=`dgmgrl / "show configuration verbose"|grep ORA-|head -1`
fi

# Fast Start faiover Status
sqlplus -s '/ as sysdba' <<EOF >/tmp/fsfo$$ 2>&1
set verify off;
set feedback off;
set pagesize 0;
set recsep off;
set tab off;
select 'FSFO:'||FS_FAILOVER_STATUS||':'
from V\$DATABASE;
EOF
FSFO=`head -1 /tmp/fsfo$$ | tail -1 | cut -d':' -f2`
rm -f /tmp/fsfo$$

# Due to issue on release 12 with count of dest_id
if [[ ( "$DB_ROLE" = "PHYSICAL STANDBY" ) ]]
then
  DESTID="DG"
else
  # On verifie la synchro dans tous les cas
  # Dataguard configuration ?
  sqlplus -s '/ as sysdba' <<EOF >/tmp/quisuisje$$ 2>&1
  set verify off;
  set feedback off;
  set pagesize 0;
  set recsep off;
  set tab off;
  select 'DestId:'||DECODE(count(distinct dest_id),0,'NOTDG','1','NOTDG','DG')||':'
  from V\$ARCHIVED_LOG;
EOF
  DESTID=`head -1 /tmp/quisuisje$$ | tail -1 | cut -d':' -f2`
  rm /tmp/quisuisje$$
  # --
fi

>$result2

GAPL=0
GAPH=0
gapdiff=0
if [[ ( "$DESTID" = "DG" ) ]]
then
  sqlplus -s '/ as sysdba' <<EOF >>$result2
  set head off
  set feedback off;
  set term on;
  set verify off;
  set recsep off;
  set pagesize 0;
  set feed off;
  set term off;
  set trimspool off
  set linesize 200
  set echo on
  set wrap on
  select 'GAPL:'||LOW_SEQUENCE#||'GAPH:'||HIGH_SEQUENCE#
  from v\$ARCHIVE_GAP
  ;
EOF
  # delete empty lines
  awk 'NF != 0' $result2 > $result2
  if [ -s $result2 ]
  then
    GAPL=`head -1 $result2 | tail -1 | cut -d':' -f2`
    GAPH=`head -1 $result2 | tail -1 | cut -d':' -f4`
    let gapdiff=$GAPH-$GAPL 2>&1 1>/dev/null
  fi

  >$result2
  sqlplus -s '/ as sysdba' <<EOF >>$result2
  set head off
  set feedback off;
  set term on;
  set verify off;
  set recsep off;
  set pagesize 0;
  set feed off;
  set term off;
  set trimspool off
  set linesize 200
  set echo on
  set wrap on
  select 'PRY:'||pry||':STY:'||sty
  from
  (
  SELECT b.reset_log_time,
       b.last_seq pry,
       nvl(a.applied_seq,0) sty,
       a.last_app_timestamp
  FROM
   (SELECT RESETLOGS_ID,max(SEQUENCE#) applied_seq, max(NEXT_TIME) last_app_timestamp
    FROM V\$ARCHIVED_LOG where applied = 'YES'
    group by RESETLOGS_ID ) a,
   (SELECT RESETLOGS_ID, max(NEXT_TIME) last_app_timestamp,max(RESETLOGS_TIME) reset_log_time, MAX (sequence#) last_seq
    FROM V\$ARCHIVED_LOG
    group by RESETLOGS_ID) b
  WHERE a.RESETLOGS_ID(+) = b.RESETLOGS_ID
    and b.RESETLOGS_ID = (select max(RESETLOGS_ID) from V\$ARCHIVED_LOG)
  )
  ;
EOF

PRY=`head -1 $result2 | tail -1 | cut -d':' -f2`
STY=`head -1 $result2 | tail -1 | cut -d':' -f4`
let diff=$PRY-$STY
standbyserver=`echo "show configuration" | dgmgrl / | grep "Physical standby database" | cut -f1 -d"-" | cut -d"_" -f2-4 | sed "s/ //g" | sed "s/_/-/g"`
if [ $diff -gt 1 ]
then
  echo "KO Redo apply seems to be LATE on Standby Primary:$PRY/Standby:$STY" > $result2
  if [ $gapdiff -ge 1 ]
  then
    echo "Gap detected by Oracle kernel LOW_SEQUENCE:$GAPL/HIGH_SEQUENCE:$GAPH" >> $result2
  fi
  echo "Database $db hosted on $ou is $DB_ROLE" >> $result2
  echo "The Standby database is hosted on : $standbyserver" >> $result2
  if [ "$STATUSDGMGRL" = "SUCCESS" ]
  then
    echo "DGMGRL Configuration Status is $STATUSDGMGRL" >> $result2
  else
    echo "DGMGRL Configuration Status is <b>$STATUSDGMGRL</b> </font>" >> $result2
    echo "Error(s) : $ORAERR" >> $result2
  fi

  if [ "$FSFO" = "DISABLE" ]
  then
    echo "Warning : Fast Start Failover is $FSFO" >> $result2
  else
    echo "Fast Start Failover is $FSFO" >> $result2
  fi
  echo "(either DISABLE or status which should be SYNCHRONIZED)" >> $result2
else
  echo "OK Primary and Standby are synchronized Primary:$PRY/Standby:$STY" > $result2
  if [ $gapdiff -eq 0 ]
  then
    echo "No Gap detected by Oracle kernel LOW_SEQUENCE:$GAPL/HIGH_SEQUENCE:$GAPH" >> $result2
  fi
  echo "Database $db hosted on $ou is $DB_ROLE" >> $result2
  echo "The Standby database is hosted on : $standbyserver" >> $result2
  if [ "$STATUSDGMGRL" = "SUCCESS" ]
  then
    echo "DGMGRL Configuration Status is $STATUSDGMGRL" >> $result2
  else
    echo "DGMGRL Configuration Status is $STATUSDGMGRL" >> $result2
    echo "Error(s) : $ORAERR" >> $result2
  fi

  if [ "$FSFO" = "DISABLE" ]
  then
    echo "Fast Start Failover is $FSFO" >> $result2
  else
    echo "Fast Start Failover is $FSFO" >> $result2
  fi
  echo "(either DISABLE or status which should be SYNCHRONIZED)" >> $result2
fi


echo " "  >> $result
echo " "  >> $result
echo "Dataguard Status :" >> $result
echo " "  >> $result
cat $result2 >> $result
rm $result2

fi  # DG/NOTDG
###############fi # PRIMARY

#-----------------------------------------------------------------------------------
# Look for Instances Parameters
sqlplus -s '/ as sysdba' <<EOF >/tmp/instance_parameter$$ 2>&1
set verify off;
set feedback off;
set pagesize 0;
set linesize 200;
set recsep off;
set tab off;
select name || ': ' || value from v\$parameter order by 1;
EOF

echo "" >> $result
echo "" >> $result
echo "List of Instance Parameters :" >> $result
echo "" >> $result

cat /tmp/instance_parameter$$ >> $result
rm /tmp/instance_parameter$$

#-----------------------------------------------------------------------------------
# Look for sessions
sqlplus -s '/ as sysdba' <<EOF >/tmp/sessions_list$$ 2>&1
set verify off;
set feedback off;
set pagesize 0;
set linesize 200;
set recsep off;
set tab off;
set linesize 300
set pagesize 100
col uname heading 'Username' for a20
col osu heading 'OS User' for a15
col logont heading 'Logon Time' for a22
col prog heading 'Program' for a60
col mach heading 'Machine' for a35
col sta heading 'Status' for a10
col s_sid heading 'SID' for 9999
col s_ser heading 'Serial #' for 99999999
col s_proc heading 'Process' for a10
select username uname, osuser osu, machine mach, to_char(logon_time,'dd/mm/yyyy - hh24:mi:ss') logont, program prog, status, sid s_sid, serial# s_ser, process proc
from v\$session
where username is not null
order by 1;
EOF

echo "" >> $result
echo "" >> $result
echo "List of sessions :" >> $result
echo "" >> $result

cat /tmp/sessions_list$$ >> $result
rm /tmp/sessions_list$$

#-----------------------------------------------------------------------------------
# end PRIMARY
else
# STANDBY CASE
if [[ ( "$DB_ROLE" = "PHYSICAL STANDBY" ) ]]
then
# Get primary server
primaryserver=`echo "show configuration" | dgmgrl / | grep "Primary database" | cut -f1 -d"-" | cut -d"_" -f2-4 | sed "s/ //g" | sed "s/_/-/g"`

sqlplus -s '/ as sysdba' <<EOF >/tmp/quisuisje$$ 2>&1
set verify off;
set feedback off;
set pagesize 0;
set recsep off;
set tab off;
select 'Database Name:'||NAME
from V\$DATABASE;
EOF
DB_NAME=`head -1 /tmp/quisuisje$$ | tail -1`
rm -f /tmp/quisuisje$$

echo $DB_NAME >> $result

#-----------------------------------------------------------------------------------
# Server Name
SERVER_NAME=`hostname --fqdn`
echo "SERVER NAME: $SERVER_NAME" >> $result


#-----------------------------------------------------------------------------------
# Look for Release
sqlplus -s '/ as sysdba' <<EOF >/tmp/release$$ 2>&1
set verify off;
set feedback off;
set pagesize 0;
set recsep off;
set tab off;
select 'RELEASE: '||version from v\$instance;
EOF
RELEASE=`head -1 /tmp/release$$ | tail -1`

echo $RELEASE >> $result
rm /tmp/release$$

#-----------------------------------------------------------------------------------
#-----------------------------------------------------------------------------------
# Look for Archivelog mode
sqlplus -s '/ as sysdba' <<EOF >/tmp/archivelog$$ 2>&1
set verify off;
set feedback off;
set pagesize 0;
set recsep off;
set tab off;
select 'ARCHIVELOG MODE: '||LOG_MODE from v\$database;
EOF
ARCHIVELOG=`head -1 /tmp/archivelog$$ | tail -1`

echo $ARCHIVELOG >> $result
rm /tmp/archivelog$$

echo "" >> $result
echo "INFORMATION : Your database is a Standby database, to get more information please launch the script on the other node : $primaryserver." >> $result
echo "" >> $result

#-----------------------------------------------------------------------------------
# Provide FS Information
echo "" >> $result
echo "" >> $result
echo "Filesystems of $ou server :" >> $result
echo "" >> $result
if [ "$quoi" = "HP-UX" ]
then
bdf >> $result
else
df -h >> $result
fi
#-----------------------------------------------------------------------------------
# Dataguard check (synchro, ...)
# ------------------------------
# Configuration dgmgrl
STATUSDGMGRL=`dgmgrl / "show configuration verbose"|tail -2|head -1`
if [ "$STATUSDGMGRL" != "SUCCESS" ]
then
  ORAERR=`dgmgrl / "show configuration verbose"|grep ORA-|head -1`
fi

# Fast Start faiover Status
sqlplus -s '/ as sysdba' <<EOF >/tmp/fsfo$$ 2>&1
set verify off;
set feedback off;
set pagesize 0;
set recsep off;
set tab off;
select 'FSFO:'||FS_FAILOVER_STATUS||':'
from V\$DATABASE;
EOF
FSFO=`head -1 /tmp/fsfo$$ | tail -1 | cut -d':' -f2`
rm -f /tmp/fsfo$$

# Due to issue on release 12 with count of dest_id
if [[ ( "$DB_ROLE" = "PHYSICAL STANDBY" ) ]]
then
  DESTID="DG"
else
  # On verifie la synchro dans tous les cas
  # Dataguard configuration ?
  sqlplus -s '/ as sysdba' <<EOF >/tmp/quisuisje$$ 2>&1
  set verify off;
  set feedback off;
  set pagesize 0;
  set recsep off;
  set tab off;
  select 'DestId:'||DECODE(count(distinct dest_id),0,'NOTDG','1','NOTDG','DG')||':'
  from V\$ARCHIVED_LOG;
EOF
  DESTID=`head -1 /tmp/quisuisje$$ | tail -1 | cut -d':' -f2`
  rm /tmp/quisuisje$$
  # --
fi

>$result2

GAPL=0
GAPH=0
gapdiff=0
if [[ ( "$DESTID" = "DG" ) ]]
then
  sqlplus -s '/ as sysdba' <<EOF >>$result2
  set head off
  set feedback off;
  set term on;
  set verify off;
  set recsep off;
  set pagesize 0;
  set feed off;
  set term off;
  set trimspool off
  set linesize 200
  set echo on
  set wrap on
  select 'GAPL:'||LOW_SEQUENCE#||'GAPH:'||HIGH_SEQUENCE#
  from v\$ARCHIVE_GAP
  ;
EOF
  # delete empty lines
  awk 'NF != 0' $result2 > $result2
  if [ -s $result2 ]
  then
    GAPL=`head -1 $result2 | tail -1 | cut -d':' -f2`
    GAPH=`head -1 $result2 | tail -1 | cut -d':' -f4`
    let gapdiff=$GAPH-$GAPL 2>&1 1>/dev/null
  fi

  >$result2
  sqlplus -s '/ as sysdba' <<EOF >>$result2
  set head off
  set feedback off;
  set term on;
  set verify off;
  set recsep off;
  set pagesize 0;
  set feed off;
  set term off;
  set trimspool off
  set linesize 200
  set echo on
  set wrap on
  select 'PRY:'||pry||':STY:'||sty
  from
  (
  SELECT b.reset_log_time,
       b.last_seq pry,
       nvl(a.applied_seq,0) sty,
       a.last_app_timestamp
  FROM
   (SELECT RESETLOGS_ID,max(SEQUENCE#) applied_seq, max(NEXT_TIME) last_app_timestamp
    FROM V\$ARCHIVED_LOG where applied = 'YES'
    group by RESETLOGS_ID ) a,
   (SELECT RESETLOGS_ID, max(NEXT_TIME) last_app_timestamp,max(RESETLOGS_TIME) reset_log_time, MAX (sequence#) last_seq
    FROM V\$ARCHIVED_LOG
    group by RESETLOGS_ID) b
  WHERE a.RESETLOGS_ID(+) = b.RESETLOGS_ID
    and b.RESETLOGS_ID = (select max(RESETLOGS_ID) from V\$ARCHIVED_LOG)
  )
  ;
EOF
# delete empty lines
PRY=`head -1 $result2 | tail -1 | cut -d':' -f2`
STY=`head -1 $result2 | tail -1 | cut -d':' -f4`
let diff=$PRY-$STY
if [ $diff -gt 1 ]
then
  echo "KO Redo apply seems to be LATE on Standby Primary:$PRY/Standby:$STY" > $result2
  if [ $gapdiff -ge 1 ]
  then
    echo "Gap detected by Oracle kernel LOW_SEQUENCE:$GAPL/HIGH_SEQUENCE:$GAPH" >> $result2
  fi
  echo "Database $db hosted on $ou is $DB_ROLE" >> $result2
  echo "The Primary database is hosted on $primaryserver" >> $result2

  if [ "$STATUSDGMGRL" = "SUCCESS" ]
  then
    echo "DGMGRL Configuration Status is $STATUSDGMGRL" >> $result2
  else
    echo "DGMGRL Configuration Status is <b>$STATUSDGMGRL</b> </font>" >> $result2
    echo "Error(s) : $ORAERR" >> $result2
  fi

  if [ "$FSFO" = "DISABLE" ]
  then
    echo "Warning : Fast Start Failover is $FSFO" >> $result2
  else
    echo "Fast Start Failover is $FSFO" >> $result2
  fi
  echo "(either DISABLE or status which should be SYNCHRONIZED)" >> $result2
else
  echo "OK Primary and Standby are synchronized Primary:$PRY/Standby:$STY" > $result2
  if [ $gapdiff -eq 0 ]
  then
    echo "No Gap detected by Oracle kernel LOW_SEQUENCE:$GAPL/HIGH_SEQUENCE:$GAPH" >> $result2
  fi
  echo "Database $db hosted on $ou is $DB_ROLE" >> $result2
  echo "The Primary database is hosted on $primaryserver" >> $result2
  if [ "$STATUSDGMGRL" = "SUCCESS" ]
  then
    echo "DGMGRL Configuration Status is $STATUSDGMGRL" >> $result2
  else
    echo "DGMGRL Configuration Status is $STATUSDGMGRL" >> $result2
    echo "Error(s) : $ORAERR" >> $result2
  fi

  if [ "$FSFO" = "DISABLE" ]
  then
    echo "Fast Start Failover is $FSFO" >> $result2
  else
    echo "Fast Start Failover is $FSFO" >> $result2
  fi
  echo "(either DISABLE or status which should be SYNCHRONIZED)" >> $result2
fi

echo " "  >> $result
echo " "  >> $result
echo "Dataguard Status :" >> $result
echo " "  >> $result
cat $result2 >> $result
rm $result2
#rm -f /tmp/quisuisje$$
#rm -f /tmp/fsfo$$

fi  # DG/NOTDG
###############fi # PRIMARY

#-----------------------------------------------------------------------------------
# Look for Instances Parameters
sqlplus -s '/ as sysdba' <<EOF >/tmp/instance_parameter$$ 2>&1
set verify off;
set feedback off;
set pagesize 0;
set linesize 200;
set recsep off;
set tab off;
select name || ': ' || value from v\$parameter order by 1;
EOF

echo "" >> $result
echo "" >> $result
echo "List of Instance Parameters :" >> $result
echo "" >> $result

cat /tmp/instance_parameter$$ >> $result
rm /tmp/instance_parameter$$

#-----------------------------------------------------------------------------------
# end STANDBY
fi

fi
# end database is up / down


fi

exit $RetCode

