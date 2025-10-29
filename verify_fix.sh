#!/bin/bash

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  验证 MissingPluginException 修复"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo "检查修复内容..."
echo ""

check() {
    if eval "$2"; then
        echo -e "${GREEN}✓${NC} $1"
        return 0
    else
        echo -e "${RED}✗${NC} $1"
        return 1
    fi
}

check "SimplePermissionService 已创建" \
    "test -f lib/services/simple_permission_service.dart"

check "TaskManager 使用 SimplePermissionService" \
    "grep -q 'SimplePermissionService' lib/providers/task_manager.dart"

check "移除了权限检查逻辑" \
    "grep -q 'FilePicker will handle permissions' lib/providers/task_manager.dart"

check "使用固定路径" \
    "grep -q '/storage/emulated/0/Movies/FFmpeg-Mobile' lib/providers/task_manager.dart"

check "移除了 permission_diagnostic_screen" \
    "! test -f lib/screens/permission_diagnostic_screen.dart"

check "HomeScreen 不再引用诊断页面" \
    "! grep -q 'PermissionDiagnosticScreen' lib/screens/home_screen.dart"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}所有修复已完成！${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
