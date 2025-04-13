#!/bin/bash

# BITZ挖矿系统 - 转移钱包中的BITZ

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

# RPC地址
RPC_URL="https://eclipse.helius-rpc.com/"

# 显示标题
clear
echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}         BITZ挖矿系统 - 转移BITZ代币          ${NC}"
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

# 获取有多少个钱包
TOTAL_WALLET_COUNT=$(cat "$WORK_DIR/wallet_count.txt")
ACTIVE_WALLET_COUNT=$(cat "$WORK_DIR/active_wallet_count.txt" 2>/dev/null || echo "$TOTAL_WALLET_COUNT")

echo -e "${BLUE}系统中有 ${ACTIVE_WALLET_COUNT} 个激活的钱包${NC}"

# 询问目标钱包地址
read -p "请输入要转入BITZ的目标钱包地址: " TARGET_WALLET

# 验证钱包地址格式
if [ -z "$TARGET_WALLET" ] || [ ${#TARGET_WALLET} -lt 32 ]; then
    echo -e "${RED}错误: 无效的钱包地址，请提供有效的钱包地址${NC}"
    echo -e "\n${BLUE}按回车键返回主菜单...${NC}"
    read
    exit 1
fi

echo -e "${BLUE}将从 ${ACTIVE_WALLET_COUNT} 个钱包中转移BITZ至目标地址: ${YELLOW}${TARGET_WALLET}${NC}"

# 确认操作
read -p "是否确认转移操作? [Y/n]: " CONFIRM
if [[ $CONFIRM =~ ^[Nn]$ ]]; then
    echo "操作已取消"
    echo -e "\n${BLUE}按回车键返回主菜单...${NC}"
    read
    exit 0
fi

# 记录日志
LOG_FILE="$WORK_DIR/bitz_transfer_log.txt"
echo "===== $(date): 开始执行BITZ转账 =====" >> "$LOG_FILE"

# 创建临时文件存储转账结果
TEMP_BITZ_TRANSFERS=$(mktemp)

# 创建变量跟踪总转账金额
TOTAL_BITZ_TRANSFERRED=0

# 转移所有启用钱包中的BITZ
for ((i=1; i<=$ACTIVE_WALLET_COUNT; i++)); do
    WALLET_FILE="$WORK_DIR/wallet$i.json"
    
    # 检查钱包文件是否存在
    if [ ! -f "$WALLET_FILE" ]; then
        echo -e "${RED}跳过不存在的钱包: $WALLET_FILE${NC}"
        continue
    fi
    
    WALLET_ADDRESS=$($SOLANA_BIN/solana address -k "$WALLET_FILE")
    
    echo -e "\n${BLUE}处理钱包 $i: $WALLET_ADDRESS${NC}"
    
    # 获取钱包余额信息
    echo "获取钱包余额信息..."
    BALANCE_INFO=$(bitz account --keypair "$WALLET_FILE" --rpc $RPC_URL 2>&1)
    
    # 提取ETH余额
    ETH_BALANCE=$(echo "$BALANCE_INFO" | grep "ETH" | awk '{print $(NF-1)}')
    if [ -z "$ETH_BALANCE" ]; then
        ETH_BALANCE="0.0"
    fi
    echo -e "ETH余额: ${YELLOW}$ETH_BALANCE ETH${NC}"
    
    # 提取BITZ余额
    BITZ_BALANCE=$(echo "$BALANCE_INFO" | grep -i "Balance" | grep -i "BITZ" | head -1 | awk '{print $(NF-1)}')
    if [ -z "$BITZ_BALANCE" ]; then
        BITZ_BALANCE="0.0"
    fi
    echo -e "BITZ余额: ${YELLOW}$BITZ_BALANCE BITZ${NC}"
    
    # 转账BITZ代币（如果有余额且ETH足够）
    if (( $(echo "$BITZ_BALANCE > 0.0000002" | bc -l) )) && (( $(echo "$ETH_BALANCE >= 0.0005" | bc -l) )); then
        echo -e "${GREEN}准备转移BITZ: $WALLET_FILE -> $TARGET_WALLET${NC}"
        
        # 计算转账金额，保留0.0000001精度
        TRANSFER_AMOUNT=$(echo "$BITZ_BALANCE - 0.0000001" | bc)
        echo -e "准备转账 ${YELLOW}$TRANSFER_AMOUNT BITZ${NC} 至 ${YELLOW}$TARGET_WALLET${NC}"
        
        # 执行转账命令
        echo -e "${CYAN}执行转账...${NC}"
        BITZ_TRANSFER_RESULT=$(echo "Y" | bitz transfer --keypair "$WALLET_FILE" --rpc $RPC_URL $TRANSFER_AMOUNT $TARGET_WALLET 2>&1)
        echo "$BITZ_TRANSFER_RESULT"
        
        # 检查转账结果
        if ! echo "$BITZ_TRANSFER_RESULT" | grep -q "Error"; then
            echo -e "${GREEN}BITZ转账成功: $TRANSFER_AMOUNT BITZ${NC}" | tee -a "$TEMP_BITZ_TRANSFERS"
            # 累加总转账金额
            TOTAL_BITZ_TRANSFERRED=$(echo "$TOTAL_BITZ_TRANSFERRED + $TRANSFER_AMOUNT" | bc)
        else
            echo -e "${RED}BITZ转账失败${NC}" | tee -a "$TEMP_BITZ_TRANSFERS"
        fi
        
        # 记录到全局日志
        echo "钱包: wallet$i.json ($WALLET_ADDRESS) - BITZ转账结果: $BITZ_TRANSFER_RESULT" >> "$LOG_FILE"
        
        # 等待转账交易完成
        sleep 5
    elif (( $(echo "$BITZ_BALANCE <= 0.0000002" | bc -l) )); then
        echo -e "${YELLOW}BITZ余额太小，跳过BITZ转账${NC}" | tee -a "$TEMP_BITZ_TRANSFERS"
    else
        echo -e "${YELLOW}ETH余额不足，跳过BITZ转账${NC}" | tee -a "$TEMP_BITZ_TRANSFERS"
    fi
    
    # 短暂休息，避免RPC节点限制
    sleep 2
done

# 打印汇总信息
echo -e "\n${GREEN}======= BITZ转账汇总 =======${NC}"
cat "$TEMP_BITZ_TRANSFERS"
echo -e "${BLUE}----------------------${NC}"
echo -e "${GREEN}总计BITZ转账金额: ${YELLOW}$TOTAL_BITZ_TRANSFERRED BITZ${NC}"
echo -e "${GREEN}目标钱包地址: ${YELLOW}$TARGET_WALLET${NC}"
echo -e "${BLUE}========================${NC}"

# 将汇总信息添加到日志
echo "" >> "$LOG_FILE"
echo "======= BITZ转账汇总 $(date) =======" >> "$LOG_FILE"
cat "$TEMP_BITZ_TRANSFERS" >> "$LOG_FILE"
echo "----------------------" >> "$LOG_FILE"
echo "总计BITZ转账金额: $TOTAL_BITZ_TRANSFERRED BITZ" >> "$LOG_FILE"
echo "目标钱包地址: $TARGET_WALLET" >> "$LOG_FILE"
echo "========================" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# 清理临时文件
rm "$TEMP_BITZ_TRANSFERS"

echo "===== $(date): BITZ转账完成 =====" >> "$LOG_FILE"
echo "" >> "$LOG_FILE"

# 等待用户确认
echo -e "\n${BLUE}按回车键返回主菜单...${NC}"
read
