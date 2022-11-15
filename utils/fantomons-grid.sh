set -e

if [[ -z "$1" || "$1" == "fantomon" ]]; then
    npx hardhat test test/FantomonManyMint.ts
    python3 utils/fantomonUrisFromMeta.py 'gen/fantomonURIs.json' > gen/fantomonURIs.html
    brave-browser gen/fantomonURIs.html
fi

if [[ -z "$1" || "$1" == "morph" ]]; then
    npx hardhat test test/Fantomon.ts
    python3 utils/fantomonUrisFromMeta.py 'gen/fantomonMorphURIs.json' 8 > gen/fantomonMorphURIs.html
    brave-browser gen/fantomonMorphURIs.html
fi
