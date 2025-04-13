#!/bin/bash

# BITZ挖矿系统 - 安装依赖和创建钱包

# 颜色定义
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # 无颜色

# 工作目录
WORK_DIR="$HOME/bitz_mining"
mkdir -p "$WORK_DIR"

# 设置Solana路径
SOLANA_BIN="$HOME/.local/share/solana/install/active_release/bin"
export PATH="$SOLANA_BIN:$PATH"
export PATH="$HOME/.cargo/bin:$PATH"

# 显示标题
clear
echo -e "${BLUE}===============================================${NC}"
echo -e "${BLUE}      BITZ挖矿系统 - 安装依赖和创建钱包      ${NC}"
echo -e "${BLUE}    推特@XIAOLINBIJI  免费开源 勿信收费       ${NC}"
echo -e "${BLUE}===============================================${NC}"
echo ""

# 询问钱包数量
read -p "请输入要创建的钱包数量 [默认: 2]: " WALLET_COUNT
WALLET_COUNT=${WALLET_COUNT:-2}

echo -e "${BLUE}将创建 ${WALLET_COUNT} 个钱包${NC}"
echo -e "${YELLOW}注意: 创建钱包后，您需要向每个钱包地址发送至少0.0005 ETH才能开始挖矿${NC}\n"

# 确认操作
read -p "是否继续? [Y/n]: " CONFIRM
if [[ $CONFIRM =~ ^[Nn]$ ]]; then
    echo "脚本已取消"
    exit 0
fi

# 检查并安装依赖
echo -e "${GREEN}[1/5] 检查并安装依赖...${NC}"
sudo apt-get update
sudo apt-get install -y curl build-essential gcc make screen bc

# 安装Rust和Cargo
echo -e "${GREEN}[2/5] 安装Rust和Cargo...${NC}"
if ! command -v rustc &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y
    source "$HOME/.cargo/env"
else
    echo "Rust已安装，跳过..."
fi

# 安装Solana CLI
echo -e "${GREEN}[3/5] 安装Solana CLI...${NC}"
if ! command -v solana &> /dev/null; then
    curl --proto '=https' --tlsv1.2 -sSfL https://solana-install.solana.workers.dev | bash
    echo 'export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"' >> "$HOME/.bashrc"
    export PATH="$HOME/.local/share/solana/install/active_release/bin:$PATH"
else
    echo "Solana CLI已安装，跳过..."
fi

# 设置Solana配置
echo -e "${GREEN}[4/5] 设置Solana RPC端点...${NC}"
$SOLANA_BIN/solana config set --url https://eclipse.helius-rpc.com/

# 安装Bitz CLI
echo -e "${GREEN}[5/5] 安装Bitz CLI...${NC}"
if ! command -v bitz &> /dev/null; then
    cargo install bitz
else
    echo "Bitz CLI已安装，跳过..."
fi

# 记录钱包数量
echo "$WALLET_COUNT" > "$WORK_DIR/wallet_count.txt"

# 创建钱包
echo -e "${GREEN}正在创建 ${WALLET_COUNT} 个钱包...${NC}"

# 创建钱包信息汇总文件
echo "# Bitz挖矿钱包信息" > "$WORK_DIR/wallet_info.txt"
echo "创建日期: $(date)" >> "$WORK_DIR/wallet_info.txt"
echo "总计创建: $WALLET_COUNT 个钱包" >> "$WORK_DIR/wallet_info.txt"
echo "" >> "$WORK_DIR/wallet_info.txt"

# 创建CSV格式文件，方便导入
echo "钱包序号,钱包地址,钱包路径" > "$WORK_DIR/wallets.csv"

for ((i=1; i<=$WALLET_COUNT; i++)); do
    WALLET_FILE="$WORK_DIR/wallet$i.json"
    
    # 检查钱包是否已存在
    if [ ! -f "$WALLET_FILE" ]; then
        echo -e "${BLUE}创建钱包 $i...${NC}"
        $SOLANA_BIN/solana-keygen new -o "$WALLET_FILE" --no-passphrase
    else
        echo -e "${YELLOW}钱包 $i 已存在，跳过创建...${NC}"
    fi
    
    # 获取钱包地址
    WALLET_ADDRESS=$($SOLANA_BIN/solana address -k "$WALLET_FILE")
    
    echo -e "${GREEN}钱包 $i 地址: ${YELLOW}$WALLET_ADDRESS${NC}"
    
    # 添加到钱包信息文件
    echo "## 钱包 $i" >> "$WORK_DIR/wallet_info.txt"
    echo "地址: $WALLET_ADDRESS" >> "$WORK_DIR/wallet_info.txt"
    echo "钱包文件路径: $WALLET_FILE" >> "$WORK_DIR/wallet_info.txt"
    echo "" >> "$WORK_DIR/wallet_info.txt"
    
    # 添加到CSV文件
    echo "$i,$WALLET_ADDRESS,$WALLET_FILE" >> "$WORK_DIR/wallets.csv"
done

echo -e "\n${GREEN}======= 钱包创建完成! =======${NC}"
echo -e "${BLUE}总共创建了 ${WALLET_COUNT} 个钱包${NC}"
echo -e "${YELLOW}请向每个钱包地址发送至少0.0005 ETH以开始挖矿${NC}"
echo -e "\n${BLUE}钱包信息已保存在:${NC}"
echo -e "  ${YELLOW}- $WORK_DIR/wallet_info.txt${NC} (详细信息)"
echo -e "  ${YELLOW}- $WORK_DIR/wallets.csv${NC} (CSV格式，方便导入)"

# 等待用户确认
echo -e "\n${BLUE}按回车键返回主菜单...${NC}"
read