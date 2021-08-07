#!/bin/bash

function notice () {
    curl \
        -H "Content-Type: application/json" \
        -d '{"username": "mapmaker", "content": "'$1'"}' \
        $DISCORD_WEBHOOK_URL
}

# ワールドデータをダウンロード
echo "MCMAP> [START DOWNLOAD WORLD]"
source credentials.sh
minecraft-tools/realms-download.sh
status=$?
# 0:成功
# 1:おそらくトークンが古い
# 2:おそらく中に人がいてバックアップが取れない
# 3:ワールドデータがダウンロードできなかった
if [ $status -e 1 ];then
    # 1の場合はトークンを取得し直して再試行
    echo "MCMAP> [RENEW TOKEN]"
    source renew-credentials.sh
    minecraft-tools/realms-download.sh
    status=$?
    if [ $status -e 1 ];then
        echo "MCMAP> [ERROR: REALMS ACCESS FAILED]"
        notice "再ログインしたけどダウンロード失敗した。。"
        exit 1
    fi
fi
if [ $status -e 2 ];then
    echo "MCMAP> [ERROR: BACKUP TAKING FAILED]"
    exit 2
fi
if [ $status -e 3 ];then
    echo "MCMAP> [ERROR: DOWNLOAD FAILED]"
    notice "バックアップまでは取得できたっぽいけど何故かダウンロードできなかった。。"
    exit 3
fi
aws s3 cp world.tar.gz s3://${UTIL_BUCKET}/world.tar.gz
echo "MCMAP> [DOWNLOAD COMPLETED]"
