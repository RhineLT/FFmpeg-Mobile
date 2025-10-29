#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  修复 MissingPluginException 错误"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}问题分析:${NC}"
echo "MissingPluginException - permission_handler 插件无法工作"
echo "path_provider 插件也有通道错误"
echo ""

echo -e "${YELLOW}解决方案:${NC}"
echo "1. 移除对 permission_handler 的依赖"
echo "2. 使用 SimplePermissionService（不依赖插件）"
echo "3. file_picker 会自动处理权限请求"
echo "4. 使用固定路径代替 path_provider"
echo ""

echo -e "${YELLOW}修改内容:${NC}"
echo "✓ 创建 SimplePermissionService（无插件依赖）"
echo "✓ TaskManager 使用 SimplePermissionService"
echo "✓ 移除 pickVideos 中的权限检查"
echo "✓ 使用固定路径 /storage/emulated/0/Movies/FFmpeg-Mobile"
echo "✓ 删除 permission_diagnostic_screen"
echo ""

echo -e "${YELLOW}重新构建:${NC}"
echo ""

echo "1. 清理项目..."
flutter clean

echo ""
echo "2. 获取依赖..."
flutter pub get

echo ""
echo "3. 构建 APK..."
flutter build apk --debug

echo ""
if [ -f "build/app/outputs/flutter-apk/app-debug.apk" ]; then
    echo -e "${GREEN}✓ 构建成功！${NC}"
    echo ""
    echo "安装命令:"
    echo "  adb uninstall com.videocompressor.video_compressor"
    echo "  adb install -r build/app/outputs/flutter-apk/app-debug.apk"
else
    echo -e "${RED}✗ 构建失败${NC}"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
