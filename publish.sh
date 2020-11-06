#! /bin/bash
rm -rf ./dist
npm install
cp ./static/antd.css ./node_modules/ant-design-vue/dist
npm run build
docker build -t nebula/ci/plugins/common/config .