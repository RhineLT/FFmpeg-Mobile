#!/bin/bash

# 视频压缩器 - 快速开始脚本

echo "=================================="
echo "视频压缩器 - 快速开始"
echo "=================================="
echo ""

# 检查 Flutter
if ! command -v flutter &> /dev/null; then
    echo "⚠️  Flutter 未找到，使用本地安装的 Flutter"
    export PATH="$PATH:/workspaces/flutter/bin"
fi

# 显示 Flutter 版本
echo "📱 Flutter 版本:"
flutter --version | head -1
echo ""

# 进入项目目录（脚本所在目录）
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
cd "$SCRIPT_DIR"

# 显示项目信息
echo "📂 项目位置: $(pwd)"
echo ""

# 显示菜单
while true; do
    echo "请选择操作:"
    echo "  1) 检查项目状态 (flutter doctor)"
    echo "  2) 安装依赖 (flutter pub get)"
    echo "  3) 代码分析 (flutter analyze)"
    echo "  4) 运行测试 (flutter test)"
    echo "  5) 查看连接的设备 (flutter devices)"
    echo "  6) 运行应用 (flutter run)"
    echo "  7) 构建 Debug APK"
    echo "  8) 构建 Release APK"
    echo "  9) 清理项目 (flutter clean)"
    echo "  0) 退出"
    echo ""
    read -p "请输入选项 (0-9): " choice

    case $choice in
        1)
            echo ""
            echo "🔍 检查项目状态..."
            flutter doctor
            ;;
        2)
            echo ""
            echo "📦 安装依赖..."
            flutter pub get
            ;;
        3)
            echo ""
            echo "🔍 分析代码..."
            flutter analyze
            ;;
        4)
            echo ""
            echo "🧪 运行测试..."
            flutter test
            ;;
        5)
            echo ""
            echo "📱 查看连接的设备..."
            flutter devices
            ;;
        6)
            echo ""
            echo "🚀 运行应用..."
            echo "提示: 确保已连接设备或启动模拟器"
            flutter run
            ;;
        7)
            echo ""
            echo "🔨 构建 Debug APK..."
            flutter build apk --debug
            echo ""
            echo "✅ APK 位置: build/app/outputs/flutter-apk/app-debug.apk"
            ;;
        8)
            echo ""
            echo "🔨 构建 Release APK..."
            flutter build apk --release
            echo ""
            echo "✅ APK 位置: build/app/outputs/flutter-apk/app-release.apk"
            ;;
        9)
            echo ""
            echo "🧹 清理项目..."
            flutter clean
            echo "✅ 清理完成"
            ;;
        0)
            echo ""
            echo "👋 再见!"
            exit 0
            ;;
        *)
            echo ""
            echo "❌ 无效选项，请重试"
            ;;
    esac
    
    echo ""
    echo "=================================="
    echo ""
done
