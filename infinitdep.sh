#!/bin/bash

# Update & Instalasi dependensi yang diperlukan (opsional)
sudo apt-get update -y
sudo apt-get install -y curl

# Instalasi Bun
curl -fsSL https://bun.sh/install | bash
source /root/.bashrc  # Memuat ulang bashrc setelah instalasi Bun

# Instalasi Foundry
curl -L https://foundry.paradigm.xyz | bash
source /root/.bashrc  # Memuat ulang bashrc setelah instalasi Foundry

# Instalasi NVM (Node Version Manager)
curl https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.0/install.sh | bash
source /root/.bashrc  # Memuat ulang bashrc setelah instalasi NVM

# Mengatur NVM_DIR dan memuat NVM
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # Memuat nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # Memuat nvm bash_completion

# Instalasi Node.js versi 22 dan set sebagai default
nvm install 22
nvm alias default 22
nvm use default
source /root/.bashrc  # Memuat ulang bashrc setelah menggunakan NVM

curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash

sleep 3

# Membuat folder proyek baru
mkdir AirdropNode
cd AirdropNode

# Inisialisasi proyek Node.js baru menggunakan Bun
bun init -y
source /root/.bashrc  # Memuat ulang bashrc setelah inisialisasi proyek

# Instalasi paket @infinit-xyz/aave-v3
bun add @infinit-xyz/aave-v3
source /root/.bashrc  # Memuat ulang bashrc setelah instalasi paket

echo
echo "Inisialisasi Infinit CLI dan membuat akun..."
echo
bunx infinit init
bunx infinit account generate
echo

read -p "Apa alamat dompet Anda (Masukkan alamat dari langkah sebelumnya): " WALLET
echo
read -p "Apa ID akun Anda (dimasukkan pada langkah sebelumnya): " ACCOUNT_ID
echo

echo "Salin kunci pribadi ini dan simpan di tempat yang aman, ini adalah kunci pribadi dompet ini"
echo
bunx infinit account export "$ACCOUNT_ID"

sleep 5
echo
# Menghapus skrip deployAaveV3Action lama jika ada
rm -rf src/scripts/deployAaveV3Action.script.ts

# Membuat skrip baru untuk deployAaveV3Action
cat <<EOF > src/scripts/deployAaveV3Action.script.ts
import { DeployAaveV3Action, type actions } from '@infinit-xyz/aave-v3/actions'
import type { z } from 'zod'

type Param = z.infer<typeof actions['init']['paramsSchema']>

// TODO: Ganti dengan parameter sebenarnya
const params: Param = {
  // Label mata uang asli (misalnya, ETH)
  "nativeCurrencyLabel": 'ETH',

  // Alamat pemilik proxy admin
  "proxyAdminOwner": '$WALLET',

  // Alamat pemilik pabrik
  "factoryOwner": '$WALLET',

  // Alamat token asli yang dibungkus (misalnya, WETH)
  "wrappedNativeToken": '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'
}

// Konfigurasi penandatangan
const signer = {
  "deployer": "$ACCOUNT_ID"
}

export default { params, signer, Action: DeployAaveV3Action }
EOF

echo "Menjalankan skrip AaveV3 Action..."
echo
bunx infinit script execute deployAaveV3Action.script.ts
