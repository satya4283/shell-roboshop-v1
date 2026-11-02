#!/bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"
R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

if [ $user_id -ne 0 ]; then
    echo "please run the script with root access."
    exit 1
fi

timestamp(){
    date "+%F %T"
}

mkdir -p $logs_folder

validate(){
if [ $1 -ne 0 ]; then
    echo -e "$(timestamp) [ERROR] ${2}...${R}FAILED${N}"|tee -a $logs_file
    exit 1
else
    echo -e "$(timestamp) [INFO] ${2}...${G}SUCCESS${N}" |tee -a $logs_file
fi
}

echo "$(timestamp) [INFO] ==== Script started execution at ===="  |tee -a $logs_file

dnf module enable mysql:8.4 -y &>> $logs_file
validate $? "Enable mysql 8.4"

dnf install mysql-server -y &>> $logs_file
validate $? "Install mySQL -server"

systemctl enable mysqld &>> $logs_file
systemctl start mysqld
validate $? " Enable and start Mysql"

mysql_secure_installation --set-root-pass RoboShop@1 
validate $? "setup Mysql root password"


echo "$(timestamp) [INFO] Script completed in $SECONDS seconds" |tee -a $logs_file
echo "$(timestamp) [INFO] ==== Script completed execution at ===="  |tee -a $logs_file


