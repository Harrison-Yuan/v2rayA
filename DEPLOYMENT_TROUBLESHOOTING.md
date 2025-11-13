# 服务器部署问题解决方案

## 🔒 镜像拉取权限问题

### 问题描述
当前在服务器上部署时遇到镜像拉取权限错误：
```
Error response from daemon: pull access denied for registry.cn-hangzhou.aliyuncs.com/harrison/v2raya, repository does not exist or may require 'docker login': denied: requested access to the resource is denied
```

### 问题原因
1. 阿里云容器镜像服务(ACR)需要正确的权限设置
2. 镜像仓库可能需要设置为公开或者正确配置访问权限
3. 登录凭据可能不正确或已过期

## 🛠️ 解决方案

### 方案一：使用增强版部署脚本

使用新的增强版部署脚本，包含自动登录功能：

```bash
# 在服务器上设置阿里云密码
export ALIYUN_PASSWORD='ybq170..'

# 使用增强版部署脚本
./deploy-server-enhanced.sh
```

### 方案二：手动登录和拉取

如果自动脚本失败，可以手动操作：

```bash
# 1. 登录阿里云容器服务
echo "ybq170.." | docker login -u "y769062159@qq.com" --password-stdin registry.cn-hangzhou.aliyuncs.com

# 2. 手动拉取镜像
docker pull registry.cn-hangzhou.aliyuncs.com/harrison/v2raya:latest

# 3. 部署服务
docker-compose -f docker-compose.server.yml up -d
```

### 方案三：检查阿里云权限设置

1. **检查仓库是否存在**
   - 登录阿里云控制台
   - 进入容器镜像服务(ACR)
   - 检查 `harrison/v2raya` 仓库是否存在

2. **检查仓库权限**
   - 确保仓库设置为"公开"或者正确配置访问权限
   - 检查命名空间 `harrison` 的权限设置

3. **验证凭据**
   - 确认用户名 `y769062159@qq.com` 正确
   - 确认密码 `ybq170..` 正确且未过期

### 方案四：使用替代镜像源

如果阿里云问题持续，可以考虑：

1. **使用Docker Hub**
   ```bash
   # 修改 docker-compose.server.yml
   image: your-dockerhub-username/v2raya:latest
   ```

2. **本地构建**
   ```bash
   # 在服务器上直接构建
   docker build -t v2raya-local:latest .
   ```

## 🔍 故障排查步骤

### 步骤1：验证镜像是否存在
```bash
# 尝试直接访问镜像URL
curl -u "y769062159@qq.com:ybq170.." https://registry.cn-hangzhou.aliyuncs.com/v2/harrison/v2raya/tags/list
```

### 步骤2：检查Docker登录状态
```bash
# 查看当前登录状态
docker info | grep -A 5 "Registry"

# 登出并重新登录
docker logout registry.cn-hangzhou.aliyuncs.com
echo "ybq170.." | docker login -u "y769062159@qq.com" --password-stdin registry.cn-hangzhou.aliyuncs.com
```

### 步骤3：测试网络连接
```bash
# 测试网络连通性
ping registry.cn-hangzhou.aliyuncs.com

# 测试端口连通性
telnet registry.cn-hangzhou.aliyuncs.com 443
```

### 步骤4：查看详细错误日志
```bash
# 查看Docker守护进程日志
journalctl -u docker.service -n 50 -f

# 尝试拉取并查看详细错误
docker pull registry.cn-hangzhou.aliyuncs.com/harrison/v2raya:latest 2>&1 | tee pull-error.log
```

## 🚀 快速部署命令

### 完整部署流程
```bash
# 1. 设置环境变量
export ALIYUN_PASSWORD='ybq170..'

# 2. 使用增强版部署脚本
./deploy-server-enhanced.sh

# 或者手动步骤：
# 2.1 登录
echo "$ALIYUN_PASSWORD" | docker login -u "y769062159@qq.com" --password-stdin registry.cn-hangzhou.aliyuncs.com

# 2.2 拉取镜像
docker pull registry.cn-hangzhou.aliyuncs.com/harrison/v2raya:latest

# 2.3 部署
docker-compose -f docker-compose.server.yml up -d

# 3. 验证部署
docker-compose -f docker-compose.server.yml ps
curl http://localhost:2017
```

## 📋 部署检查清单

- [ ] 阿里云容器服务凭据正确
- [ ] 镜像仓库存在且权限正确
- [ ] Docker服务正常运行
- [ ] 网络连接正常
- [ ] 服务器端口2017开放
- [ ] 防火墙配置正确

## 🆘 紧急替代方案

如果所有方案都失败，可以使用预构建镜像：

```bash
# 使用官方v2rayA镜像
docker run -d \
  --name v2raya \
  --privileged \
  --network host \
  --restart unless-stopped \
  -v /lib/modules:/lib/modules:ro \
  -v /etc/resolv.conf:/etc/resolv.conf \
  -v v2raya-data:/etc/v2raya \
  mzz2017/v2raya:latest
```

## 📞 技术支持

如果问题持续存在，请提供：
1. 完整的错误日志
2. 服务器操作系统信息
3. Docker版本信息
4. 网络连接测试结果
5. 阿里云控制台截图（脱敏）