#!/bin/bash

# BITZ挖矿系统 - 开启脚本错误监控

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

# 日志文件
LOG_FILE="$WORK_DIR/bitz_monitor.log"

# 监控脚本文件
MONITOR_SCRIPT="$WORK_DIR/bitz_monitor.sh"

# 显示标题
clear
echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}        BITZ挖矿系统 - 错误监控设置          ${NC}"
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

# 检查是否有活跃的钱包
if [ ! -f "$WORK_DIR/active_wallet_count.txt" ]; then
    echo -e "${RED}错误: 尚未启动挖矿，请先运行选项2配置和启动挖矿${NC}"
    echo -e "\n${BLUE}按回车键返回主菜单...${NC}"
    read
    exit 1
fi

# 检查依赖
echo -e "${BLUE}检查必要组件...${NC}"
if ! command -v screen &> /dev/null; then
    echo -e "${YELLOW}安装screen命令...${NC}"
    sudo apt-get update
    sudo apt-get install -y screen
fi

# 获取检查间隔
echo -e "${BLUE}监控脚本会定期检查所有钱包的挖矿状态，并自动重启出错的挖矿进程${NC}"
read -p "请输入检查间隔(分钟) [默认: 5]: " CHECK_INTERVAL
CHECK_INTERVAL=${CHECK_INTERVAL:-5}

# 获取运行模式
echo -e "\n${BLUE}请选择监控脚本的运行模式:${NC}"
echo -e "${YELLOW}1.${NC} 作为服务运行 (推荐，系统级守护进程)"
echo -e "${YELLOW}2.${NC} 作为Screen会话运行"
echo -e "${YELLOW}3.${NC} 停止现有监控"
echo ""
read -p "请选择模式 [1-3]: " RUN_MODE
RUN_MODE=${RUN_MODE:-1}

# 创建监控脚本
echo -e "\n${GREEN}创建监控脚本...${NC}"

cat > "$MONITOR_SCRIPT" << 'EOL'
#!/bin/bash

# BITZ挖矿状态监控和自动重启脚本
# 用法: bash bitz_monitor.sh [检查间隔(分钟)]

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

# 默认检查间隔(分钟)
DEFAULT_CHECK_INTERVAL=5

# 日志文件
LOG_FILE="$WORK_DIR/bitz_monitor.log"

# 记录日志
log_message() {
    local message="$1"
    local timestamp=$(date "+%Y-%m-%d %H:%M:%S")
    echo "[$timestamp] $message" >> "$LOG_FILE"
    echo -e "$message"
}

# 检查是否安装了必要的工具
check_dependencies() {
    if ! command -v bitz &> /dev/null; then
        log_message "${RED}错误: bitz命令未找到，请确保已安装Bitz CLI${NC}"
        exit 1
    fi
    
    if ! command -v screen &> /dev/null; then
        log_message "${RED}错误: screen命令未找到，请安装screen: sudo apt-get install screen${NC}"
        exit 1
    fi
}

# 获取活跃钱包数量
get_wallet_count() {
    if [ -f "$WORK_DIR/active_wallet_count.txt" ]; then
        cat "$WORK_DIR/active_wallet_count.txt"
    elif [ -f "$WORK_DIR/wallet_count.txt" ]; then
        cat "$WORK_DIR/wallet_count.txt"
    else
        # 尝试计算钱包数量
        ls -1 "$WORK_DIR"/wallet*.json 2>/dev/null | wc -l
    fi
}

# 检查挖矿实例状态
check_mining_instance() {
    local wallet_num=$1
    local screen_name="bitz$wallet_num"
    local wallet_file="$WORK_DIR/wallet${wallet_num}.json"
    
    # 检查钱包文件是否存在
    if [ ! -f "$wallet_file" ]; then
        log_message "${RED}错误: 钱包文件 $wallet_file 不存在${NC}"
        return 1
    fi
    
    # 获取钱包地址
    local wallet_address=$($SOLANA_BIN/solana address -k "$wallet_file" 2>/dev/null)
    if [ -z "$wallet_address" ]; then
        log_message "${RED}错误: 无法获取钱包 $wallet_num 的地址${NC}"
        return 1
    fi
    
    # 检查screen会话是否存在
    if ! screen -list | grep -q "$screen_name"; then
        log_message "${YELLOW}钱包 $wallet_num ($wallet_address) 的挖矿实例不存在，正在启动...${NC}"
        # 获取CPU核心数设置
        local cores_per_instance=2
        if [ -f "$WORK_DIR/cores_per_instance.txt" ]; then
            cores_per_instance=$(cat "$WORK_DIR/cores_per_instance.txt")
        fi
        # 启动挖矿实例
        screen -dmS "$screen_name" bash -c "bitz collect --keypair \"$wallet_file\" --cores $cores_per_instance || bash"
        log_message "${GREEN}已启动钱包 $wallet_num ($wallet_address) 的挖矿实例${NC}"
        return 0
    fi
    
    # 检查是否有错误日志
    local screen_log="/tmp/bitz_screen_${wallet_num}.log"
    screen -S "$screen_name" -X hardcopy "$screen_log" 2>/dev/null
    
    if [ -f "$screen_log" ]; then
        # 检查错误模式
        if grep -q "RPC response error" "$screen_log" || \
           grep -q "Transaction simulation failed" "$screen_log" || \
           grep -q "custom program error" "$screen_log" || \
           grep -q "Error processing Instruction" "$screen_log"; then
            
            log_message "${RED}检测到钱包 $wallet_num ($wallet_address) 的挖矿实例出错，正在重启...${NC}"
            # 先关闭现有screen会话
            screen -X -S "$screen_name" quit
            
            # 等待一会儿确保完全关闭
            sleep 2
            
            # 获取CPU核心数设置
            local cores_per_instance=2
            if [ -f "$WORK_DIR/cores_per_instance.txt" ]; then
                cores_per_instance=$(cat "$WORK_DIR/cores_per_instance.txt")
            fi
            
            # 重新启动挖矿实例
            screen -dmS "$screen_name" bash -c "bitz collect --keypair \"$wallet_file\" --cores $cores_per_instance || bash"
            log_message "${GREEN}已重启钱包 $wallet_num ($wallet_address) 的挖矿实例${NC}"
        else
            # 检查最后活动时间
            local last_modified=$(stat -c %Y "$screen_log" 2>/dev/null)
            local current_time=$(date +%s)
            local time_diff=$((current_time - last_modified))
            
            # 如果超过30分钟没有更新，认为挖矿已停止
            if [ $time_diff -gt 1800 ]; then
                log_message "${YELLOW}钱包 $wallet_num ($wallet_address) 的挖矿实例超过30分钟无活动，正在重启...${NC}"
                # 先关闭现有screen会话
                screen -X -S "$screen_name" quit
                
                # 等待一会儿确保完全关闭
                sleep 2
                
                # 获取CPU核心数设置
                local cores_per_instance=2
                if [ -f "$WORK_DIR/cores_per_instance.txt" ]; then
                    cores_per_instance=$(cat "$WORK_DIR/cores_per_instance.txt")
                fi
                
                # 重新启动挖矿实例
                screen -dmS "$screen_name" bash -c "bitz collect --keypair \"$wallet_file\" --cores $cores_per_instance || bash"
                log_message "${GREEN}已重启钱包 $wallet_num ($wallet_address) 的挖矿实例${NC}"
            fi
        fi
        
        # 清理临时日志文件
        rm -f "$screen_log"
    fi
}

# 停止服务
stop_service() {
    if systemctl is-active --quiet bitz-monitor.service; then
        log_message "${YELLOW}正在停止BITZ挖矿监控服务...${NC}"
        sudo systemctl stop bitz-monitor.service
        sudo systemctl disable bitz-monitor.service
        log_message "${GREEN}BITZ挖矿监控服务已停止${NC}"
    else
        log_message "${YELLOW}BITZ挖矿监控服务未运行${NC}"
    fi
    
    # 检查是否有独立的监控进程在运行
    local monitor_pid=$(pgrep -f "bash.*bitz_monitor.*run")
    if [ ! -z "$monitor_pid" ]; then
        log_message "${YELLOW}检测到监控进程 (PID: $monitor_pid)，正在停止...${NC}"
        kill $monitor_pid
        log_message "${GREEN}监控进程已停止${NC}"
    fi
}

# 主监控循环
run_monitoring() {
    local check_interval=$1
    
    log_message "${GREEN}=== BITZ挖矿状态监控已启动 ===${NC}"
    log_message "${BLUE}检查间隔: ${YELLOW}$check_interval 分钟${NC}"
    log_message "${BLUE}日志文件: ${YELLOW}$LOG_FILE${NC}"
    
    while true; do
        log_message "${BLUE}=== 开始检查挖矿状态 ($(date)) ===${NC}"
        
        # 获取钱包数量
        local wallet_count=$(get_wallet_count)
        log_message "${BLUE}共有 $wallet_count 个钱包需要检查${NC}"
        
        # 检查每个钱包的挖矿状态
        for ((i=1; i<=$wallet_count; i++)); do
            check_mining_instance $i
            # 每次检查之间稍微暂停，避免系统负载过高
            sleep 2
        done
        
        log_message "${GREEN}检查完成，等待 $check_interval 分钟后进行下一次检查${NC}"
        log_message ""
        
        # 等待指定的时间间隔
        sleep $(($check_interval * 60))
    done
}

# 解析命令行参数
if [ "$1" == "run" ]; then
    # 内部命令，用于服务模式
    check_interval=${2:-$DEFAULT_CHECK_INTERVAL}
    check_dependencies
    run_monitoring $check_interval
    exit 0
fi

# 默认执行
check_interval=${1:-$DEFAULT_CHECK_INTERVAL}
check_dependencies
run_monitoring $check_interval
EOL

chmod +x "$MONITOR_SCRIPT"

# 根据选择的模式执行操作
case $RUN_MODE in
    1)
        # 作为系统服务运行
        echo -e "\n${BLUE}设置监控脚本作为系统服务运行...${NC}"
        
        # 创建服务配置文件
        SERVICE_FILE="/tmp/bitz-monitor.service"
        cat > "$SERVICE_FILE" << EOF
[Unit]
Description=BITZ挖矿状态监控服务
After=network.target

[Service]
Type=simple
User=$USER
ExecStart=$MONITOR_SCRIPT run $CHECK_INTERVAL
Restart=always
RestartSec=30

[Install]
WantedBy=multi-user.target
EOF

        # 安装服务
        echo -e "${YELLOW}正在安装BITZ挖矿监控服务...${NC}"
        sudo mv "$SERVICE_FILE" /etc/systemd/system/bitz-monitor.service
        sudo systemctl daemon-reload
        sudo systemctl enable bitz-monitor.service
        sudo systemctl start bitz-monitor.service
        
        echo -e "${GREEN}BITZ挖矿监控服务已安装并启动${NC}"
        echo -e "${BLUE}查看服务状态: ${YELLOW}sudo systemctl status bitz-monitor.service${NC}"
        echo -e "${BLUE}查看服务日志: ${YELLOW}sudo journalctl -u bitz-monitor.service -f${NC}"
        ;;
    2)
        # 作为Screen会话运行
        echo -e "\n${BLUE}设置监控脚本作为Screen会话运行...${NC}"
        
        # 检查是否已有运行中的监控
        if screen -list | grep -q "bitz_monitor"; then
            echo -e "${YELLOW}检测到已有监控会话正在运行，将先停止...${NC}"
            screen -X -S bitz_monitor quit
            sleep 2
        fi
        
        # 启动新的监控会话
        echo -e "${GREEN}启动监控会话...${NC}"
        screen -dmS bitz_monitor bash -c "$MONITOR_SCRIPT $CHECK_INTERVAL"
        
        echo -e "${GREEN}BITZ挖矿监控已在Screen会话中启动${NC}"
        echo -e "${BLUE}查看监控会话: ${YELLOW}screen -r bitz_monitor${NC}"
        echo -e "${BLUE}监控日志文件: ${YELLOW}$LOG_FILE${NC}"
        ;;
    3)
        # 停止现有监控
        echo -e "\n${BLUE}停止现有监控...${NC}"
        
        # 停止服务
        if systemctl is-active --quiet bitz-monitor.service; then
            echo -e "${YELLOW}正在停止BITZ挖矿监控服务...${NC}"
            sudo systemctl stop bitz-monitor.service
            sudo systemctl disable bitz-monitor.service
            echo -e "${GREEN}BITZ挖矿监控服务已停止${NC}"
        else
            echo -e "${YELLOW}BITZ挖矿监控服务未运行${NC}"
        fi
        
        # 停止Screen会话
        if screen -list | grep -q "bitz_monitor"; then
            echo -e "${YELLOW}停止监控Screen会话...${NC}"
            screen -X -S bitz_monitor quit
            echo -e "${GREEN}监控Screen会话已停止${NC}"
        else
            echo -e "${YELLOW}监控Screen会话未运行${NC}"
        fi
        
        # 检查是否有独立的监控进程在运行
        MONITOR_PID=$(pgrep -f "bash.*bitz_monitor.*run")
        if [ ! -z "$MONITOR_PID" ]; then
            echo -e "${YELLOW}检测到监控进程 (PID: $MONITOR_PID)，正在停止...${NC}"
            kill $MONITOR_PID
            echo -e "${GREEN}监控进程已停止${NC}"
        fi
        
        echo -e "${GREEN}所有BITZ挖矿监控程序已停止${NC}"
        ;;
    *)
        echo -e "${RED}无效选项，操作已取消${NC}"
        exit 1
        ;;
esac

# 等待用户确认
echo -e "\n${BLUE}按回车键返回主菜单...${NC}"
read