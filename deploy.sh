#!/bin/bash

# Hexo博客部署脚本 (简化版)
# 适用于安知鱼主题的Hexo博客，使用Git部署到GitHub
# 所有内容都推送到main分支

# 设置颜色输出
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# 打印带颜色的消息
print_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

# 检查命令是否存在
check_command() {
    if ! command -v $1 &> /dev/null; then
        print_error "$1 未安装，请先安装 $1"
        exit 1
    fi
}

# 显示帮助信息
show_help() {
    echo "Hexo博客部署脚本 (简化版)"
    echo ""
    echo "用法: $0 [选项]"
    echo ""
    echo "选项:"
    echo "  -h, --help          显示此帮助信息"
    echo "  -s, --skip-clean    跳过清理步骤"
    echo "  -g, --skip-generate 跳过生成静态文件步骤"
    echo "  -f, --force         强制部署，忽略警告"
    echo "  -o, --open          部署完成后自动打开网站"
    echo ""
    echo "分支说明:"
    echo "  - main分支: 用于存放博客源代码和生成的静态内容"
    echo ""
}

# 解析命令行参数
SKIP_CLEAN=false
SKIP_GENERATE=false
FORCE=false
OPEN_SITE=false

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -s|--skip-clean)
            SKIP_CLEAN=true
            shift
            ;;
        -g|--skip-generate)
            SKIP_GENERATE=true
            shift
            ;;
        -f|--force)
            FORCE=true
            shift
            ;;
        -o|--open)
            OPEN_SITE=true
            shift
            ;;
        *)
            print_error "未知选项: $1"
            show_help
            exit 1
            ;;
    esac
done

# 1. 环境检查
print_info "检查环境..."

# 检查必要的命令
check_command "git"
check_command "node"
check_command "npm"

# 检查Hexo是否安装
if ! npm list -g hexo &> /dev/null; then
    if [ ! -d "node_modules/hexo" ]; then
        print_error "Hexo未安装，请先安装Hexo"
        print_info "运行: npm install -g hexo"
        exit 1
    fi
fi

# 2. 检查Git配置
print_info "检查Git配置..."

if [ -z "$(git config user.name)" ]; then
    print_warning "Git用户名未设置"
    read -p "请输入Git用户名: " git_username
    git config user.name "$git_username"
fi

if [ -z "$(git config user.email)" ]; then
    print_warning "Git邮箱未设置"
    read -p "请输入Git邮箱: " git_email
    git config user.email "$git_email"
fi

# 3. 检查SSH连接
print_info "检查SSH连接..."

if ! ssh -T git@github.com 2>&1 | grep -q "successfully authenticated"; then
    print_warning "无法通过SSH连接到GitHub"
    if [ "$FORCE" = false ]; then
        read -p "是否继续部署? (y/n): " -n 1 -r
        echo
        if [[ ! $REPLY =~ ^[Yy]$ ]]; then
            print_info "部署已取消"
            exit 0
        fi
    fi
fi

# 4. 初始化Git仓库并设置远程仓库（如果需要）
print_info "检查Git仓库状态..."

# 检查是否是Git仓库
if [ ! -d ".git" ]; then
    print_info "初始化Git仓库..."
    git init
    
    # 添加远程仓库
    print_info "添加远程仓库..."
    git remote add origin git@github.com:bigzzh2022/bigzzh2022.github.io.git
    
    # 设置main分支
    print_info "设置main分支..."
    git branch -M main
fi

# 确保远程仓库存在
if ! git remote get-url origin &> /dev/null; then
    print_info "添加远程仓库..."
    git remote add origin git@github.com:bigzzh2022/bigzzh2022.github.io.git
fi

# 5. 清理和生成静态文件
if [ "$SKIP_CLEAN" = false ]; then
    print_info "清理旧的静态文件..."
    hexo clean
fi

if [ "$SKIP_GENERATE" = false ]; then
    print_info "生成静态文件..."
    hexo generate
fi

# 6. 提交所有内容到main分支
print_info "提交所有内容到main分支..."

# 检查当前分支
current_branch=$(git branch --show-current)
if [ "$current_branch" != "main" ]; then
    print_info "切换到main分支..."
    git checkout main || git checkout -b main
fi

# 添加所有更改（包括生成的静态文件）
git add .

# 提交更改
commit_msg="Update blog - $(date '+%Y-%m-%d %H:%M:%S')"
git commit -m "$commit_msg"

# 推送到main分支
print_info "推送到main分支..."
git push origin main

# 7. 完成提示
print_success "部署完成！"
echo -e "${GREEN}所有内容已推送到main分支${NC}"
echo -e "${YELLOW}注意：请确保在GitHub设置中将Pages源设置为main分支${NC}"
echo -e "${YELLOW}设置路径：GitHub仓库 > Settings > Pages > Source > Deploy from a branch > Branch: main${NC}"

if [ "$OPEN_SITE" = true ]; then
    print_info "正在打开网站..."
    if command -v open &> /dev/null; then
        open https://bigzzh2022.github.io
    elif command -v xdg-open &> /dev/null; then
        xdg-open https://bigzzh2022.github.io
    else
        print_warning "无法自动打开网站，请手动访问: https://bigzzh2022.github.io"
    fi
fi

print_info "部署脚本执行完毕"