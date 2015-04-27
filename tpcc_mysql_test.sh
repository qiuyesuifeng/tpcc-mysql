#!/bin/bash

# 
# qiuyesuifeng(cuiqiu.bupt@gmail.com)
#

#export LD_LIBRARY_PATH=/usr/local/mysql/lib/

source ~/.bash_profile

Usage()
{
    echo "Usage: sh tpcc_mysql_test.sh {ServiceType all|load|run} {ServiceScale tiny|small|normal|large}"
    echo "Bad parameters!"
    exit 1
}

if [ $# -lt 2 ]; then
Usage
fi

DoRun="false"
DoLoad="false"
WIREHOUSE=10
WARMUP=120
DURING=600

ServiceType=${1}
ServiceScale=${2}

# check service type
if [ "${ServiceType}ok" == "allok" ]; then
    DoRun="true"
    DoLoad="true"
elif [ "${ServiceType}ok" == "loadok" ]; then
    DoLoad="true"
elif [ "${ServiceType}ok" == "runok" ]; then
    DoRun="true"
else
    Usage
fi 

# check service scale
if [ "${ServiceScale}ok" == "tinyok" ]; then
    WIREHOUSE=1
    WARMUP=60
    DURING=60
elif [ "${ServiceScale}ok" == "smallok" ]; then
    WIREHOUSE=10
    WARMUP=120
    DURING=600
elif [ "${ServiceScale}ok" == "normalok" ]; then
    WIREHOUSE=100
    WARMUP=120
    DURING=1800
elif [ "${ServiceScale}ok" == "largeok" ]; then
    WIREHOUSE=1000
    WARMUP=300
    DURING=3600
else
    Usage
fi 

DB_HOST="127.0.0.1"
DB_USER="root"
DB_PASSWD=""
DB_PORT=3306
DB_NAME="tpcc_${WIREHOUSE}"
TPCC_MYSQL_PATH="/home/cuiqiu/code/mysql-tool/tpcc-mysql"
LOG_PATH="."
RESULT_PATH="."

# do db load
if [ "${DoLoad}ok" == "trueok" ]; then
    in_passwd="-p${DB_PASSWD}"
    if [ "${DB_PASSWD}" == "" ]; then 
        in_passwd=""
    fi

    mysql -h${DB_HOST} -P${DB_PORT} -u${DB_USER} ${in_passwd} -e "create database if not exists ${DB_NAME};"
    mysql -h${DB_HOST} -P${DB_PORT} -u${DB_USER} ${in_passwd} -f ${DB_NAME} < ${TPCC_MYSQL_PATH}/create_table.sql
    mysql -h${DB_HOST} -P${DB_PORT} -u${DB_USER} ${in_passwd} -f ${DB_NAME} < ${TPCC_MYSQL_PATH}/add_idx.sql
    ${TPCC_MYSQL_PATH}/tpcc_load ${DB_HOST} ${DB_NAME} ${DB_USER} "${DB_PASSWD}" ${WIREHOUSE}
fi

# do db run
if [ "${DoRun}ok" == "trueok" ]; then
    for THREADS in 8 16 32 64 128 256 
    do
        now=`date +'%Y%m%d%H%M'`
        ${TPCC_MYSQL_PATH}/tpcc_start -h ${DB_HOST} -d ${DB_NAME} -u ${DB_USER} -p "${DB_PASSWD}" -w ${WIREHOUSE} -c ${THREADS} -r ${WARMUP} -l ${DURING} -f ${RESULT_PATH}/tpcc_test_${THREADS}_${WIREHOUSE}_${WARMUP}_${DURING}_${now}.result > ${LOG_PATH}/tpcc_test_${THREADS}_${WIREHOUSE}_${WARMUP}_${DURING}_${now}.log 2>&1
    done
fi
