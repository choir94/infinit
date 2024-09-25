#!/bin/bash
function show {
  echo -e "\e[1;34m$1\e[0m"
}

# Memastikan skrip dijalankan dengan hak akses sudo
if [[ $EUID -ne 0 ]]; then
   echo "Silakan jalankan skrip ini dengan sudo." 
   exit 1
fi

# Memperbarui repositori dan menginstal unzip
echo "Memperbarui repositori dan menginstal unzip..."
apt-get update
apt-get install -y unzip

# Menginstal Bun
echo "Menginstal Bun..."
curl -fsSL https://bun.sh/install | bash

# Menambahkan Bun ke PATH
echo "Menambahkan Bun ke PATH..."
echo 'export PATH="$HOME/.bun/bin:$PATH"' >> ~/.bashrc
source ~/.bashrc

# Memeriksa instalasi
echo "Memeriksa instalasi Bun..."
if command -v bun &> /dev/null; then
    echo "Bun berhasil diinstal: $(bun --version)"
else
    echo "Gagal menginstal Bun."
fi

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
curl -s https://raw.githubusercontent.com/choir94/Airdropguide/refs/heads/main/logo.sh | bash

sleep 3
echo "done"
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
