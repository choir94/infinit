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

echo "done"
mkdir AirdropNode && cd AirdropNode
bun init -y
bun add @infinit-xyz/cli
bun add @infinit-xyz/aave-v3
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
 
type Param = z.infer<typeof actions['init']['paramSchema']>
 
// TODO: Replace with actual params
const params: Param = {
  // TODO: Native currency label (e.g., ETH)
  "nativeCurrencyLabel": 'ETH',
 
  // TODO: Address of the owner of the proxy admin
  "proxyAdminOwner": '0xE04A57dFC52B65C1ABaDc8D9F7b968Ea60685b3E',
 
  // TODO: Address of the owner of factory
  "factoryOwner": '0xE04A57dFC52B65C1ABaDc8D9F7b968Ea60685b3E',
 
  // TODO: Address of the wrapped native token (e.g., '0x123...abc')
  "wrappedNativeToken": '0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2'
}
 
// TODO: Replace with actual account id
const accounts = {
  "deployer": "test-acc"
}
 
export default { params, signer: accounts, Action: DeployAaveV3Action }
EOF

show "Menjalankan skrip Aave V3 Action..."
echo
bunx infinit script execute deployAaveV3Action.script.ts
