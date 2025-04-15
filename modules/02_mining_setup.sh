#!/bin/bash

# BITZ挖矿系统 - 配置和启动挖矿

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

# 获取CPU核心数
TOTAL_CORES=$(nproc)

# 显示标题
clear
echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}         BITZ挖矿系统 - 配置和启动挖矿        ${NC}"
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

TOTAL_WALLET_COUNT=$(cat "$WORK_DIR/wallet_count.txt")

echo -e "${BLUE}系统中共有 ${TOTAL_WALLET_COUNT} 个钱包${NC}"

# 询问要启用的钱包数量
read -p "请输入要启用的钱包数量 [默认: $TOTAL_WALLET_COUNT]: " WALLET_COUNT
WALLET_COUNT=${WALLET_COUNT:-$TOTAL_WALLET_COUNT}

# 检查钱包数量是否有效
if [ $WALLET_COUNT -gt $TOTAL_WALLET_COUNT ]; then
    echo -e "${RED}错误: 指定的钱包数量 ($WALLET_COUNT) 超过了已创建的钱包数量 ($TOTAL_WALLET_COUNT)${NC}"
    echo -e "\n${BLUE}按回车键返回主菜单...${NC}"
    read
    exit 1
fi

if [ $WALLET_COUNT -le 0 ]; then
    echo -e "${RED}错误: 钱包数量必须大于0${NC}"
    echo -e "\n${BLUE}按回车键返回主菜单...${NC}"
    read
    exit 1
fi

# 询问总共要使用的CPU核心数
echo -e "${BLUE}您的系统有 ${TOTAL_CORES} 个CPU核心${NC}"
read -p "请输入所有钱包总共要使用的CPU核心数 [默认: $TOTAL_CORES]: " CORES_TO_USE
CORES_TO_USE=${CORES_TO_USE:-$TOTAL_CORES}

# 检查核心数是否有效
if [ $CORES_TO_USE -gt $TOTAL_CORES ]; then
    echo -e "${YELLOW}警告: 您设置的核心数 ($CORES_TO_USE) 超过了系统可用的核心数 ($TOTAL_CORES)${NC}"
    echo -e "${YELLOW}这可能导致性能下降。${NC}"
    read -p "是否继续? [y/N]: " CONTINUE
    if [[ ! $CONTINUE =~ ^[Yy]$ ]]; then
        echo "操作已取消"
        echo -e "\n${BLUE}按回车键返回主菜单...${NC}"
        read
        exit 0
    fi
fi

# 计算每个钱包实例使用的核心数
CORES_PER_INSTANCE=$(echo "scale=2; $CORES_TO_USE / $WALLET_COUNT" | bc)
CORES_PER_INSTANCE=$(echo "($CORES_PER_INSTANCE+0.5)/1" | bc) # 四舍五入
if [ $CORES_PER_INSTANCE -lt 1 ]; then
    CORES_PER_INSTANCE=1
fi

echo -e "${BLUE}每个钱包实例将使用约 ${CORES_PER_INSTANCE} 个CPU核心${NC}"

## 询问自动索赔间隔
#read -p "请输入自动索赔间隔(分钟)，0表示不自动索赔 [默认: 360]: " CLAIM_INTERVAL
#CLAIM_INTERVAL=${CLAIM_INTERVAL:-360}

# 询问钱包启动间隔时间
read -p "请输入每个钱包启动的间隔时间(秒)，0表示同时启动 [默认: 0]: " WALLET_START_INTERVAL
WALLET_START_INTERVAL=${WALLET_START_INTERVAL:-0}

# 显示启动配置摘要
echo -e "\n${BLUE}=== 挖矿配置摘要 ===${NC}"
echo -e "${YELLOW}将启动 ${WALLET_COUNT}/${TOTAL_WALLET_COUNT} 个挖矿实例${NC}"
echo -e "${YELLOW}总计使用 ${CORES_TO_USE}/${TOTAL_CORES} 个CPU核心${NC}"
echo -e "${YELLOW}每个实例使用约 ${CORES_PER_INSTANCE} 个CPU核心${NC}"

#if [ "$CLAIM_INTERVAL" -gt 0 ]; then
#    echo -e "${YELLOW}每 ${CLAIM_INTERVAL} 分钟自动索赔一次${NC}"
#else
#    echo -e "${YELLOW}不启用自动索赔${NC}"
#fi

if [ "$WALLET_START_INTERVAL" -gt 0 ]; then
    echo -e "${YELLOW}每个钱包将间隔 ${WALLET_START_INTERVAL} 秒依次启动${NC}"
    # 计算总启动时间
    TOTAL_START_TIME=$((WALLET_COUNT * WALLET_START_INTERVAL))
    echo -e "${YELLOW}所有钱包完全启动需要约 ${TOTAL_START_TIME} 秒 ($(($TOTAL_START_TIME / 60)) 分 $(($TOTAL_START_TIME % 60)) 秒)${NC}"
else
    echo -e "${YELLOW}所有钱包将同时启动${NC}"
fi

# 确认操作
echo ""
read -p "是否确认以上配置并启动挖矿? [Y/n]: " CONFIRM
if [[ $CONFIRM =~ ^[Nn]$ ]]; then
    echo "脚本已取消"
    echo -e "\n${BLUE}按回车键返回主菜单...${NC}"
    read
    exit 0
fi

# 保存配置
echo "$WALLET_COUNT" > "$WORK_DIR/active_wallet_count.txt"
echo "$CORES_PER_INSTANCE" > "$WORK_DIR/cores_per_instance.txt"
echo "$WALLET_START_INTERVAL" > "$WORK_DIR/wallet_start_interval.txt"

# 首先停止所有现有的挖矿实例
echo -e "\n${GREEN}停止所有现有的挖矿实例...${NC}"
for i in $(screen -ls | grep bitz | awk '{print $1}' | cut -d. -f1); do
    echo -e "${YELLOW}停止挖矿实例: $i${NC}"
    screen -X -S $i quit
done

# 等待确保所有实例完全停止
sleep 3

# 创建一个重启脚本
cat > "$WORK_DIR/restart_mining.sh" << EOL
#!/bin/bash
# 重启所有Bitz挖矿实例的脚本

# 关闭现有的挖矿screen会话
for i in \$(screen -ls | grep bitz | awk '{print \$1}' | cut -d. -f1); do
    screen -X -S \$i quit
done

# 等待确保所有实例完全停止
sleep 3

# 重启所有挖矿实例
cd "$WORK_DIR"

# 设置Solana路径
export PATH="$SOLANA_BIN:\$PATH"
export PATH="\$HOME/.cargo/bin:\$PATH"

# 设置钱包启动间隔(秒)
WALLET_START_INTERVAL=$WALLET_START_INTERVAL

echo "开始启动挖矿实例，钱包启动间隔: \$WALLET_START_INTERVAL 秒"
EOL

# 为选定的钱包添加挖矿命令
for ((i=1; i<=$WALLET_COUNT; i++)); do
    WALLET_FILE="$WORK_DIR/wallet$i.json"
    
    # 添加到重启脚本，包含延迟启动逻辑
    if [ "$WALLET_START_INTERVAL" -gt 0 ]; then
        echo "# 启动钱包 $i" >> "$WORK_DIR/restart_mining.sh"
        echo "echo \"启动钱包 $i 的挖矿实例...\"" >> "$WORK_DIR/restart_mining.sh"
        echo "screen -dmS bitz$i bash -c 'bitz collect --keypair \"$WALLET_FILE\" --cores $CORES_PER_INSTANCE || bash'" >> "$WORK_DIR/restart_mining.sh"
        
        # 除了最后一个钱包，其他都需要等待
        if [ "$i" -lt "$WALLET_COUNT" ]; then
            echo "echo \"等待 \$WALLET_START_INTERVAL 秒后启动下一个钱包...\"" >> "$WORK_DIR/restart_mining.sh"
            echo "sleep \$WALLET_START_INTERVAL" >> "$WORK_DIR/restart_mining.sh"
        fi
    else
        # 不需要间隔，直接启动
        echo "screen -dmS bitz$i bash -c 'bitz collect --keypair \"$WALLET_FILE\" --cores $CORES_PER_INSTANCE || bash'" >> "$WORK_DIR/restart_mining.sh"
    fi
done

# 添加完成提示
echo 'echo "所有挖矿实例已启动完成!"' >> "$WORK_DIR/restart_mining.sh"

chmod +x "$WORK_DIR/restart_mining.sh"

# 创建索赔脚本
cat > "$WORK_DIR/claim_all.sh" << EOL
#!/bin/bash
# 设置Solana路径
SOLANA_BIN="$SOLANA_BIN"
export PATH="\$SOLANA_BIN:\$PATH"
export PATH="\$HOME/.cargo/bin:\$PATH"

# 记录日志
echo "===== \$(date): 开始执行索赔 =====" >> "$WORK_DIR/claim_log.txt"

cd "$WORK_DIR"

# 获取启用的钱包数量
WALLET_COUNT=\$(cat "$WORK_DIR/active_wallet_count.txt" 2>/dev/null || echo "$WALLET_COUNT")

# 创建临时文件存储索赔结果
TEMP_RESULTS=\$(mktemp)

# 创建变量跟踪总索赔金额
TOTAL_CLAIMED=0

# 只索赔启用的钱包
for ((i=1; i<=\$WALLET_COUNT; i++)); do
    wallet="wallet\$i.json"
    
    # 检查钱包文件是否存在
    if [ ! -f "\$wallet" ]; then
        echo "===== 跳过不存在的钱包: \$wallet ====="
        continue
    fi
    
    echo "===== 从钱包索赔: \$wallet ====="
    WALLET_ADDRESS=\$(\$SOLANA_BIN/solana address -k "\$wallet")
    echo "钱包地址: \$WALLET_ADDRESS"
    
    # 获取钱包余额信息
    echo "获取钱包余额信息..."
    BALANCE_INFO=\$(bitz account --keypair "\$wallet" 2>&1)
    
    # 提取ETH余额
    ETH_BALANCE=\$(echo "\$BALANCE_INFO" | grep "ETH" | awk '{print \$(NF-1)}')
    if [ -z "\$ETH_BALANCE" ]; then
        ETH_BALANCE="0.0"
    fi
    echo "ETH余额: \$ETH_BALANCE ETH"
    
    # 只有当ETH余额足够时才执行索赔
    if (( \$(echo "\$ETH_BALANCE >= 0.0005" | bc -l) )); then
        # 执行索赔并记录结果
        echo "执行索赔命令: bitz claim --keypair \"\$wallet\" --rpc https://eclipse.helius-rpc.com/"
        RESULT=\$(echo "Y" | bitz claim --keypair "\$wallet" --rpc https://eclipse.helius-rpc.com/ 2>&1)
        echo "\$RESULT"
        
        # 尝试提取索赔金额
        CLAIMED_AMOUNT=\$(echo "\$RESULT" | grep -o "You are about to claim [0-9.]\+ BITZ" | grep -o "[0-9.]\+")
        
        # 检查是否成功提取金额
        if [ -n "\$CLAIMED_AMOUNT" ]; then
            echo "索赔金额: \$CLAIMED_AMOUNT BITZ" | tee -a "\$TEMP_RESULTS"
            # 累加总金额（使用bc进行浮点数计算）
            TOTAL_CLAIMED=\$(echo "\$TOTAL_CLAIMED + \$CLAIMED_AMOUNT" | bc)
        else
            # 检查是否有错误或无可索赔金额
            if echo "\$RESULT" | grep -q "Error"; then
                echo "索赔失败，发生错误" | tee -a "\$TEMP_RESULTS"
            elif echo "\$RESULT" | grep -q "Nothing to claim"; then
                echo "无可索赔金额" | tee -a "\$TEMP_RESULTS"
            else
                echo "无法确定索赔结果" | tee -a "\$TEMP_RESULTS"
            fi
        fi
    else
        echo "ETH余额不足，跳过索赔" | tee -a "\$TEMP_RESULTS"
    fi
    
    # 记录到全局日志
    echo "钱包: \$wallet (\$WALLET_ADDRESS) - 索赔结果: \$RESULT" >> "$WORK_DIR/claim_log.txt"
    
    echo ""
done

# 打印汇总信息
echo ""
echo "======= 索赔汇总 ======="
cat "\$TEMP_RESULTS"
echo "----------------------"
echo "总计索赔金额: \$TOTAL_CLAIMED BITZ"
echo "========================"

# 将汇总信息添加到日志
echo "" >> "$WORK_DIR/claim_log.txt"
echo "======= 索赔汇总 \$(date) =======" >> "$WORK_DIR/claim_log.txt"
cat "\$TEMP_RESULTS" >> "$WORK_DIR/claim_log.txt"
echo "----------------------" >> "$WORK_DIR/claim_log.txt"
echo "总计索赔金额: \$TOTAL_CLAIMED BITZ" >> "$WORK_DIR/claim_log.txt"
echo "========================" >> "$WORK_DIR/claim_log.txt"
echo "" >> "$WORK_DIR/claim_log.txt"

# 清理临时文件
rm "\$TEMP_RESULTS"

echo "===== \$(date): 索赔完成 =====" >> "$WORK_DIR/claim_log.txt"
echo "" >> "$WORK_DIR/claim_log.txt"
EOL

chmod +x "$WORK_DIR/claim_all.sh"

# 设置自动索赔定时任务
if [ "$CLAIM_INTERVAL" -gt 0 ]; then
    echo -e "\n${BLUE}设置每 ${CLAIM_INTERVAL} 分钟自动索赔一次...${NC}"
    
    # 创建一个临时文件
    TEMP_CRON=$(mktemp)
    
    # 导出当前的crontab
    crontab -l > "$TEMP_CRON" 2>/dev/null || true
    
    # 检查是否已经有相同的cron任务
    if grep -q "claim_all.sh" "$TEMP_CRON"; then
        echo -e "${YELLOW}自动索赔任务已存在，正在更新...${NC}"
        # 移除旧的索赔任务
        sed -i '/bitz_mining\/claim_all.sh/d' "$TEMP_CRON"
    fi
    
    # 添加新的索赔任务 - 修改为分钟级别的cron表达式
    echo "*/$CLAIM_INTERVAL * * * * $WORK_DIR/claim_all.sh >> $WORK_DIR/cron_claim.log 2>&1" >> "$TEMP_CRON"
    
    # 应用新的crontab
    crontab "$TEMP_CRON"
    
    # 清理临时文件
    rm "$TEMP_CRON"
    
    echo -e "${GREEN}自动索赔任务已设置，每 ${CLAIM_INTERVAL} 分钟执行一次${NC}"
else
    echo -e "${YELLOW}未设置自动索赔，您可以手动运行 $WORK_DIR/claim_all.sh 进行索赔${NC}"
fi

# 启动挖矿
echo -e "\n${GREEN}启动挖矿实例...${NC}"
bash "$WORK_DIR/restart_mining.sh"

# 挖矿启动完成
echo -e "\n${GREEN}====== 挖矿已启动! ======${NC}"
echo -e "${BLUE}已启用 ${WALLET_COUNT}/${TOTAL_WALLET_COUNT} 个钱包进行挖矿${NC}"
if [ "$WALLET_START_INTERVAL" -gt 0 ]; then
    echo -e "${BLUE}每个钱包间隔 ${WALLET_START_INTERVAL} 秒启动${NC}"
fi

echo -e "${BLUE}使用以下命令:${NC}"
echo -e "  ${YELLOW}- 查看运行中的挖矿实例: screen -ls${NC}"
echo -e "  ${YELLOW}- 连接到挖矿实例查看: screen -r bitz1${NC}"
echo -e "  ${YELLOW}- 分离挖矿实例: Ctrl+A 然后按 D${NC}"
echo -e "  ${YELLOW}- 手动索赔: $WORK_DIR/claim_all.sh${NC}"
echo -e "  ${YELLOW}- 重启所有挖矿实例: $WORK_DIR/restart_mining.sh${NC}"

if [ "$CLAIM_INTERVAL" -gt 0 ]; then
    echo -e "\n${BLUE}自动索赔设置:${NC}"
    echo -e "  ${YELLOW}- 频率: 每 ${CLAIM_INTERVAL} 分钟${NC}"
    echo -e "  ${YELLOW}- 索赔日志: $WORK_DIR/claim_log.txt${NC}"
    echo -e "  ${YELLOW}- Cron日志: $WORK_DIR/cron_claim.log${NC}"
fi

# 等待用户确认
echo -e "\n${BLUE}按回车键返回主菜单...${NC}"
read
