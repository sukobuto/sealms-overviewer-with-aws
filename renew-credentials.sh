#!/bin/bash

source minecraft-tools/login.sh ${MINECRAFT_USER_EMAIL} ${MINECRAFT_USER_PASSWORD}

echo "access_token=${access_token}" > credentials.env
echo "name=${name}" >> credentials.env
echo "id=${id}" >> credentials.env

# S3 に credential を保存
aws s3 cp credentials.env s3://${UTIL_BUCKET}/credentials.env
