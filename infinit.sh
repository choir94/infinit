#!/bin/bash

function tampilkan {
  echo -e "\e[1;34m$1\e[0m"
}
export NVM_DIR="$HOME/.nvm"
if [ -s "$NVM_DIR/nvm.sh" ]; then
    tampilkan "Memuat NVM..."
    echo
    source "$NVM_DIR/nvm.sh"
else
    tampilkan "NVM tidak ditemukan, menginstal NVM..."
    echo
    curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.4/install.sh | bash
    source "$NVM_DIR/nvm.sh"
fi


echo
tampilkan "Menginstal Node.js..."
echo
nvm install 22 && nvm alias default 22 && nvm use default
echo

tampilkan "Menginstal Foundry..."
echo
curl -L https://foundry.paradigm.xyz | bash
export PATH="$HOME/.foundry/bin:$PATH"
sleep 5
source ~/.bashrc
foundryup


tampilkan "Menginstal Bun..."
echo
curl -fsSL https://bun.sh/install | bash
export PATH="$HOME/.bun/bin:$PATH"
sleep 5
source ~/.bashrc
echo

tampilkan "Menyiapkan proyek Bun..."
echo
mkdir AirdropNode && cd AirdropNode
bun init -y
bun add @infinit-xyz/aave-v3
echo

tampilkan "Inisialisasi Infinit CLI dan membuat akun..."
echo
bunx infinit init
bunx infinit account generate
echo

read -p "Apa alamat dompet Anda (Masukkan alamat dari langkah sebelumnya) : " WALLET
echo
read -p "Apa ID akun Anda (dimasukkan pada langkah sebelumnya) : " ACCOUNT_ID
echo

tampilkan "Salin kunci pribadi ini dan simpan di tempat yang aman, ini adalah kunci pribadi dompet ini"
echo
bunx infinit account export $ACCOUNT_ID

sleep 5
echo
# Menghapus skrip deployAaveV3Action lama jika ada
rm -rf src/scripts/deployAaveV3Action.script.ts

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

tampilkan "Menjalankan skrip AaveV3 Action..."
echo
bunx infinit script execute deployAaveV3Action.script.ts
