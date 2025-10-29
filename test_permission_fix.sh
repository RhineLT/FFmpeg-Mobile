#!/bin/bash

# Android 权限修复测试脚本
# 用于验证权限修复是否生效

echo "=========================================="
echo "  Android 权限修复 - 测试脚本"
echo "=========================================="
echo ""

# 1. 检查当前连接的设备
echo "[1/6] 检查 Android 设备连接..."
if ! adb devices | grep -q "device$"; then
    echo "❌ 未检测到 Android 设备，请连接设备或启动模拟器"
    exit 1
fi
echo "✅ 设备已连接"
echo ""

# 2. 卸载旧版本（如果存在）
echo "[2/6] 卸载旧版本应用（如果存在）..."
adb uninstall com.videocompressor.video_compressor 2>/dev/null
echo "✅ 清理完成"
echo ""

# 3. 构建应用
echo "[3/6] 构建应用..."
if ! flutter build apk --debug; then
    echo "❌ 构建失败"
    exit 1
fi
echo "✅ 构建成功"
echo ""

# 4. 安装应用
echo "[4/6] 安装应用..."
if ! flutter install; then
    echo "❌ 安装失败"
    exit 1
fi
echo "✅ 安装成功"
echo ""

# 5. 启动应用
echo "[5/6] 启动应用..."
adb shell am start -n com.videocompressor.video_compressor/.MainActivity
sleep 2
echo "✅ 应用已启动"
echo ""

# 6. 显示实时日志
echo "[6/6] 显示应用日志（按 Ctrl+C 停止）..."
echo "==================== 应用日志 ===================="
adb logcat -c  # 清除旧日志
adb logcat | grep -E "FFmpeg-Mobile|permission|Permission|PERMISSION|flutter"

