#!/bin/bash

function notice () {
    curl \
        -H "Content-Type: application/json" \
        -d '{"username": "mapmaker", "content": "'$1'"}' \
        $DISCORD_WEBHOOK_URL
}

# ワールドデータをダウンロード
echo "MCMAP> [GET WORLD]"
aws s3 cp s3://${UTIL_BUCKET}/world.tar.gz world.tar.gz

# 更新がなければ終了
aws s3 cp s3://${UTIL_BUCKET}/last-world.md5 ./
new_md5=`md5sum world.tar.gz`
echo "MCMAP> [NEW MD5] ${new_md5}"
if [ -e last-world.md5 ]; then
    last_md5=`cat last-world.md5`
    echo "MCMAP> [LAST MD5] ${last_md5}"
    if [ "${last_md5}" = "${new_md5}" ]; then
        echo "MCMAP> [ALREADY UP TO DATE]"
        notice "更新なかったっぽい"
        exit 0
    fi
fi
echo "MCMAP> [WORLD UPDATE DETECTED]"
echo $new_md5 > last_md5
aws s3 cp last_md5 s3://${UTIL_BUCKET}/last-world.md5

# レンダリング（マップ生成）
mv world.tar.gz server/
cd server
tar xzf world.tar.gz
rm world.tar.gz
cd ..
echo "MCMAP> [START RENDERING]"
notice "マップ生成しまぁす"
SECONDS=0

bash render.sh
if [ $? -ne 0 ];then
    echo "MCMAP> [ERROR: RENDERING FAILED]"
    notice $DISCORD_ERROR
    exit 2
fi

bash minecraft-tools/overviewer/insert-google-key.sh render/ $GOOGLE_MAP_API_KEY
if [ $? -ne 0 ];then
    echo "MCMAP> [ERROR: API KEY INSERET FAILED]"
    notice $DISCORD_ERROR
    exit 2
fi

echo "MCMAP> [RENDERING COMPLETED] elapsed=${SECONDS}"

# デプロイ
SECONDS=0
aws s3 sync render/ s3://${WEB_BUCKET}/ --delete
if [ $? -ne 0 ];then
    echo "MCMAP> [ERROR: DEPLOY FAILED]"
    notice $DISCORD_ERROR
    exit 2
fi

aws cloudfront create-invalidation --distribution-id $DISTRIBUTION_ID --paths "/*"
if [ $? -ne 0 ];then
    echo "MCMAP> [ERROR: CACHE INVALIDATION FAILED]"
    notice $DISCORD_ERROR
    exit 2
fi

echo "MCMAP> [DEPLOY COMPLETED] elapsed=${SECONDS}"
notice $DISCORD_SUCCESS
