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

cp rabbitmq.repo /etc/yum.repos.d/rabbitmq.repo

dnf install erlang rabbitmq-server -y &>> $logs_file
validate $? "Installing RabbitMQ Server"

systemctl enable rabbitmq-server &>> $logs_file
systemctl start rabbitmq-server &>> $logs_file
validate $? "Enable and start rabbitMQ"

rabbitmqctl add_user roboshop roboshop123 &>> $logs_file
validate $? "Create RabbitMQ user for roboshop."

rabbitmqctl set_permissions -p / roboshop ".*" ".*" ".*" &>> $logs_file
validate $? "Setting the permissions for RabbitMQ."


echo "$(timestamp) [INFO] Script completed in $SECONDS seconds" |tee -a $logs_file
echo "$(timestamp) [INFO] ==== Script completed execution at ===="  |tee -a $logs_file


