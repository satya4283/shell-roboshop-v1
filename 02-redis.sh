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

echo "${timestamp} [INFO] ==== Script started execution at ===="  |tee -a $logs_file

dnf module disable redis -y &>> $logs_file
dnf module enable redis:7 -y &>> $logs_file
validate $? "Disable and enable redis"

dnf install redis -y &>> $logs_file
validate $? "Install redis"

sed -i  -e 's/^bind 127.0.0.1/bind 0.0.0.0/' -e 's/^protected-mode yes/protected-mode no/' /etc/redis/redis.conf
validate $? "Updated remote connections and protected mode to redis"


systemctl enable redis &>> $logs_file
systemctl start redis 
validate $? "Enable and start redis"

echo "$(timestamp) [INFO] Script completed in $SECONDS seconds" |tee -a $logs_file
echo "$(timestamp) [INFO] ==== Script completed execution at ===="  |tee -a $logs_file


