#!/bin/bash

# BITZ挖矿系统 - 一键更换RPC地址

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # 无颜色

# 工作目录
WORK_DIR="$HOME/bitz_mining"

# 设置Solana路径
SOLANA_BIN="$HOME/.local/share/solana/install/active_release/bin"
export PATH="$SOLANA_BIN:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# 显示标题
clear
echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}         BITZ挖矿系统 - 一键更换RPC地址        ${NC}"
echo -e "${BLUE}    推特@XIAOLINBIJI  免费开源 勿信收费       ${NC}"
echo -e "${BLUE}===============================================${NC}"
echo ""

# 检查钱包是否已创建
if [ ! -f "$WORK_DIR/wallet_count.txt" ]; then
    echo -e "${RED}错误: 尚未完成钱包创建，请先运行选项1进行安装和钱包创建${NC}"
    echo -e "\n${BLUE}按回车键返回主菜单...${NC}"
    read
    exit 1
fi

# 获取当前RPC地址
CURRENT_RPC=$($SOLANA_BIN/solana config get | grep "RPC URL" | awk '{print $3}')
echo -e "${BLUE}当前RPC地址: ${YELLOW}$CURRENT_RPC${NC}"

# 预设的RPC地址列表
echo -e "\n${BLUE}可用的RPC地址:${NC}"
echo -e "${YELLOW}1.${NC} https://eclipse.helius-rpc.com/ (默认)"
echo -e "${YELLOW}2.${NC} https://eclipse.lgns.net/"
echo -e "${YELLOW}3.${NC} https://mainnet.eclipse.rpcpool.com/"
echo -e "${YELLOW}4.${NC} 自定义RPC地址"
echo ""

# 询问用户选择
read -p "请选择要使用的RPC地址 [1-4]: " RPC_CHOICE

case $RPC_CHOICE in
    1)
        NEW_RPC="https://eclipse.helius-rpc.com/"
        ;;
    2)
        NEW_RPC="https://eclipse.lgns.net/"
        ;;
    3)
        NEW_RPC="https://mainnet.eclipse.rpcpool.com/"
        ;;
    4)
        read -p "请输入自定义RPC地址: " NEW_RPC
        if [ -z "$NEW_RPC" ]; then
            echo -e "${RED}错误: RPC地址不能为空${NC}"
            echo -e "\n${BLUE}按回车键返回主菜单...${NC}"
            read
            exit 1
        fi
        # 确保RPC URL以"/"结尾
        [[ "$NEW_RPC" != */ ]] && NEW_RPC="${NEW_RPC}/"
        ;;
    *)
        echo -e "${RED}无效选项，使用默认RPC地址${NC}"
        NEW_RPC="https://eclipse.helius-rpc.com/"
        ;;
esac

# 确认操作
echo -e "\n${BLUE}将更改RPC地址:${NC}"
echo -e "  ${YELLOW}旧RPC地址: $CURRENT_RPC${NC}"
echo -e "  ${YELLOW}新RPC地址: $NEW_RPC${NC}"
echo ""
read -p "是否确认更换RPC地址? [Y/n]: " CONFIRM
if [[ $CONFIRM =~ ^[Nn]$ ]]; then
    echo "操作已取消"
    echo -e "\n${BLUE}按回车键返回主菜单...${NC}"
    read
    exit 0
fi

# 更新Solana配置
echo -e "${GREEN}更新Solana配置...${NC}"
$SOLANA_BIN/solana config set --url "$NEW_RPC"
echo -e "${GREEN}Solana配置已更新为使用 $NEW_RPC${NC}"

# 更新脚本文件中的RPC地址
echo -e "${GREEN}更新BITZ挖矿脚本中的RPC地址...${NC}"
FILES_UPDATED=0

# 更新脚本文件
for SCRIPT_FILE in "$WORK_DIR"/*.sh; do
    if [ -f "$SCRIPT_FILE" ]; then
        # 备份文件
        cp "$SCRIPT_FILE" "${SCRIPT_FILE}.bak"
        
        # 替换RPC地址
        sed -i "s|$CURRENT_RPC|$NEW_RPC|g" "$SCRIPT_FILE"
        
        # 检查是否有更改
        if diff -q "$SCRIPT_FILE" "${SCRIPT_FILE}.bak" > /dev/null; then
            rm "${SCRIPT_FILE}.bak"  # 如果没有更改，删除备份
        else
            ((FILES_UPDATED++))
            rm "${SCRIPT_FILE}.bak"  # 更改后删除备份
        fi
    fi
done

# 显示更新结果
echo -e "${GREEN}已更新 $FILES_UPDATED 个脚本文件${NC}"

# 检查是否有活跃的挖矿实例
MINING_INSTANCES=$(screen -ls | grep bitz | wc -l)
if [ $MINING_INSTANCES -gt 0 ]; then
    echo -e "\n${BLUE}检测到 $MINING_INSTANCES 个正在运行的挖矿实例${NC}"
    read -p "是否重启所有挖矿实例以应用新的RPC地址? [Y/n]: " RESTART
    
    if [[ ! $RESTART =~ ^[Nn]$ ]]; then
        echo -e "${GREEN}重启所有挖矿实例...${NC}"
        
        # 如果有重启脚本，使用它
        if [ -f "$WORK_DIR/restart_mining.sh" ]; then
            bash "$WORK_DIR/restart_mining.sh"
        else
            # 停止所有挖矿实例
            for i in $(screen -ls | grep bitz | awk '{print $1}' | cut -d. -f1); do
                echo -e "${YELLOW}停止挖矿实例: $i${NC}"
                screen -X -S $i quit
            done
            
            # 等待确保所有实例完全停止
            sleep 3
            
            # 手动重启挖矿
            echo -e "${YELLOW}没有找到重启脚本，无法自动重启挖矿实例${NC}"
            echo -e "${YELLOW}请在主菜单中选择选项2重新配置并启动挖矿${NC}"
        fi
    else
        echo -e "${YELLOW}挖矿实例未重启，请注意当前运行的实例仍在使用旧的RPC地址${NC}"
        echo -e "${YELLOW}建议在方便时重新启动挖矿以应用新设置${NC}"
    fi
fi

echo -e "\n${GREEN}====== RPC地址更换完成! ======${NC}"
echo -e "${BLUE}已成功将RPC地址从 ${YELLOW}${CURRENT_RPC}${BLUE} 更改为 ${YELLOW}${NEW_RPC}${NC}"

# 等待用户确认
echo -e "\n${BLUE}按回车键返回主菜单...${NC}"
read