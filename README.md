# s2s_vpn installation script

## 单一站点到站点 VPN 连接架构
VPC 具有挂载的虚拟私有网关，您的本地（远程）网络内包括一个客户网关设备，您必须配置该设备以启用 VPN 连接。必须更新 VPC 路由表，以使从 VPC 通向网络的任何流量可以转至虚拟私有网关。

![iShot_2023-11-12_13 46 02](https://github.com/ChengzeHsiao/s2s_vpn/assets/60311214/672e3ab3-de58-4625-9672-472494441e68)


## 安装脚本使用步骤如下：

### Step 1

Download this installation script to local

### Step 2

chmod +x  s2s_ipsecvpn.sh

### Step 3

./s2s_ipsecvpn.sh

