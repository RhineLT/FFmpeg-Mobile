#!/bin/bash

echo "========================================="
echo "FFmpeg-Mobile 应用诊断脚本"
echo "========================================="
echo ""

# 检查是否有设备连接
echo "1. 检查 ADB 设备连接..."
adb devices -l
echo ""

# 检查应用是否已安装
echo "2. 检查应用安装状态..."
adb shell pm list packages | grep com.videocompressor || echo "应用未安装"
echo ""

# 卸载旧版本
echo "3. 卸载旧版本（如果存在）..."
adb uninstall com.videocompressor.video_compressor 2>/dev/null || echo "未找到旧版本"
echo ""

# 清理项目
echo "4. 清理项目..."
flutter clean
echo ""

# 获取依赖
echo "5. 获取依赖..."
flutter pub get
echo ""

# 构建调试版本
echo "6. 构建调试版 APK..."
flutter build apk --debug
echo ""

# 检查 APK 是否生成
if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
    echo "✓ APK 构建成功"
    ls -lh build/app/outputs/flutter-apk/app-debug.apk
    echo ""
    
    # 安装应用
    echo "7. 安装应用..."
    adb install -r build/app/outputs/flutter-apk/app-debug.apk
    echo ""
    
    # 清除应用数据
    echo "8. 清除应用数据（全新启动）..."
    adb shell pm clear com.videocompressor.video_compressor
    echo ""
    
    # 启动应用
    echo "9. 启动应用..."
    adb shell am start -n com.videocompressor.video_compressor/.MainActivity
    echo ""
    
    echo "========================================="
    echo "应用已启动，正在查看日志..."
    echo "========================================="
    echo ""
    echo "按 Ctrl+C 停止日志查看"
    echo ""
    
    # 实时查看日志
    adb logcat -c  # 清除旧日志
    adb logcat | grep -E "flutter|FFmpeg|VideoCompressor|MainActivity|FATAL|AndroidRuntime"
else
    echo "✗ APK 构建失败"
    exit 1
fi
