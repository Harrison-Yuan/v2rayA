# 汉小密系统 - 服务器部署指南

## 📋 部署前检查清单

### ✅ 系统要求
- Linux服务器（推荐Ubuntu 20.04+ 或 CentOS 8+）
- Docker 20.10+
- Docker Compose 1.29+
- 至少2GB RAM
- 10GB可用磁盘空间

### ✅ 网络配置
- 开放端口：2017（v2rayA管理界面）
- 开放端口：按需开放代理端口（如1080, 1081等）
- 确保服务器能够访问阿里云容器服务

## 🚀 快速部署

### 1. 获取部署文件
```bash
# 克隆项目或下载部署文件
git clone <your-repo> /opt/v2rayA
cd /opt/v2rayA
```

### 2. 构建镜像（可选）
如果需要自定义构建：
```bash
# 确保设置了阿里云密码
export ALIYUN_PASSWORD='你的密码'

# 构建并推送镜像
./build.sh
```

### 3. 部署服务
```bash
# 使用部署脚本
./deploy-server.sh

# 或者手动部署
docker-compose -f docker-compose.server.yml up -d
```

## 📁 配置文件说明

### docker-compose.server.yml
```yaml
version: "3.8"

services:
  v2raya:
    image: registry.cn-hangzhou.aliyuncs.com/harrison/v2raya:latest  # 阿里云镜像
    container_name: v2raya-server
    privileged: true          # 需要特权模式运行
    network_mode: host        # 使用主机网络
    restart: unless-stopped   # 自动重启策略
    environment:
      - V2RAYA_ADDRESS=0.0.0.0:2017    # 监听地址
      - V2RAYA_CONFIG=/etc/v2raya     # 配置文件路径
    volumes:
      - /lib/modules:/lib/modules:ro   # 内核模块（必需）
      - /etc/resolv.conf:/etc/resolv.conf  # DNS配置
      - v2raya-data:/etc/v2raya        # 数据持久化
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"
    healthcheck:
      test: ["CMD", "wget", "--no-verbose", "--tries=1", "--spider", "http://localhost:2017/"]
      interval: 30s
      timeout: 10s
      retries: 3
      start_period: 40s

volumes:
  v2raya-data:
    driver: local
```

### build.sh（阿里云构建脚本）
- **目标平台**: linux/amd64（服务器优化）
- **镜像名称**: v2rayA
- **版本**: latest
- **阿里云仓库**: registry.cn-hangzhou.aliyuncs.com/harrison/v2raya:latest

## 🔧 管理命令

### 服务管理
```bash
# 启动服务
docker-compose -f docker-compose.server.yml up -d

# 停止服务
docker-compose -f docker-compose.server.yml down

# 重启服务
docker-compose -f docker-compose.server.yml restart

# 查看状态
docker-compose -f docker-compose.server.yml ps

# 查看日志
docker-compose -f docker-compose.server.yml logs -f
```

### 容器管理
```bash
# 进入容器
docker exec -it v2raya-server /bin/sh

# 查看容器信息
docker inspect v2raya-server

# 更新镜像
docker pull registry.cn-hangzhou.aliyuncs.com/harrison/hanxiaomi:25110616
docker-compose -f docker-compose.server.yml up -d
```

## 🐛 常见问题排查

### 1. 容器无法启动
```bash
# 检查日志
docker-compose -f docker-compose.server.yml logs

# 检查端口占用
netstat -tlnp | grep 2017

# 检查权限
docker exec v2raya-server id
```

### 2. 网络连接问题
```bash
# 测试网络连通性
docker exec v2raya-server ping baidu.com

# 检查DNS解析
docker exec v2raya-server nslookup google.com
```

### 3. 性能问题
```bash
# 查看资源使用
docker stats v2raya-server

# 检查系统日志
journalctl -u docker.service -f
```

## 🔒 安全配置

### 防火墙配置
```bash
# UFW (Ubuntu)
ufw allow 2017/tcp
ufw allow 1080/tcp  # 代理端口

# firewalld (CentOS)
firewall-cmd --permanent --add-port=2017/tcp
firewall-cmd --permanent --add-port=1080/tcp
firewall-cmd --reload
```

### 访问控制
- 首次访问 http://服务器IP:2017 设置管理员密码
- 建议配置HTTPS反向代理
- 定期更新镜像版本

## 📊 监控和日志

### 健康检查
- 内置健康检查：每30秒检查一次
- 访问地址：http://localhost:2017/
- 失败重试：最多3次

### 日志轮转
- 日志文件最大10MB
- 保留3个历史文件
- 自动清理旧日志

## 🔄 更新和维护

### 更新镜像
```bash
# 拉取最新镜像
docker pull registry.cn-hangzhou.aliyuncs.com/harrison/v2raya:latest

# 重新部署
docker-compose -f docker-compose.server.yml up -d

# 清理旧镜像
docker image prune -f
```

### 备份数据
```bash
# 备份配置文件
docker run --rm -v v2raya-data:/data -v $(pwd):/backup alpine tar czf /backup/v2raya-backup.tar.gz -C /data .

# 恢复备份
docker run --rm -v v2raya-data:/data -v $(pwd):/backup alpine tar xzf /backup/v2raya-backup.tar.gz -C /data
```

## 📞 技术支持

如遇到问题，请提供以下信息：
1. 服务器操作系统和版本
2. Docker和Docker Compose版本
3. 相关日志输出
4. 配置文件内容（脱敏后）

---

**注意**: 确保你的阿里云容器服务凭据安全，不要在公共场合暴露密码信息。