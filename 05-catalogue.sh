#!/bin/bash

user_id=$(id -u)
logs_folder="/var/log/roboshop"
logs_file="${logs_folder}/${0}.log"
domain_name="daws92ss.store"
scripts_dir=$(dirname "$(realpath "$0")")
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

dnf module disable nodejs -y &>> $logs_file
dnf module enable nodejs:24 -y &>> $logs_file
dnf install nodejs -y &>> $logs_file
validate $? "Installing nodejs 24"

id roboshop &>> $logs_file
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop &>> $logs_file
    validate $? "Creating system user"
else
    echo -e "$(timestamp) [INFO] System user already exist..${Y}SKIPPING${N}" |tee -a $logs_file
fi

rm -rf /app
validate $? "Removing old code"

mkdir -p /app
validate $? "Creating app directory"

curl -L -o /tmp/catalogue.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/catalogue-v4.zip &>> $logs_file
validate $? "Downloading catalogue"

cd /app
unzip /tmp/catalogue.zip &>> $logs_file
validate $? "Unzapping catalogue"

npm install &>> $logs_file
validate $? "Installing dependencies"

sed -i "s/DOMAIN_NAME/$domain_name/g" $scripts_dir/catalogue.service &>> $logs_file
validate $? "DOMAIN_NAME updated"
cp  "$scripts_dir/catalogue.service"  /etc/systemd/system/catalogue.service &>> $logs_file
validate $? "service file created"

systemctl daemon-reload &>> $logs_file
systemctl enable catalogue &>> $logs_file
systemctl start catalogue &>> $logs_file 
validate $? "Start and enabling catalogue"

cp "$scripts_dir/mongo.repo"  /etc/yum.repos.d/mongo.repo &>> $logs_file
validate $? "Adding  mongo repo"

dnf install mongodb-mongosh -y &>> $logs_file
validate $? "Installing mongodb client"




echo "$(timestamp) [INFO] Script completed in $SECONDS seconds" |tee -a $logs_file
echo "$(timestamp) [INFO] ==== Script completed execution at ===="  |tee -a $logs_file


