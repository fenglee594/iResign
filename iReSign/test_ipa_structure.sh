#!/bin/bash

# IPA结构测试脚本
# 用于验证重签名后的IPA文件是否符合苹果标准

echo "=== IPA文件结构测试脚本 ==="

if [ $# -eq 0 ]; then
    echo "用法: $0 <IPA文件路径>"
    echo "例如: $0 ~/Downloads/app-resigned.ipa"
    exit 1
fi

IPA_FILE="$1"
TEMP_DIR=$(mktemp -d)

if [ ! -f "$IPA_FILE" ]; then
    echo "错误: 文件 '$IPA_FILE' 不存在"
    exit 1
fi

echo "正在测试IPA文件: $IPA_FILE"
echo "临时解压目录: $TEMP_DIR"

# 解压IPA文件
echo "正在解压IPA文件..."
unzip -q "$IPA_FILE" -d "$TEMP_DIR"

echo ""
echo "=== IPA文件内容结构 ==="
cd "$TEMP_DIR"
tree -L 3 2>/dev/null || find . -type d -print | head -20

echo ""
echo "=== 检查标准结构 ==="

# 检查是否存在Payload目录
if [ -d "Payload" ]; then
    echo "✓ Payload目录存在"
    
    # 检查Payload目录中是否有.app文件
    APP_COUNT=$(find Payload -name "*.app" -type d | wc -l)
    if [ $APP_COUNT -eq 1 ]; then
        echo "✓ Payload目录中包含1个.app应用包"
        APP_NAME=$(find Payload -name "*.app" -type d | head -1)
        echo "  应用包: $APP_NAME"
    elif [ $APP_COUNT -eq 0 ]; then
        echo "✗ Payload目录中没有找到.app应用包"
    else
        echo "✗ Payload目录中包含多个.app应用包 ($APP_COUNT个)"
    fi
else
    echo "✗ Payload目录不存在"
fi

# 检查是否存在不应该存在的文件
echo ""
echo "=== 检查临时文件 ==="
if [ -f "entitlements.plist" ]; then
    echo "✗ 发现临时文件: entitlements.plist (应该被排除)"
else
    echo "✓ 没有发现entitlements.plist临时文件"
fi

# 检查元数据文件
echo ""
echo "=== 元数据文件 ==="
if [ -f "iTunesMetadata.plist" ]; then
    echo "✓ 发现iTunesMetadata.plist"
fi

if [ -f "iTunesArtwork" ]; then
    echo "✓ 发现iTunesArtwork"
fi

# 列出所有文件
echo ""
echo "=== 所有文件列表 ==="
find . -type f | sort

# 清理临时目录
echo ""
echo "清理临时目录: $TEMP_DIR"
rm -rf "$TEMP_DIR"

echo ""
echo "=== 测试完成 ==="
echo "如果看到 ✓ 标记，说明结构正确"
echo "如果看到 ✗ 标记，说明存在问题"
