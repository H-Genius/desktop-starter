#!/bin/bash

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

log_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

log_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

log_error() {
    echo -e "${RED}❌ $1${NC}"
}

command_exists() {
    command -v "$1" >/dev/null 2>&1
}

get_shell_profile() {
    local current_shell
    current_shell=$(basename "${SHELL:-bash}")
    case "$current_shell" in
        bash)
            echo "$HOME/.bashrc"
            ;;
        zsh)
            echo "$HOME/.zshrc"
            ;;
        fish)
            echo "$HOME/.config/fish/config.fish"
            ;;
        *)
            echo "$HOME/.profile"
            ;;
    esac
}

clean_npmrc_conflict() {
    local npmrc="$HOME/.npmrc"
    if [[ -f "$npmrc" ]]; then
        log_info "Cleaning npmrc conflicts..."
        grep -Ev '^(prefix|globalconfig) *= *' "$npmrc" > "${npmrc}.tmp" && mv -f "${npmrc}.tmp" "$npmrc" || true
    fi
}

install_uv() {
    local platform
    platform=$(uname -s)

    if command_exists uv; then
        log_success "uv is already installed"
        log_info "uv version: $(uv --version 2>/dev/null || echo 'version info not available')"
        return 0
    fi

    log_info "Installing uv..."

    case "$platform" in
        Linux|Darwin)
            if curl -LsSf https://astral.sh/uv/install.sh | sh; then
                log_success "uv installed successfully"
                export PATH="$HOME/.cargo/bin:$PATH"
                return 0
            fi
            ;;
        MINGW*|CYGWIN*|MSYS*)
            if powershell -ExecutionPolicy ByPass -c "irm https://astral.sh/uv/install.ps1 | iex"; then
                log_success "uv installed successfully"
                return 0
            fi
            ;;
    esac

    log_error "Failed to install uv"
    return 1
}

download_nvm_offline() {
    local version=${1:-v0.40.3}
    local out_dir=${2:-"/tmp/nvm-offline-${version}"}
    local package_url="https://cloud.iflow.cn/iflow-cli/nvm-${version}.tar.gz"
    local temp_file="/tmp/nvm-${version}.tar.gz"

    log_info "Downloading nvm ${version} package to ${out_dir}"
    mkdir -p "${out_dir}"

    if curl -sSL --connect-timeout 10 --max-time 60 "${package_url}" -o "${temp_file}"; then
        if tar -xzf "${temp_file}" -C "${out_dir}"; then
            rm -f "${temp_file}"
            if [ -f "${out_dir}/nvm-exec" ]; then
                chmod +x "${out_dir}/nvm-exec"
            fi
            log_success "nvm downloaded and extracted successfully"
            return 0
        fi
    fi

    rm -f "${temp_file}"
    log_error "Failed to download nvm package"
    return 1
}

install_nvm() {
    local nvm_dir="${NVM_DIR:-$HOME/.nvm}"
    local nvm_version="${NVM_VERSION:-v0.40.3}"
    local tmp_offline_dir="/tmp/nvm-offline-${nvm_version}"

    if [ -s "$nvm_dir/nvm.sh" ]; then
        log_info "nvm is already installed at $nvm_dir"
        return 0
    fi

    if ! download_nvm_offline "${nvm_version}" "${tmp_offline_dir}"; then
        return 1
    fi

    log_info "Installing nvm to ${nvm_dir}"
    mkdir -p "${nvm_dir}"
    cp "${tmp_offline_dir}/"{nvm.sh,nvm-exec,bash_completion} "${nvm_dir}/" || return 1
    chmod +x "${nvm_dir}/nvm-exec"

    local profile_file
    profile_file=$(get_shell_profile)

    if ! grep -q 'NVM_DIR' "${profile_file}" 2>/dev/null; then
        cat >> "${profile_file}" <<EOF

export NVM_DIR="${nvm_dir}"
[ -s "\$NVM_DIR/nvm.sh" ] && \. "\$NVM_DIR/nvm.sh"
[ -s "\$NVM_DIR/bash_completion" ] && \. "\$NVM_DIR/bash_completion"
EOF
        log_info "Added nvm to ${profile_file}"
    fi

    rm -rf "${tmp_offline_dir}"
    log_success "nvm installed successfully"
}

install_nodejs_with_nvm() {
    local node_version="${NODE_VERSION:-22}"
    local nvm_dir="${NVM_DIR:-$HOME/.nvm}"

    export NVM_DIR="${nvm_dir}"
    [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

    if ! command_exists nvm; then
        log_error "nvm not loaded properly"
        return 1
    fi

    if ! command_exists xz; then
        if command_exists yum; then
            sudo yum install -y xz || true
        elif command_exists apt-get; then
            sudo apt-get update && sudo apt-get install -y xz-utils || true
        fi
    fi

    export NVM_NODEJS_ORG_MIRROR="https://npmmirror.com/mirrors/node"
    log_info "Clearing nvm cache..."
    nvm cache clear || true

    log_info "Installing Node.js v${node_version}..."
    if nvm install "${node_version}"; then
        nvm alias default "${node_version}"
        nvm use default
        log_success "Node.js v${node_version} installed successfully"
        log_info "Node.js version: $(node -v)"
        log_info "npm version: $(npm -v)"
        clean_npmrc_conflict
        npm config set registry https://registry.npmmirror.com
        return 0
    fi

    log_error "Failed to install Node.js"
    return 1
}

check_node_version() {
    if ! command_exists node; then
        return 1
    fi

    local current_version
    local major_version
    current_version=$(node -v | sed 's/v//')
    major_version=$(echo "$current_version" | cut -d. -f1)

    if [ "$major_version" -ge 20 ]; then
        log_success "Node.js v$current_version is already installed (>= 20)"
        return 0
    fi

    log_warning "Node.js v$current_version is installed but version < 20"
    return 1
}

install_nodejs() {
    local platform
    platform=$(uname -s)

    case "$platform" in
        Linux|Darwin)
            if ! install_nvm; then
                log_error "Failed to install nvm"
                return 1
            fi

            export NVM_DIR="${HOME}/.nvm"
            [ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"

            install_nodejs_with_nvm
            ;;
        MINGW*|CYGWIN*|MSYS*)
            log_warning "Windows platform detected. Please install Node.js manually."
            log_info "Visit: https://nodejs.org/en/download/"
            return 1
            ;;
        *)
            log_error "Unsupported platform: $platform"
            return 1
            ;;
    esac
}

check_and_install_nodejs() {
    if check_node_version; then
        log_info "Using existing Node.js installation"
        clean_npmrc_conflict
    else
        log_warning "Installing or upgrading Node.js..."
        install_nodejs
    fi
}

install_homebrew_macos() {
    if command_exists brew; then
        log_success "Homebrew 已安装"
        return 0
    fi

    log_info "Installing Homebrew on macOS..."
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    log_success "Homebrew 安装完成"
}

install_bun() {
    if command_exists bun; then
        log_success "Bun 已安装：$(bun --version 2>/dev/null || echo 'unknown')"
        return 0
    fi

    log_info "Installing Bun..."
    curl -fsSL https://bun.sh/install | bash
    log_success "Bun 安装完成"
}

install_miniconda_macos() {
    if command_exists conda; then
        log_success "Miniconda / Conda 已安装：$(conda --version 2>/dev/null || echo 'unknown')"
        return 0
    fi

    if ! command_exists brew; then
        log_warning "未检测到 Homebrew，跳过 Miniconda 安装"
        return 1
    fi

    log_info "Installing Miniconda via Homebrew..."
    brew install --cask miniconda
    log_success "Miniconda 安装完成"
}

install_miniconda_linux() {
    if command_exists conda; then
        log_success "Miniconda / Conda 已安装：$(conda --version 2>/dev/null || echo 'unknown')"
        return 0
    fi

    local installer="/tmp/miniconda.sh"
    log_info "Installing Miniconda..."
    curl -fsSL https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh -o "$installer"
    bash "$installer" -b -p "$HOME/miniconda3"

    local profile_file
    profile_file=$(get_shell_profile)
    if ! grep -q 'miniconda3/bin' "${profile_file}" 2>/dev/null; then
        echo 'export PATH="$HOME/miniconda3/bin:$PATH"' >> "${profile_file}"
    fi
    export PATH="$HOME/miniconda3/bin:$PATH"
    log_success "Miniconda 安装完成"
}

app_exists_macos() {
    local app_name="$1"
    [ -d "/Applications/${app_name}.app" ] || [ -d "$HOME/Applications/${app_name}.app" ]
}

ghostty_installed_linux() {
    command_exists ghostty || [ -f "/usr/share/applications/com.mitchellh.ghostty.desktop" ] || [ -f "$HOME/.local/share/applications/com.mitchellh.ghostty.desktop" ]
}

clash_verge_installed_linux() {
    command_exists clash-verge || [ -f "/usr/share/applications/clash-verge.desktop" ] || [ -f "$HOME/.local/share/applications/clash-verge.desktop" ]
}

install_ghostty_macos() {
    if app_exists_macos "Ghostty"; then
        log_success "Ghostty 已安装"
        return 0
    fi

    if ! command_exists brew; then
        log_warning "未检测到 Homebrew，跳过 Ghostty 安装"
        return 1
    fi

    log_info "Installing Ghostty..."
    brew install --cask ghostty
    log_success "Ghostty 安装完成"
}

install_ghostty_linux() {
    if ghostty_installed_linux; then
        log_success "Ghostty 已安装"
        return 0
    fi

    if command_exists pacman; then
        log_info "Installing Ghostty via pacman..."
        sudo pacman -S --noconfirm ghostty
        log_success "Ghostty 安装完成"
        return 0
    fi

    if command_exists dnf; then
        log_info "Installing Ghostty via Fedora COPR..."
        sudo dnf copr enable -y scottames/ghostty
        sudo dnf install -y ghostty
        log_success "Ghostty 安装完成"
        return 0
    fi

    if command_exists apt-get; then
        log_info "Installing Ghostty via Ubuntu community installer..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/mkasberg/ghostty-ubuntu/HEAD/install.sh)"
        log_success "Ghostty 安装完成"
        return 0
    fi

    if command_exists snap; then
        log_info "Installing Ghostty via snap..."
        sudo snap install ghostty --classic
        log_success "Ghostty 安装完成"
        return 0
    fi

    log_warning "当前 Linux 发行版没有可自动执行的 Ghostty 安装路径。"
    return 1
}

install_clash_verge_macos() {
    if app_exists_macos "Clash Verge"; then
        log_success "Clash Verge 已安装"
        return 0
    fi

    if ! command_exists brew; then
        log_warning "未检测到 Homebrew，跳过 Clash Verge 安装"
        return 1
    fi

    log_info "Installing Clash Verge..."
    brew install --cask clash-verge-rev
    log_success "Clash Verge 安装完成"
}

find_clash_verge_windows_exe() {
    local candidates=(
        "${LOCALAPPDATA:-}/Programs/Clash Verge/Clash Verge.exe"
        "${LOCALAPPDATA:-}/Programs/Clash Verge Rev/Clash Verge.exe"
        "/c/Program Files/Clash Verge/Clash Verge.exe"
        "/c/Program Files/Clash Verge Rev/Clash Verge.exe"
        "/c/Program Files (x86)/Clash Verge/Clash Verge.exe"
        "/c/Program Files (x86)/Clash Verge Rev/Clash Verge.exe"
    )

    for path in "${candidates[@]}"; do
        if [ -n "$path" ] && [ -f "$path" ]; then
            printf '%s\n' "$path"
            return 0
        fi
    done

    return 1
}

install_clash_verge_windows() {
    local existing_path
    existing_path="$(find_clash_verge_windows_exe || true)"

    if [ -n "$existing_path" ]; then
        log_success "Clash Verge 已安装：$existing_path"
        return 0
    fi

    if command_exists winget; then
        log_info "Installing Clash Verge via winget..."
        winget install --id ClashVergeRev.ClashVergeRev -e --source winget
        log_success "Clash Verge 安装命令已执行"
        return 0
    fi

    log_warning "未检测到 winget，无法自动安装 Clash Verge。"
    log_info "请手动下载安装：https://github.com/clash-verge-rev/clash-verge-rev/releases"
    return 1
}

detect_clash_verge_tag() {
    curl -fsSL https://api.github.com/repos/clash-verge-rev/clash-verge-rev/releases/latest \
        | sed -n 's/.*"tag_name": *"\([^"]*\)".*/\1/p' \
        | head -n 1
}

install_clash_verge_linux() {
    if clash_verge_installed_linux; then
        log_success "Clash Verge 已安装"
        return 0
    fi

    local tag_name
    tag_name="$(detect_clash_verge_tag)"
    if [ -z "$tag_name" ]; then
        log_warning "无法获取 Clash Verge 最新版本信息"
        return 1
    fi

    local version="${tag_name#v}"
    local arch
    arch="$(uname -m)"
    local tmp_dir
    tmp_dir="$(mktemp -d)"

    if command_exists apt-get; then
        local deb_arch
        case "$arch" in
            x86_64) deb_arch="amd64" ;;
            aarch64|arm64) deb_arch="arm64" ;;
            armv7l|armhf) deb_arch="armhf" ;;
            *)
                log_warning "Clash Verge 暂不支持当前 Linux 架构：$arch"
                rm -rf "$tmp_dir"
                return 1
                ;;
        esac

        local deb_file="Clash.Verge_${version}_${deb_arch}.deb"
        local deb_path="${tmp_dir}/${deb_file}"
        log_info "Installing Clash Verge via deb package..."
        curl -fsSL "https://github.com/clash-verge-rev/clash-verge-rev/releases/download/${tag_name}/${deb_file}" -o "${deb_path}"
        sudo apt install -y "${deb_path}"
        rm -rf "$tmp_dir"
        log_success "Clash Verge 安装完成"
        return 0
    fi

    if command_exists dnf || command_exists yum; then
        local rpm_arch
        case "$arch" in
            x86_64) rpm_arch="x86_64" ;;
            aarch64|arm64) rpm_arch="aarch64" ;;
            armv7l|armhf) rpm_arch="armhfp" ;;
            *)
                log_warning "Clash Verge 暂不支持当前 Linux 架构：$arch"
                rm -rf "$tmp_dir"
                return 1
                ;;
        esac

        local rpm_file="Clash.Verge-${version}-1.${rpm_arch}.rpm"
        local rpm_path="${tmp_dir}/${rpm_file}"
        log_info "Installing Clash Verge via rpm package..."
        curl -fsSL "https://github.com/clash-verge-rev/clash-verge-rev/releases/download/${tag_name}/${rpm_file}" -o "${rpm_path}"

        if command_exists dnf; then
            sudo dnf install -y "${rpm_path}"
        else
            sudo yum localinstall -y "${rpm_path}"
        fi

        rm -rf "$tmp_dir"
        log_success "Clash Verge 安装完成"
        return 0
    fi

    if command_exists yay; then
        log_info "Installing Clash Verge via yay..."
        yay -S --noconfirm clash-verge-rev-bin
        rm -rf "$tmp_dir"
        log_success "Clash Verge 安装完成"
        return 0
    fi

    rm -rf "$tmp_dir"
    log_warning "当前 Linux 发行版没有可自动执行的 Clash Verge 安装路径。"
    return 1
}

main() {
    local platform
    platform=$(uname -s)

    echo "=========================================="
    echo "   Desktop Starter Installation Script"
    echo "=========================================="
    echo ""

    log_info "System: $(uname -s) $(uname -r)"
    log_info "Shell: $(basename "${SHELL:-bash}")"

    install_uv || log_warning "UV installation failed, continuing..."

    case "$platform" in
        Darwin)
            install_homebrew_macos || log_warning "Homebrew installation failed"
            check_and_install_nodejs || log_warning "Node.js installation failed"
            install_bun || log_warning "Bun installation failed"
            install_miniconda_macos || log_warning "Miniconda installation failed"
            install_ghostty_macos || log_warning "Ghostty installation failed"
            install_clash_verge_macos || log_warning "Clash Verge installation failed"
            ;;
        Linux)
            check_and_install_nodejs || log_warning "Node.js installation failed"
            install_bun || log_warning "Bun installation failed"
            install_miniconda_linux || log_warning "Miniconda installation failed"
            install_ghostty_linux || log_warning "Ghostty installation failed"
            install_clash_verge_linux || log_warning "Clash Verge installation failed"
            ;;
        MINGW*|CYGWIN*|MSYS*)
            check_and_install_nodejs || true
            install_bun || log_warning "Bun installation failed"
            if command_exists conda; then
                log_success "Miniconda / Conda 已安装：$(conda --version 2>/dev/null || echo 'unknown')"
            else
                log_warning "Windows 下未检测到 Miniconda / Conda。"
                log_info "请先安装 Miniconda: https://docs.conda.io/en/latest/miniconda.html"
            fi
            install_clash_verge_windows || true
            log_info "Windows 下忽略 Homebrew、nvm 和 Ghostty。"
            ;;
        *)
            log_error "Unsupported platform: $platform"
            exit 1
            ;;
    esac

    echo
    log_success "前置环境安装流程已完成。"
    log_info "请关闭终端后重新打开，再回到应用中点击“刷新”重新检测。"
    echo
    read -r -p "按回车关闭窗口..."
}

main
