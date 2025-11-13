#!/bin/bash
# V2rayA 服务器部署脚本

set -e

# 配置
COMPOSE_FILE="docker-compose.server.yml"
SERVICE_NAME="v2raya-server"
IMAGE_NAME="registry.cn-hangzhou.aliyuncs.com/harrison/v2raya:latest"

# 颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}     V2rayA - 服务器部署脚本${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检查Docker和Docker Compose
if ! command -v docker &> /dev/null; then
    echo -e "${RED}错误: Docker未安装${NC}"
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}错误: Docker Compose未安装${NC}"
    exit 1
fi

# 检查Docker是否运行
if ! docker info &> /dev/null; then
    echo -e "${RED}错误: Docker服务未运行${NC}"
    exit 1
fi

echo -e "${YELLOW}=> 拉取最新镜像...${NC}"
docker pull $IMAGE_NAME

echo -e "${YELLOW}=> 停止现有容器（如果存在）...${NC}"
docker-compose -f $COMPOSE_FILE down --remove-orphans 2>/dev/null || true

echo -e "${YELLOW}=> 启动服务...${NC}"
docker-compose -f $COMPOSE_FILE up -d

echo -e "${YELLOW}=> 等待服务启动...${NC}"
sleep 10

echo -e "${YELLOW}=> 检查服务状态...${NC}"
if docker-compose -f $COMPOSE_FILE ps | grep -q "Up"; then
    echo -e "${GREEN}✓ 服务启动成功！${NC}"
    echo -e "${GREEN}=> 访问地址: http://服务器IP:2017${NC}"
    echo -e "${GREEN}=> 查看日志: docker-compose -f $COMPOSE_FILE logs -f${NC}"
    echo -e "${GREEN}=> 停止服务: docker-compose -f $COMPOSE_FILE down${NC}"
else
    echo -e "${RED}✗ 服务启动失败！${NC}"
    echo -e "${RED}=> 查看错误日志: docker-compose -f $COMPOSE_FILE logs${NC}"
    exit 1
fi

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}部署完成！${NC}"
echo -e "${GREEN}========================================${NC}"