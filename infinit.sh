#!/bin/bash

function show {
  echo -e "\e[1;34m$1\e[0m"
}

export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    show "Memuat NVM..."
    echo
    source "$NVM_DIR/nvm.sh"
else
    show "NVM tidak ditemukan, menginstal NVM..."
    echo
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
    source "$NVM_DIR/nvm.sh"
fi

echo
show "Menginstal Node.js..."
echo
nvm install 22 && nvm alias default 22 && nvm use default
echo

show "Menginstal Foundry..."
echo
curl -L https://foundry.paradigm.xyz | bash
export PATH="$HOME/.foundry/bin:$PATH"
sleep 5
source ~/.bashrc
foundryup

show "Menginstal Bun..."
echo
curl -fsSL https://bun.sh/install | bash
export PATH="$HOME/.bun/bin:$PATH"
sleep 5
source ~/.bashrc
echo
# Memperbarui repositori dan menginstal unzip
echo "Memperbarui repositori dan menginstal unzip..."
apt-get update
apt-get install -y unzip
show "Menyetel proyek Bun..."
echo
mkdir AirdropNode && cd AirdropNode
bun init -y
bun add @infinit-xyz/cli
echo

show "Menginisialisasi Infinit CLI dan menghasilkan akun..."
echo
bunx infinit init
bunx infinit account generate
echo

read -p "Apa alamat dompet Anda (Masukkan alamat dari langkah di atas) : " WALLET
echo
read -p "Apa ID akun Anda (yang dimasukkan di langkah di atas) : " ACCOUNT_ID
echo

show "Salin kunci pribadi ini dan simpan di tempat yang aman, ini adalah kunci pribadi dari dompet ini"
echo
bunx infinit account export $ACCOUNT_ID

sleep 5
echo
# Menghapus skrip deployAaveV3Action yang lama jika ada
rm -rf src/scripts/deployAaveV3Action.script.ts

cat <<EOF > src/scripts/deployAaveV3Action.script.ts
import { DeployAaveV3Action, type actions } from '@infinit-xyz/aave-v3/actions'
import type { z } from 'zod'

type Param = z.infer<typeof actions['init']['paramsSchema']>

// Parameter aktual untuk Aave V3
const params: Param = {
  // Label mata uang asli (misalnya, ETH)
  "nativeCurrencyLabel": 'ETH',

  // Alamat pemilik proxy admin
  "proxyAdminOwner": '$WALLET',

  // Alamat pemilik pool
  "poolOwner": '$WALLET',

  // Alamat token asli yang dibungkus (misalnya, WETH)
  "wrappedNativeToken": '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2',

  // Alamat penyedia alamat pool pinjaman
  "lendingPoolAddressesProvider": '0x24a5e9B95a225Bef7B2F73A0f88D006B51D5B3DA',

  // Alamat pengendali insentif
  "incentivesController": '0xD7cC11D6cA6790B5aFF771A9d7C66B8B16e05F08',

  // Alamat token utang stabil
  "stableDebtToken": '0xB59A94A8C1BAdD6EA8A12D9A2B2D3E7D11cA67C2',

  // Alamat token utang variabel
  "variableDebtToken": '0xD4F5BA10D5E4a6B3C5D906e68fFCFA61A56337EA'
}

// Konfigurasi signer
const signer = {
  "deployer": "$ACCOUNT_ID"
}

export default { params, signer, Action: DeployAaveV3Action }
EOF

show "Menjalankan skrip Aave V3 Action..."
echo
bunx infinit script execute deployAaveV3Action.script.ts
