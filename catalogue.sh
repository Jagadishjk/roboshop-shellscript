#!/bin/bash
USERID=$(id -u)
LOGS_FOLDER="/var/log/shellscript"
LOGS_FILE="/var/log/shellscript/$0.log"
SCRIPT_DIR=$(pwd)
MONGODB_HOST="mongodb.techlineruns.online"

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
echo -e "$R DEBUG: $R $0 $N"
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

id roboshop &>>$LOGS_FILE
if [ $? -ne 0 ]; then
    useradd --system --home /app --shell /sbin/nologin --comment "roboshop system user" roboshop
    VALIDATE $? "Creating roboshop user"
else
    echo -e "roboshop user already exist ... $Y SKIPPING $N"
fi

mkdir -p /app
VALIDATE $? "Creating /app directory"

rm -rf /app/*
curl -o /tmp/catalogue.zip https://roboshop-artifacts.s3.amazonaws.com/catalogue-v3.zip &>>$LOGS_FILE
VALIDATE $? "Copying catalogue.zip code"

cd /app 
unzip /tmp/catalogue.zip &>>$LOGS_FILE
VALIDATE $? "Unzipping catalogue.zip code"

cd /app 
npm install &>>$LOGS_FILE
VALIDATE $? "Installing Nodejs dependencies"

cp -r $SCRIPT_DIR/catalogue.service /etc/systemd/system/catalogue.service
VALIDATE $? "Copying catalogue.service file"

systemctl daemon-reload
systemctl enable catalogue 
systemctl start catalogue
VALIDATE $? "Enabling and starting catalogue service"

cp -r $SCRIPT_DIR/mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copying Mongo.repo file"

dnf install mongodb-mongosh -y &>>$LOGS_FILE
VALIDATE $? "Installing Mongodb"

mongosh --host $MONGODB_HOST </app/db/master-data.js &>>$LOGS_FILE
VALIDATE $? "Connecting to Mongodb host"