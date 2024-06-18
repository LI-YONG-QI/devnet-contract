# 1. Create and export a .env file with the following content:
export $(cat .env | xargs)


forge create \
--rpc-url $ETH_RPC_URL \
--etherscan-api-key $ETHERSCAN_API_KEY \
--verifier-url $VERIFY_URL \
--private-key $PK \
--priority-gas-price 1 \
--verify \
src/PlanFactory.sol:PlanFactory \
