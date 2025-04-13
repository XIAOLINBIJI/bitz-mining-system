#!/bin/bash

# BITZ挖矿系统 - 一键安装脚本
# X：@XIAOLINBIJI
# GitHub: https://github.com/XIAOLINBIJI/bitz-mining-system

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # 无颜色

echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}          BITZ挖矿系统 - 一键安装            ${NC}"
echo -e "${BLUE}    推特@XIAOLINBIJI  免费开源 勿信收费       ${NC}"
echo -e "${BLUE}===============================================${NC}"
echo ""

# 检查基本依赖
echo -e "${GREEN}检查基本依赖...${NC}"
if ! command -v git &> /dev/null; then
    echo -e "${YELLOW}安装Git...${NC}"
    sudo apt-get update
    sudo apt-get install -y git
fi

# 定义安装目录
INSTALL_DIR="$HOME/bitz_mining"

# 检查是否已经存在安装目录
if [ -d "$INSTALL_DIR" ]; then
    echo -e "${YELLOW}检测到已存在安装目录: $INSTALL_DIR${NC}"
    read -p "是否重新安装? 这将删除现有数据 [y/N]: " REINSTALL
    if [[ $REINSTALL =~ ^[Yy]$ ]]; then
        echo -e "${YELLOW}备份现有数据并清空目录...${NC}"
        # 备份钱包文件
        if ls $INSTALL_DIR/wallet*.json &> /dev/null; then
            BACKUP_DIR="$HOME/bitz_backup_$(date +%Y%m%d_%H%M%S)"
            mkdir -p "$BACKUP_DIR"
            cp $INSTALL_DIR/wallet*.json "$BACKUP_DIR/" 2>/dev/null
            echo -e "${GREEN}已将钱包文件备份到: $BACKUP_DIR${NC}"
        fi
        # 清空目录
        rm -rf "$INSTALL_DIR"
    else
        echo "安装已取消"
        exit 0
    fi
fi

# 创建安装目录
mkdir -p "$INSTALL_DIR"

# 克隆仓库
echo -e "${GREEN}下载BITZ挖矿系统...${NC}"
git clone https://github.com/XIAOLINBIJI/bitz-mining-system.git "$INSTALL_DIR/temp" || {
    echo -e "${RED}下载失败，请检查网络连接或GitHub仓库地址${NC}"
    exit 1
}

# 移动文件
echo -e "${GREEN}安装系统文件...${NC}"
cp "$INSTALL_DIR/temp/bitz_mining.sh" "$INSTALL_DIR/"
mkdir -p "$INSTALL_DIR/scripts"

# 复制模块文件
cp -r "$INSTALL_DIR/temp/modules/"* "$INSTALL_DIR/scripts/"

# 设置执行权限
chmod +x "$INSTALL_DIR/bitz_mining.sh"
chmod +x "$INSTALL_DIR/scripts/"*.sh

# 清理临时文件
rm -rf "$INSTALL_DIR/temp"

# 创建快捷方式
if [ -d "$HOME/bin" ]; then
    echo -e "${GREEN}创建命令快捷方式...${NC}"
    ln -sf "$INSTALL_DIR/bitz_mining.sh" "$HOME/bin/bitz_mining"
    echo -e "${GREEN}您可以从任何位置通过运行 'bitz_mining' 命令启动BITZ挖矿系统${NC}"
fi

echo -e "\n${GREEN}====== BITZ挖矿系统安装完成! ======${NC}"
echo -e "${BLUE}系统已安装到: ${YELLOW}$INSTALL_DIR${NC}"
echo -e "${BLUE}您可以通过运行以下命令启动BITZ挖矿系统:${NC}"
echo -e "${YELLOW}bash $INSTALL_DIR/bitz_mining.sh${NC}"
echo ""
echo -e "${CYAN}是否现在启动BITZ挖矿系统? [Y/n]:${NC} "
read -r START_NOW

if [[ ! $START_NOW =~ ^[Nn]$ ]]; then
    bash "$INSTALL_DIR/bitz_mining.sh"
else
    echo -e "${GREEN}您可以稍后运行上述命令启动系统${NC}"
fi