#!/bin/bash
# 配置文件验证脚本

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}    配置文件协调性验证${NC}"
echo -e "${GREEN}========================================${NC}"
echo ""

# 检查文件存在性
check_files() {
    echo -e "${YELLOW}=> 检查必要文件...${NC}"
    
    files=(
        "docker-compose.server.yml"
        "build.sh"
        "deploy-server.sh"
        "Dockerfile"
    )
    
    for file in "${files[@]}"; do
        if [ -f "$file" ]; then
            echo -e "${GREEN}✓ $file 存在${NC}"
        else
            echo -e "${RED}✗ $file 不存在${NC}"
            exit 1
        fi
    done
}

# 检查Docker镜像配置一致性
check_docker_config() {
    echo -e "${YELLOW}=> 检查Docker配置一致性...${NC}"
    
    # 从build.sh提取镜像信息
    BUILD_REGISTRY=$(grep "ALIYUN_REGISTRY=" build.sh | head -1 | cut -d'"' -f2)
    BUILD_NAMESPACE=$(grep "ALIYUN_NAMESPACE=" build.sh | head -1 | cut -d'"' -f2)
    BUILD_IMAGE_NAME=$(grep "IMAGE_NAME=" build.sh | head -1 | cut -d'"' -f2)
    BUILD_TAG=$(grep "VERSION=" build.sh | head -1 | cut -d'"' -f2)
    FULL_IMAGE="$BUILD_REGISTRY/$BUILD_NAMESPACE/$BUILD_IMAGE_NAME:$BUILD_TAG"
    
    # 从docker-compose.server.yml提取镜像信息
    COMPOSE_IMAGE=$(grep "image:" docker-compose.server.yml | head -1 | awk '{print $2}')
    
    if [ "$FULL_IMAGE" = "$COMPOSE_IMAGE" ]; then
        echo -e "${GREEN}✓ 镜像配置一致: $FULL_IMAGE${NC}"
    else
        echo -e "${RED}✗ 镜像配置不一致${NC}"
        echo -e "${RED}  build.sh: $FULL_IMAGE${NC}"
        echo -e "${RED}  docker-compose: $COMPOSE_IMAGE${NC}"
        exit 1
    fi
}

# 检查端口配置
check_ports() {
    echo -e "${YELLOW}=> 检查端口配置...${NC}"
    
    # 检查docker-compose中的端口暴露
    if grep -q "EXPOSE 2017" Dockerfile; then
        echo -e "${GREEN}✓ Dockerfile暴露端口2017${NC}"
    else
        echo -e "${RED}✗ Dockerfile未暴露端口2017${NC}"
        exit 1
    fi
    
    # 检查健康检查配置
    if grep -q "2017" docker-compose.server.yml; then
        echo -e "${GREEN}✓ docker-compose端口配置正确${NC}"
    else
        echo -e "${RED}✗ docker-compose端口配置错误${NC}"
        exit 1
    fi
}

# 检查卷挂载配置
check_volumes() {
    echo -e "${YELLOW}=> 检查卷挂载配置...${NC}"
    
    required_volumes=(
        "/lib/modules:/lib/modules:ro"
        "/etc/resolv.conf:/etc/resolv.conf"
        "v2raya-data:/etc/v2raya"
    )
    
    for volume in "${required_volumes[@]}"; do
        if grep -q "$volume" docker-compose.server.yml; then
            echo -e "${GREEN}✓ 卷挂载配置正确: $volume${NC}"
        else
            echo -e "${RED}✗ 卷挂载配置缺失: $volume${NC}"
            exit 1
        fi
    done
}

# 检查权限配置
check_permissions() {
    echo -e "${YELLOW}=> 检查权限配置...${NC}"
    
    if grep -q "privileged: true" docker-compose.server.yml; then
        echo -e "${GREEN}✓ 特权模式已启用${NC}"
    else
        echo -e "${RED}✗ 特权模式未启用${NC}"
        exit 1
    fi
    
    if grep -q "network_mode: host" docker-compose.server.yml; then
        echo -e "${GREEN}✓ 主机网络模式已启用${NC}"
    else
        echo -e "${RED}✗ 主机网络模式未启用${NC}"
        exit 1
    fi
}

# 检查环境变量
check_environment() {
    echo -e "${YELLOW}=> 检查环境变量配置...${NC}"
    
    required_envs=(
        "V2RAYA_ADDRESS=0.0.0.0:2017"
        "V2RAYA_CONFIG=/etc/v2raya"
    )
    
    for env in "${required_envs[@]}"; do
        if grep -q "$env" docker-compose.server.yml; then
            echo -e "${GREEN}✓ 环境变量配置正确: $env${NC}"
        else
            echo -e "${RED}✗ 环境变量配置缺失: $env${NC}"
            exit 1
        fi
    done
}

# 主验证流程
main() {
    check_files
    check_docker_config
    check_ports
    check_volumes
    check_permissions
    check_environment
    
    echo ""
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}✓ 所有配置检查通过！${NC}"
    echo -e "${GREEN}========================================${NC}"
    echo ""
    echo -e "${YELLOW}建议下一步操作:${NC}"
    echo -e "1. 构建镜像: ./build.sh"
    echo -e "2. 部署服务: ./deploy-server.sh"
    echo -e "3. 查看日志: docker-compose -f docker-compose.server.yml logs -f"
}

# 运行验证
main