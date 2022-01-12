#!/usr/bin/env sh

# 确保脚本抛出遇到的错误
set -e

# 生成静态文件
# npm run docs:build

# 进入生成的文件夹
# cd ms-vite-h5/

git init
git add -A
git commit -m 'test'

# 如果发布到 https://<USERNAME>.github.io/<REPO>
# git push -f git@github.com:aBigFace/edacCodeConstraints.git master:gh-pages
git push -u origin main

cd -
