#!/bin/bash
USERID=$(id -u)
LOGS_FOLDER="/var/log/shellscript"
LOGS_FILE="/var/log/shellscript/$0.log"
SCRIPT_DIR=$(pwd)

mkdir -p "$LOGS_FOLDER"

R='\033[0;31m'
G='\033[0;32m'
Y='\033[1;33m'
N='\033[0m'

# This will check weather the script is excuted by root user.
if [ $USERID -ne 0 ]; then
    echo -e "${R}You should run this script as root user or with sudo privileges.${N}"
    exit 1
fi

VALIDATE() {
    if [ $1 -ne 0 ]; then
        echo -e "$2 .... $R FAILURE $N" | tee -a $LOGS_FILE
        exit 1
    else
        echo -e "$2 .... ${G} SUCCESS ${N}" | tee -a $LOGS_FILE
    fi
}

dnf module disable nodejs -y &>>$LOGS_FILE
VALIDATE $? "Disabling Nodejs"

dnf module enable nodejs:20 -y &>>$LOGS_FILE
VALIDATE $? "Enabling Nodejs:20"

dnf install nodejs -y &>>$LOGS_FILE
VALIDATE $? "Installing Nodejs:20"

useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop

mkdir /app 

curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip 
cd /app 

unzip /tmp/catalogue.zip

cd /app 
npm install 

cp -r SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service

systemctl daemon-reload
systemctl enable catalogue 
systemctl start catalogue