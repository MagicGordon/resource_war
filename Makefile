PRO_NAME=resource_war

build: compile

compile: 
	aptos move compile --named-addresses ${PRO_NAME}=default

publish:
	aptos move publish --named-addresses ${PRO_NAME}=default --override-size-check

init:
	aptos move run --function-id 'default::entrys::init'

ra:
	aptos move test --filter resource_account_address  --named-addresses ${PRO_NAME}=default
