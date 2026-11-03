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

dnf module enable maven:3.9 -y &>> $logs_file
dnf install maven java-25-openjdk-devel -y &>> $logs_file
validate $? "Installing java and maven"

alternatives --set java "/usr/lib/jvm/java-25-openjdk/bin/java"
validate $? "Setting Java 25 as default Java version"

echo "export JAVA_HOME=$(dirname $(dirname $(readlink -f /usr/bin/java)))" > /etc/profile.d/java.sh &>> $logs_file
source /etc/profile.d/java.sh &>> $logs_file
echo $JAVA_HOME &>> $logs_file
validate $? "Setting JAVA_HOME for maven"

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

curl -L -o /tmp/shipping.zip https://raw.githubusercontent.com/daws-92s/roboshop-documentation/refs/heads/main/artifacts/shipping-v4.zip &>> $logs_file
validate $? "Downloading shipping"

cd /app
unzip /tmp/shipping.zip &>> $logs_file
validate $? "Unzapping shipping"

mvn clean package &>> $logs_file
validate $? "Installing dependencies"

mv target/shipping.jar shipping.jar &>> $logs_file
validate $? "Moving shipping jar"

sed -i "s/DOMAIN_NAME/$domain_name/g" $scripts_dir/shipping.service &>> $logs_file
validate $? "DOMAIN_NAME updated"
cp  "$scripts_dir/shipping.service"  /etc/systemd/system/shipping.service &>> $logs_file
validate $? "service file created"

dnf install mysql -y &>> $logs_file
validate $? "Installing MySQL client"

count=$(mysql -h "mysql.$domain_name" -u root -pRoboShop@1 -e "SELECT * FROM cities.cities;" 2>>$logs_file) 
if [ -z ${count}] || [ ${count} -eq 0 ]; then
    mysql -h "mysql.$domain_name" -uroot -pRoboShop@1 < /app/db/master-data.sql
else
    echo -e "${timstamp} [INFO]  Master data already loaded...${Y}SKIPPING${N}"
fi 

mysql -h "mysql.$domain_name" -uroot -pRoboShop@1 < /app/db/app-user.sql
validate $? "Creating APP user"


systemctl daemon-reload &>> $logs_file
systemctl enable shipping &>> $logs_file
systemctl restart shipping
validate $? "Restarting/Starting shipping"



echo "$(timestamp) [INFO] Script completed in $SECONDS seconds" |tee -a $logs_file
echo "$(timestamp) [INFO] ==== Script completed execution at ===="  |tee -a $logs_file

