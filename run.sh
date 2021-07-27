#!/bin/bash
set -o errexit

# ワールドデータをダウンロード
echo "[START DOWNLOAD WORLD]"
minecraft-tools/realms-download.sh
echo "[DOWNLOAD COMPLETED]"

# 更新がなければ終了
aws s3 cp s3://mc-map1-util/last-world.md5 ./
new_md5=`md5sum world.tar.gz`
if [ -e last-world.md5 ]; then
    last_md5=`cat last-world.md5`
    if [ $last_md5 = $new_md5 ]; then
        echo "[ALREADY UP TO DATE]"
        exit 0
    fi
fi
echo "[WORLD UPDATE DETECTED]"
echo $new_md5 > last_md5
aws s3 cp last_md5 s3://mc-map1-util/last-world.md5

# レンダリング（マップ生成）
mv world.tar.gz server/
cd server
tar xzf world.tar.gz
rm world.tar.gz
cd ..
echo "[START RENDERING]"
bash render.sh
bash minecraft-tools/overviewer/insert-google-key.sh render/ $GOOGLE_MAP_API_KEY
echo "[RENDERING COMPLETED]"

# デプロイ
aws s3 sync render/ s3://mc-map1/
aws cloudfront create-invalidation --distribution-id EN343715ZCV8 --paths "/*"
echo "[DEPLOY COMPLETED]"
