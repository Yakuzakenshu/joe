# Ensure joe is installed first.

KEY="joe1"
CHAINID="joe-t1"
MONIKER="localjoe"
KEYALGO="secp256k1"
KEYRING="test" # export joe_KEYRING="TEST"
LOGLjoeL="info"
TRACE="" # "--trace"

joed config keyring-backend $KEYRING
joed config chain-id $CHAINID
joed config output "json"

command -v jq > /dev/null 2>&1 || { echo >&2 "jq not installed. More info: https://stedolan.github.io/jq/download/"; exit 1; }

from_scratch () {

  make install

  # remove existing daemon
  rm -rf ~/.joed/* 
  
  # joe1hj5fveer5cjtn4wd6wstzugjfdxzl0xp0cyvu4
  echo "decorate bright ozone fork gallery riot bus exhaust worth way bone indoor calm squirrel merry zero scheme cotton until shop any excess stage laundry" | joed keys add $KEY --keyring-backend $KEYRING --algo $KEYALGO --recover
  # Set moniker and chain-id for Craft
  joed init $MONIKER --chain-id $CHAINID 

  # Function updates the config based on a jq argument as a string
  update_test_genesis () {
    # update_test_genesis '.consensus_params["block"]["max_gas"]="100000000"'
    cat $HOME/.joed/config/genesis.json | jq "$1" > $HOME/.joed/config/tmp_genesis.json && mv $HOME/.joed/config/tmp_genesis.json $HOME/.joed/config/genesis.json
  }

  # Set gas limit in genesis
  update_test_genesis '.consensus_params["block"]["max_gas"]="100000000"'
  update_test_genesis '.app_state["gov"]["voting_params"]["voting_period"]="15s"'

  # Change chain options to use EXP as the staking denom for craft
  update_test_genesis '.app_state["staking"]["params"]["bond_denom"]="ujoe"'
  # update_test_genesis '.app_state["bank"]["params"]["send_enabled"]=[{"denom": "ujoe","enabled": false}]'
  update_test_genesis '.app_state["staking"]["params"]["min_commission_rate"]="0.100000000000000000"'    

  # update from token -> ucraft
  update_test_genesis '.app_state["mint"]["params"]["mint_denom"]="ujoe"'  
  update_test_genesis '.app_state["gov"]["deposit_params"]["min_deposit"]=[{"denom": "ujoe","amount": "100"}]' # 1 joe right now
  update_test_genesis '.app_state["crisis"]["constant_fee"]={"denom": "ujoe","amount": "1000"}'  

  # same as inqlusions
  update_test_genesis '.app_state["staking"]["params"]["exemption_factor"]="10.000000000000000000"'  

  update_test_genesis '.app_state["tokenfactory"]["params"]["denom_creation_fee"]=[{"denom": "ujoe","amount": "1000000"}]'  

  # Allocate genesis accounts
  # 10 joe (1 of which is used for validator)
  joed add-genesis-account $KEY 10000000ujoe --keyring-backend $KEYRING

  # create gentx with 1 joe
  joed gentx $KEY 1000000ujoe --keyring-backend $KEYRING --chain-id $CHAINID

  # Collect genesis tx
  joed collect-gentxs

  # Run this to ensure joerything worked and that the genesis file is setup correctly
  joed validate-genesis
}

# from_scratch

# Opens the RPC endpoint to outside connections
sed -i '/laddr = "tcp:\/\/127.0.0.1:26657"/c\laddr = "tcp:\/\/0.0.0.0:26657"' ~/.joed/config/config.toml
sed -i 's/cors_allowed_origins = \[\]/cors_allowed_origins = \["\*"\]/g' ~/.joed/config/config.toml
# cors_allowed_origins = []

# # Start the node (remove the --pruning=nothing flag if historical queries are not needed)
joed start --pruning=nothing  --minimum-gas-prices=0ujoe #--mode validator     