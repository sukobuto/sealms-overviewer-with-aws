#!/bin/bash

# S3 から credential を取得
aws s3 cp s3://${UTIL_BUCKET}/credentials.env ./
if [ -e credentials.env ]; then
    export $(grep -v '^\s*#' credentials.env |grep -v '^\s*$' |sed -e 's/=\(.*\)/="\1/g' -e 's/$/"/g' | xargs)
else
    source renew-credential.sh
fi
