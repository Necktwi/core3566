BLINK='\033[5m'
YELLOW='\033[1;33m'
HBLUE='\e[1;94m'
BGBLACK='\e[40m'
NC='\033[0m'
function echoH () {
	echo -e "\n${YELLOW}$1${NC}"
}
function echoHB () {
	echo -e "\n${BLINK}${BGBLACK}${HBLUE}$1${NC}"
}
TGTTPL=aarch64-gentoo-linux-musl
set -euo pipefail
set -x
