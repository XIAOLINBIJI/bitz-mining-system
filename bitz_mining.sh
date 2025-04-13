#!/bin/bash

# BITZ挖矿系统 - 主菜单脚本
# 提供模块化功能和用户友好的界面

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # 无颜色

# 定义工作目录
WORK_DIR="$HOME/bitz_mining"
SCRIPTS_DIR="$WORK_DIR/scripts"

# 创建必要的目录
mkdir -p "$WORK_DIR"
mkdir -p "$SCRIPTS_DIR"

# 设置Solana路径
SOLANA_BIN="$HOME/.local/share/solana/install/active_release/bin"
export PATH="$SOLANA_BIN:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# 显示标题
show_title() {
    clear
    echo -e "${BLUE}===============================================${NC}"
    echo -e "${BLUE}            BITZ挖矿系统管理工具             ${NC}"
    echo -e "${BLUE}    推特@XIAOLINBIJI  免费开源 勿信收费       ${NC}"
    echo -e "${BLUE}               脚本问题可推特私信             ${NC}"
    echo -e "${BLUE}===============================================${NC}"
    echo -e "${YELLOW}当前工作目录: ${WORK_DIR}${NC}"
    echo -e "${BLUE}===============================================${NC}"
    echo ""
}

# 复制所有模块脚本到工作目录
copy_module_scripts() {
    # 获取当前脚本目录
    CURRENT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    
    # 复制模块脚本
    cp "$CURRENT_DIR/modules/01_install_setup.sh" "$SCRIPTS_DIR/"
    cp "$CURRENT_DIR/modules/02_mining_setup.sh" "$SCRIPTS_DIR/"
    cp "$CURRENT_DIR/modules/03_transfer_bitz.sh" "$SCRIPTS_DIR/"
    cp "$CURRENT_DIR/modules/04_transfer_eth.sh" "$SCRIPTS_DIR/"
    cp "$CURRENT_DIR/modules/05_monitor_setup.sh" "$SCRIPTS_DIR/"
    cp "$CURRENT_DIR/modules/06_change_rpc.sh" "$SCRIPTS_DIR/"
    cp "$CURRENT_DIR/modules/07_check_balance.sh" "$SCRIPTS_DIR/"
    
    # 设置执行权限
    chmod +x "$SCRIPTS_DIR"/*.sh
    
    echo -e "${GREEN}所有模块脚本已复制到 $SCRIPTS_DIR 目录${NC}"
}

# 主菜单
show_main_menu() {
    show_title
    echo -e "${CYAN}请选择要执行的操作:${NC}"
    echo -e "${YELLOW}1.${NC} 安装依赖软件、创建钱包"
    echo -e "${YELLOW}2.${NC} 配置和启动挖矿"
    echo -e "${YELLOW}3.${NC} 转移钱包中的BITZ"
    echo -e "${YELLOW}4.${NC} 转移钱包中的ETH"
    echo -e "${YELLOW}5.${NC} 开启脚本错误监控"
    echo -e "${YELLOW}6.${NC} 一键更换RPC"
    echo -e "${YELLOW}7.${NC} 查询账户的BITZ和ETH余额"
    echo -e "${YELLOW}0.${NC} 退出"
    echo ""
    read -p "请输入选项 [0-7]: " choice
    
    case $choice in
        1)
            # 执行安装依赖和创建钱包脚本
            bash "$SCRIPTS_DIR/01_install_setup.sh"
            ;;
        2)
            # 执行配置和启动挖矿脚本
            bash "$SCRIPTS_DIR/02_mining_setup.sh"
            ;;
        3)
            # 执行转移BITZ脚本
            bash "$SCRIPTS_DIR/03_transfer_bitz.sh"
            ;;
        4)
            # 执行转移ETH脚本
            bash "$SCRIPTS_DIR/04_transfer_eth.sh"
            ;;
        5)
            # 执行错误监控脚本
            bash "$SCRIPTS_DIR/05_monitor_setup.sh"
            ;;
        6)
            # 执行更换RPC脚本
            bash "$SCRIPTS_DIR/06_change_rpc.sh"
            ;;
        7)
            # 执行余额查询脚本
            bash "$SCRIPTS_DIR/07_check_balance.sh"
            ;;
        0)
            echo -e "${GREEN}感谢使用BITZ挖矿系统，再见!${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}无效选项，请重新选择${NC}"
            sleep 2
            ;;
    esac
    
    # 返回主菜单
    show_main_menu
}

# 检查是否是第一次运行
if [ ! -d "$SCRIPTS_DIR" ] || [ -z "$(ls -A "$SCRIPTS_DIR" 2>/dev/null)" ]; then
    echo -e "${YELLOW}首次运行，准备复制模块脚本...${NC}"
    copy_module_scripts
fi

# 显示主菜单
show_main_menu