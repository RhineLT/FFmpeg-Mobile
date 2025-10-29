#!/bin/bash

# FFmpeg Kit 测试切换脚本

MAIN_FILE="lib/main.dart"
TEST_FILE="lib/main_test_ffmpeg.dart"
BACKUP_FILE="lib/main_original.dart"

if [ "$1" == "test" ]; then
    echo "切换到 FFmpeg Kit 测试模式..."
    cp "$MAIN_FILE" "$BACKUP_FILE"
    cp "$TEST_FILE" "$MAIN_FILE"
    echo "✓ 已切换到测试模式"
    echo "运行: flutter run"
elif [ "$1" == "restore" ]; then
    echo "恢复到原始版本..."
    if [ -f "$BACKUP_FILE" ]; then
        cp "$BACKUP_FILE" "$MAIN_FILE"
        rm "$BACKUP_FILE"
        echo "✓ 已恢复原始版本"
    else
        echo "✗ 没有找到备份文件"
    fi
else
    echo "用法:"
    echo "  ./switch_main.sh test     # 切换到 FFmpeg Kit 测试模式"
    echo "  ./switch_main.sh restore  # 恢复到原始版本"
fi
