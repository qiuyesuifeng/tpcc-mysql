#!/bin/bash

# 
# source from yejr(http://imysql.com), 2012/12/14
# modified by qiuyesuifeng(cuiqiu.bupt@gmail.com)
#

# Todo: make it suit for our job.

#export LD_LIBRARY_PATH=/usr/local/mysql/lib/ 
. ~/.bash_profile >/dev/null 2>&1

BASEDIR="/home/tpcc-mysql"
cd $BASEDIR

exec 3>&1 4>&2 1>> tpcc-mysql-benchmark-oltp-`date +'%Y%m%d%H%M%S'`.log 2>&1

DBIP=localhost
DBUSER='tpcc'
DBPASS='tpcc'
DBNAME="tpcc${WIREHOUSE}"

WIREHOUSE=1000
WARMUP=120
DURING=3600
MODE="2SSD_RAID0_WB_nobarrier_deadline"

if [ -z "`mysqlshow|grep -v grep|grep \"$DBNAME\"`" ] ; then
 mysqladmin -f create $DBNAME
 mysql -e "grant all on $DBNAME.* to $DBUSER@'$DBIP' identified by '$DBPASS';"
 mysql -f $DBNAME < ./create_table.sql
 ./tpcc_load $DBIP $DBNAME $DBUSER $DBPASS $WIREHOUSE
fi

CNT=0
CYCLE=2
while [ $CNT -lt $CYCLE ]
do
NOW=`date +'%Y%m%d%H%M'`

for THREADS in 8 16 32 64 128 256 
do

./tpcc_start -h $DBIP -d $DBNAME -u $DBUSER -p "${DBPASS}" -w $WIREHOUSE -c $THREADS -r $WARMUP -l $DURING -f ./logs/tpcc_${MODE}_${NOW}_${THREADS}_THREADS.res >> ./logs/tpcc_runlog_${MODE}_${NOW}_${THREADS}_THREADS 2>&1

/etc/init.d/mysql stop; echo 3 > /proc/sys/vm/drop_caches; /etc/init.d/mysql start; sleep 60
done

CNT=`expr $CNT + 1`
done
