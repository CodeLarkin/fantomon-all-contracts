
set -e

if [[ -z "$1" || "$1" == "fantomon" ]]; then
    npx hardhat test test/FantomonArenaPVPv0.ts
    python3 utils/fantomonUrisFromMeta.py 'gen/pvp.json' 18 > gen/pvp.html
    brave-browser gen/pvp.html
fi
