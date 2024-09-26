#!/bin/bash

# Jalur penyimpanan script
SCRIPT_PATH="$HOME/infinit.sh"

# Tampilkan Logo
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash
sleep 3

# Perbarui sistem dan instal unzip
sudo apt update
sudo apt install -y unzip

# Fungsi menu utama
function main_menu() {
    while true; do
        clear
        
        echo "================================================================"
        echo "Airdrop Node Telegram Channel: https://t.me/airdrop_node"
        echo "Untuk keluar dari script, tekan ctrl+c pada keyboard"
        echo "Pilih tindakan yang ingin dilakukan:"
        echo "1) Deploy Kontrak"
        echo "2) Keluar"

        read -p "Masukkan pilihan: " choice

        case $choice in
            1)
                deploy_contract
                ;;
            2)
                echo "Keluar dari script..."
                exit 0
                ;;
            *)
                echo "Pilihan tidak valid, silakan coba lagi"
                ;;
        esac
        read -n 1 -s -r -p "Tekan enter tombol untuk melanjutkan..."
    done
}

# Periksa dan instal perintah
function check_install() {
    command -v "$1" &> /dev/null
    if [ $? -ne 0 ]; then
        echo "$1 belum diinstal, menginstal..."
        eval "$2"
    else
        echo "$1 sudah diinstal"
    fi
}

# Deploy kontrak
function deploy_contract() {
    export NVM_DIR="$HOME/.nvm"
    
    if [ -s "$NVM_DIR/nvm.sh" ]; then
        source "$NVM_DIR/nvm.sh"
    else
        curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
        source "$NVM_DIR/nvm.sh"
    fi

    # Periksa dan instal Node.js
    if ! command -v node &> /dev/null; then
        nvm install 22
        nvm alias default 22
        nvm use default
    fi
    
    echo "Menginstal Foundry..."
    curl -L https://foundry.paradigm.xyz | bash
    export PATH="$HOME/.foundry/bin:$PATH"
    sleep 5
    source ~/.bashrc
    foundryup
    
    # Periksa dan instal Bun
    if ! command -v bun &> /dev/null; then
        curl -fsSL https://bun.sh/install | bash
        export PATH="$HOME/.bun/bin:$PATH"
        sleep 5
        source "$HOME/.bashrc"
    fi

    # Periksa apakah Bun ada
    if ! command -v bun &> /dev/null; then
        echo "Bun belum diinstal, instalasi mungkin gagal, periksa langkah instalasi"
        exit 1
    fi

    # Setup proyek Bun
    mkdir -p infinit && cd infinit || exit
    bun init -y
    bun add @infinit-xyz/cli

    echo "Menginisialisasi Infinit CLI dan menghasilkan akun..."
    bunx infinit init
    bunx infinit account generate
    echo

    read -p "Apa alamat dompet Anda (masukkan alamat dari langkah di atas): " WALLET
    echo
    read -p "Apa ID akun Anda (masukkan dari langkah di atas): " ACCOUNT_ID
    echo

    echo "Salin private key ini dan simpan di suatu tempat, ini adalah private key dompet Anda"
    bunx infinit account export $ACCOUNT_ID

    sleep 5
    echo

    # Hapus skrip deployUniswapV3Action lama jika ada
    rm -rf src/scripts/deployUniswapV3Action.script.ts

cat <<EOF > src/scripts/deployUniswapV3Action.script.ts
import { DeployUniswapV3Action, type actions } from '@infinit-xyz/uniswap-v3/actions'
import type { z } from 'zod'

type Param = z.infer<typeof actions['init']['paramsSchema']>

// TODO: Ganti dengan parameter yang sesuai
const params: Param = {
  // Label mata uang asli (misalnya, ETH)
  "nativeCurrencyLabel": 'ETH',

  // Alamat pemilik proxy admin
  "proxyAdminOwner": '$WALLET',

  // Alamat pemilik factory
  "factoryOwner": '$WALLET',

  // Alamat token native yang dibungkus (misalnya, WETH)
  "wrappedNativeToken": '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'
}

// Konfigurasi signer
const signer = {
  "deployer": "$ACCOUNT_ID"
}

export default { params, signer, Action: DeployUniswapV3Action }
EOF

show "Menjalankan skrip UniswapV3 Action..."
echo
bunx infinit script execute deployUniswapV3Action.script.ts
