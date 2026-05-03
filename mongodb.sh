#!/bin/bash
USERID=$(id -u)
LOGS_FOLDER="/var/log/shellscript"
LOGS_FILE="/var/log/shellscript/$0.log"

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
        echo -e "$2 .... ${G} SUCESS ${N}" | tee -a $LOGS_FILE
    fi
}

cp mongo.repo /etc/yum.repos.d/mongo.repo
VALIDATE $? "Copied mongo.repo file."

dnf install mongodb-org -y 
VALIDATE $? "Installed MongoDB server."

systemctl enable mongod
VALIDATE $? "Enable MongoDB service."

systemctl start mongod 
VALIDATE $? "StartingMongoDB service."

sed -i 's/127.0.0.1/0.0.0.0/g' /etc/mongod.conf
VALIDATE $? "Allowing remote connections."

systemctl restart mongod
VALIDATE $? "Restarting mongobd"