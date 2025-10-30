#!/bin/bash

# FFmpeg-Mobile 构建脚本
# 用于重新构建和安装应用

set -e  # 遇到错误时退出

echo "================================"
echo "FFmpeg-Mobile 构建脚本"
echo "================================"
echo ""

# 检查是否在项目根目录
if [ ! -f "pubspec.yaml" ]; then
    echo "❌ 错误: 请在项目根目录运行此脚本"
    exit 1
fi

# 步骤 1: 清理项目
echo "步骤 1/5: 清理项目..."
flutter clean
echo "✅ 清理完成"
echo ""

# 步骤 2: 获取依赖
echo "步骤 2/5: 获取依赖..."
flutter pub get
echo "✅ 依赖获取完成"
echo ""

# 步骤 3: 检查设备
echo "步骤 3/5: 检查连接的设备..."
if ! flutter devices | grep -q "android"; then
    echo "⚠️  警告: 未检测到 Android 设备"
    echo "请确保:"
    echo "  1. USB 调试已启用"
    echo "  2. 设备已通过 USB 连接"
    echo "  3. 已授权 USB 调试"
    echo ""
    read -p "是否继续构建? (y/n) " -n 1 -r
    echo ""
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        exit 1
    fi
else
    echo "✅ 检测到 Android 设备"
    flutter devices
fi
echo ""

# 步骤 4: 构建应用
echo "步骤 4/5: 构建应用..."
BUILD_TYPE=${1:-debug}  # 默认为 debug，可以通过参数传入 release

if [ "$BUILD_TYPE" = "release" ]; then
    echo "构建 Release 版本..."
    flutter build apk --release
    APK_PATH="build/app/outputs/flutter-apk/app-release.apk"
else
    echo "构建 Debug 版本..."
    flutter build apk --debug
    APK_PATH="build/app/outputs/flutter-apk/app-debug.apk"
fi
echo "✅ 构建完成"
echo ""

# 步骤 5: 安装应用
echo "步骤 5/5: 安装应用..."
if flutter devices | grep -q "android"; then
    flutter install
    echo "✅ 安装完成"
else
    echo "⚠️  未检测到设备，跳过安装"
    echo "APK 已构建到: $APK_PATH"
    echo "您可以手动安装此 APK"
fi
echo ""

echo "================================"
echo "✅ 构建流程完成！"
echo "================================"
echo ""
echo "如果遇到问题，请查看 FILE_PICKER_FIX.md 获取详细信息"
