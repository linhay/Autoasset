#! /bin/bash
file="Template"
# 文档生成
jazzy \
--podspec ${file}.podspec \
--output ./document/api/
