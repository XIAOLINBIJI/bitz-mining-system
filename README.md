# BITZ Mining System / BITZ挖矿系统

[English](#english) | [中文](#chinese)

<a name="english"></a>

## Overview

ePoW is a Proof of Work (PoW) mining mechanism specifically designed for token mining on EclipseFND. $BITZ is the first token to be mined on EclipseFND through the ePoW mechanism with a total supply of 5 million tokens.

## Features

- **Multi-wallet Support**: Create and manage multiple mining wallets
- **Automated Setup**: Quick installation of dependencies and wallet creation
- **Mining Configuration**: Easily customize mining parameters
- **Token Management**: Transfer BITZ and ETH between wallets
- **Error Monitoring**: Automatic detection and restart of failed mining instances
- **RPC Management**: Simple switching between different RPC nodes
- **Balance Tracking**: Query all wallets for BITZ and ETH balances

## Quick Installation

```bash
wget -O bitz_install.sh https://raw.githubusercontent.com/XIAOLINBIJI/bitz-mining-system/main/quick_install.sh && chmod +x bitz_install.sh && ./bitz_install.sh
```

## Usage Guide

### First-time Setup

1. Run option 1 to install dependencies and create wallets
2. Fund each wallet with at least 0.0005 ETH
3. Run option 2 to configure and start mining

### Routine Operations

- **Check Balances**: Use option 7 to view wallet balances
- **Transfer Tokens**: Use options 3/4 to transfer BITZ or ETH
- **Change RPC**: Use option 6 to switch RPC nodes
- **Monitor Mining**: Use option 5 to enable automatic monitoring

## System Requirements

- Linux-based operating system
- Internet connection
- Sufficient ETH for gas fees (minimum 0.0005 ETH per wallet)
- CPU with multiple cores for optimal performance

## Important Notes

1. Each wallet requires a minimum of 0.0005 ETH to start mining
2. The system allocates resources based on your CPU core count
3. When transferring tokens, a small amount is retained for transaction fees
4. Monitoring service automatically restarts failed mining instances

## Troubleshooting

| Issue | Solution |
|-------|----------|
| Mining won't start | Ensure each wallet has sufficient ETH balance |
| RPC connection error | Switch to another RPC address using option 6 |
| Low mining efficiency | Adjust the CPU cores used per wallet |
| Monitoring service issues | Manually stop all related processes before restarting |

## Mining Commands

Check running instances:
```bash
screen -ls
```

Connect to a specific mining instance:
```bash
screen -r bitz1
```

## FAQ

**Q: How much ETH is needed to start mining?**  
A: Each wallet needs at least 0.0005 ETH.

**Q: How can I check mining status?**  
A: Use `screen -ls` to view all running mining instances, then use `screen -r bitzN` (e.g., `screen -r bitz1`) to connect to a specific instance.

**Q: How can I optimize mining performance?**  
A: Adjust the number of CPU cores used per wallet, balance system resources, and ensure you're using stable and fast RPC nodes.

**Q: How often should auto-claim be set?**  
A: We recommend setting it to 60-360 minutes, adjusting based on your mining efficiency and network fee conditions.

<a name="chinese"></a>

## 简介

ePoW是一个工作量证明（PoW）的挖矿机制，专门用于 EclipseFND 上的代币挖掘。$BITZ 是第一个在 EclipseFND 上通过 ePoW 机制挖掘的代币。具有 500 万的总供应量。

## 系统功能

BITZ挖矿系统包含以下主要功能：

1. **安装依赖软件、创建钱包** - 自动安装所需软件并创建多个钱包
2. **配置和启动挖矿** - 设置挖矿参数并启动多钱包挖矿
3. **转移钱包中的BITZ** - 将所有钱包中的BITZ代币转移到指定地址
4. **转移钱包中的ETH** - 将所有钱包中的ETH转移到指定地址
5. **开启脚本错误监控** - 监控挖矿状态并自动重启出错的实例
6. **一键更换RPC** - 方便地更换RPC节点地址
7. **查询账户的BITZ和ETH余额** - 快速查看所有钱包的余额情况

## 安装说明

### 直接安装

1. 下载安装脚本
wget -O bitz_install.sh https://raw.githubusercontent.com/XIAOLINBIJI/bitz-mining-system/main/quick_install.sh && chmod +x bitz_install.sh && ./bitz_install.sh

### 使用流程

1. **首次使用**：
   - 运行选项1，安装依赖软件并创建钱包
   - 为每个钱包充值至少0.0005 ETH
   - 运行选项2，配置并启动挖矿

2. **日常操作**：
   - 使用选项7查询钱包余额
   - 使用选项3/4转移BITZ或ETH
   - 如需更换RPC，使用选项6
   - 如需监控挖矿状态，使用选项5

## 注意事项

1. 每个钱包至少需要0.0005 ETH才能开始挖矿
2. 系统会根据您的CPU核心数合理分配资源
3. 使用选项5启用监控后，系统将自动检测并重启出错的挖矿实例
4. 转移BITZ或ETH时，系统会保留少量余额以支付交易费用

## 故障排除

如果您遇到以下问题，请尝试相应的解决方案：

- **挖矿无法启动**：确保每个钱包有足够的ETH余额
- **RPC连接错误**：使用选项6更换为其他RPC地址
- **挖矿效率低**：适当降低每个钱包使用的CPU核心数
- **监控服务无法启动**：手动停止所有相关进程后重新启动

## 常见问题

**Q: 需要多少ETH才能开始挖矿？**  
A: 每个钱包至少需要0.0005 ETH。

**Q: 如何查看挖矿状态？**  
A: 使用`screen -ls`查看所有运行中的挖矿实例，然后使用`screen -r bitz数字`(例如`screen -r bitz1`)连接到特定实例查看详情。

**Q: 如何优化挖矿性能？**  
A: 调整每个钱包使用的CPU核心数，均衡分配系统资源，并确保使用稳定快速的RPC节点。

**Q: 自动索赔间隔应该设置多久？**  
A: 建议设置为60-360分钟，根据您的挖矿效率和网络费用情况调整。
