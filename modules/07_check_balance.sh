#!/bin/bash

# BITZ挖矿系统 - 查询账户的BITZ和ETH余额

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
RPC_URL=$($SOLANA_BIN/solana config get | grep "RPC URL" | awk '{print $3}')

# 显示标题
clear
echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}        BITZ挖矿系统 - 查询账户余额           ${NC}"
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

echo -e "${BLUE}系统中共有 ${TOTAL_WALLET_COUNT} 个钱包，当前激活 ${ACTIVE_WALLET_COUNT} 个钱包${NC}"
echo -e "${BLUE}使用的RPC地址: ${YELLOW}$RPC_URL${NC}"
echo ""

# 提供查询选项
echo -e "${YELLOW}请选择查询方式:${NC}"
echo -e "${GREEN}1.${NC} 查询单个钱包余额"
echo -e "${GREEN}2.${NC} 查询所有钱包余额"
echo -e "${GREEN}3.${NC} 导出所有钱包余额为CSV文件"
echo ""
read -p "请输入选项 [1-3]: " QUERY_MODE

# 提取输出中的特定数值
extract_value() {
    local output="$1"
    local pattern="$2"
    local default="$3"
    
    # 从输出中提取匹配模式的行，然后提取数值
    local value=$(echo "$output" | grep -i "$pattern" | awk '{print $(NF-1)}')
    
    if [ -z "$value" ]; then
        echo "$default"
    else
        echo "$value"
    fi
}

# 查询单个钱包的余额
check_one_wallet() {
    local wallet_num=$1
    local wallet_file="$WORK_DIR/wallet${wallet_num}.json"
    
    # 检查钱包文件是否存在
    if [ ! -f "$wallet_file" ]; then
        echo -e "${RED}错误: 钱包文件 $wallet_file 不存在${NC}"
        return 1
    fi
    
    # 获取钱包地址
    local wallet_address=$($SOLANA_BIN/solana address -k "$wallet_file")
    
    echo -e "${BLUE}钱包 ${wallet_num}${NC} (地址: ${YELLOW}${wallet_address}${NC})"
    
    # 执行bitz account命令获取账户信息
    echo -e "${GREEN}正在查询余额信息...${NC}"
    local account_info=$(bitz account --keypair "$wallet_file" --rpc $RPC_URL 2>&1)
    
    # 提取各项数值
    local eth_balance=$(extract_value "$account_info" "ETH" "0.0")
    local bitz_balance=$(extract_value "$account_info" "Balance.*BITZ" "0.0")
    local proof_balance=$(extract_value "$account_info" "Proof.*Balance.*BITZ" "0.0")
    local lifetime_rewards=$(extract_value "$account_info" "Lifetime rewards" "0.0")
    local lifetime_hashes=$(extract_value "$account_info" "Lifetime hashes" "0")
    
    # 收集最近的哈希信息
    local last_hash=$(echo "$account_info" | grep "Last hash" | grep -v "at" | awk '{print $NF}')
    local last_hash_time=$(echo "$account_info" | grep "Last hash at" | awk '{print $NF}')
    
    echo -e "  ${CYAN}ETH余额:${NC} ${eth_balance} ETH"
    echo -e "  ${CYAN}BITZ余额:${NC} ${bitz_balance} BITZ"
    echo -e "  ${CYAN}证明余额:${NC} ${proof_balance} BITZ"
    echo -e "  ${CYAN}生命周期奖励:${NC} ${lifetime_rewards} BITZ"
    echo -e "  ${CYAN}生命周期哈希:${NC} ${lifetime_hashes}"
    
    if [ ! -z "$last_hash" ] && [ "$last_hash" != "0" ]; then
        echo -e "  ${CYAN}最近哈希:${NC} ${last_hash}"
    fi
    
    if [ ! -z "$last_hash_time" ] && [ "$last_hash_time" != "0" ]; then
        echo -e "  ${CYAN}最近哈希时间:${NC} ${last_hash_time}"
    fi
}

# 查询所有钱包的余额并计算总计
check_all_wallets() {
    local total_bitz=0
    local total_eth=0
    local wallet_count=0
    local csv_mode=$1
    local csv_file=""
    
    # 如果是CSV模式，创建CSV文件
    if [ "$csv_mode" = "csv" ]; then
        csv_file="$WORK_DIR/bitz_balances_$(date +%Y%m%d_%H%M%S).csv"
        echo "钱包序号,钱包地址,ETH余额,BITZ余额,证明余额,生命周期奖励,生命周期哈希,最近哈希,最近哈希时间" > "$csv_file"
    else
        echo -e "${BLUE}=== BITZ代币余额查询 - 所有钱包 ===${NC}"
        echo -e "查询时间: $(date)"
        echo -e ""
    fi
    
    local end_wallet=${2:-$TOTAL_WALLET_COUNT}
    
    # 收集所有钱包信息
    for ((i=1; i<=$end_wallet; i++)); do
        local wallet_file="$WORK_DIR/wallet$i.json"
        
        # 检查钱包文件是否存在
        if [ ! -f "$wallet_file" ]; then
            echo -e "${RED}跳过不存在的钱包: $wallet_file${NC}"
            continue
        fi
        
        # 获取钱包地址
        local wallet_address=$($SOLANA_BIN/solana address -k "$wallet_file")
        
        # 获取钱包余额信息
        if [ "$csv_mode" != "csv" ]; then
            echo -e "${BLUE}处理钱包 $i: $wallet_address${NC}"
        fi
        
        local account_info=$(bitz account --keypair "$wallet_file" --rpc $RPC_URL 2>&1)
        
        # 提取各项数值
        local eth_balance=$(extract_value "$account_info" "ETH" "0.0")
        local bitz_balance=$(extract_value "$account_info" "Balance.*BITZ" "0.0")
        local proof_balance=$(extract_value "$account_info" "Proof.*Balance.*BITZ" "0.0")
        local lifetime_rewards=$(extract_value "$account_info" "Lifetime rewards" "0.0")
        local lifetime_hashes=$(extract_value "$account_info" "Lifetime hashes" "0")
        
        # 收集最近的哈希信息
        local last_hash=$(echo "$account_info" | grep "Last hash" | grep -v "at" | awk '{print $NF}')
        local last_hash_time=$(echo "$account_info" | grep "Last hash at" | awk '{print $NF}')
        
        ((wallet_count++))
        
        # 转换为数字并累加总计
        local bitz_numeric=$(echo "$bitz_balance" | sed 's/[^0-9.]//g')
        if [ ! -z "$bitz_numeric" ]; then
            total_bitz=$(echo "$total_bitz + $bitz_numeric" | bc 2>/dev/null || echo "$total_bitz")
        fi
        
        local eth_numeric=$(echo "$eth_balance" | sed 's/[^0-9.]//g')
        if [ ! -z "$eth_numeric" ]; then
            total_eth=$(echo "$total_eth + $eth_numeric" | bc 2>/dev/null || echo "$total_eth")
        fi
        
        if [ "$csv_mode" = "csv" ]; then
            # 添加到CSV文件
            echo "$i,$wallet_address,$eth_balance,$bitz_balance,$proof_balance,$lifetime_rewards,$lifetime_hashes,$last_hash,$last_hash_time" >> "$csv_file"
        else
            # 普通格式输出
            echo -e "  ${CYAN}ETH余额:${NC} ${eth_balance} ETH"
            echo -e "  ${CYAN}BITZ余额:${NC} ${bitz_balance} BITZ"
            echo -e "  ${CYAN}证明余额:${NC} ${proof_balance} BITZ"
            echo -e "  ${CYAN}生命周期奖励:${NC} ${lifetime_rewards} BITZ"
            echo -e "  ${CYAN}生命周期哈希:${NC} ${lifetime_hashes}"
            
            if [ ! -z "$last_hash" ] && [ "$last_hash" != "0" ]; then
                echo -e "  ${CYAN}最近哈希:${NC} ${last_hash}"
            fi
            
            if [ ! -z "$last_hash_time" ] && [ "$last_hash_time" != "0" ]; then
                echo -e "  ${CYAN}最近哈希时间:${NC} ${last_hash_time}"
            fi
            
            echo ""
        fi
    done
    
    if [ "$csv_mode" = "csv" ]; then
        # CSV导出完成
        echo -e "${GREEN}已将BITZ余额导出到以下文件:${NC}"
        echo -e "${YELLOW}- $csv_file${NC}"
        
        # 添加总计数据
        echo "总计,,$total_eth,$total_bitz,,,,," >> "$csv_file"
    else
        # 显示汇总信息
        echo -e "${GREEN}=== 汇总信息 ===${NC}"
        echo -e "检查了 ${wallet_count}/${end_wallet} 个钱包"
        echo -e "ETH代币总计: ${YELLOW}${total_eth} ETH${NC}"
        echo -e "BITZ代币总计: ${YELLOW}${total_bitz} BITZ${NC}"
    fi
}

# 根据用户选择执行对应功能
case $QUERY_MODE in
    1)
        # 查询单个钱包
        read -p "请输入要查询的钱包序号: " WALLET_NUM
        if [[ ! $WALLET_NUM =~ ^[0-9]+$ ]] || [ $WALLET_NUM -le 0 ] || [ $WALLET_NUM -gt $TOTAL_WALLET_COUNT ]; then
            echo -e "${RED}错误: 无效的钱包序号，请输入1-$TOTAL_WALLET_COUNT之间的数字${NC}"
        else
            check_one_wallet $WALLET_NUM
        fi
        ;;
    2)
        # 查询所有钱包
        read -p "是否只查询激活的钱包? [Y/n]: " ACTIVE_ONLY
        if [[ ! $ACTIVE_ONLY =~ ^[Nn]$ ]]; then
            echo -e "${BLUE}仅查询 $ACTIVE_WALLET_COUNT 个激活的钱包${NC}"
            check_all_wallets "" $ACTIVE_WALLET_COUNT
        else
            echo -e "${BLUE}查询所有 $TOTAL_WALLET_COUNT 个钱包${NC}"
            check_all_wallets
        fi
        ;;
    3)
        # 导出CSV
        read -p "是否只导出激活的钱包? [Y/n]: " ACTIVE_ONLY
        if [[ ! $ACTIVE_ONLY =~ ^[Nn]$ ]]; then
            echo -e "${BLUE}仅导出 $ACTIVE_WALLET_COUNT 个激活的钱包${NC}"
            check_all_wallets "csv" $ACTIVE_WALLET_COUNT
        else
            echo -e "${BLUE}导出所有 $TOTAL_WALLET_COUNT 个钱包${NC}"
            check_all_wallets "csv"
        fi
        ;;
    *)
        echo -e "${RED}无效选项，请输入1-3之间的数字${NC}"
        ;;
esac

# 等待用户确认
echo -e "\n${BLUE}按回车键返回主菜单...${NC}"
read