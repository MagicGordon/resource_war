module resource_war::resource_pool {
    use std::error;
    use std::vector;
    use std::signer;
    use std::bcs;
    use std::string::{Self, String};

    use aptos_framework::timestamp;
    use aptos_framework::aptos_coin::AptosCoin;
    use aptos_framework::coin;
    use aptos_framework::table_with_length::{Self, TableWithLength};
    use aptos_framework::account::{Self, SignerCapability};

    use aptos_token::token;
    use aptos_token::property_map;

    use resource_war::resource::{mint_resource, Resource};

    friend resource_war::entrys;

    const ENOT_RESOURCE_WAR_ADDRESS: u64 = 1;

    const COLLECTION: vector<u8> = b"resource_war_collection";
    const LAST_CLAIM_TIMESTAMP: vector<u8> = b"LAST_CLAIM_TIMESTAMP";

    struct MinerManagerCap has key { 
        signer_cap: SignerCapability,
        next_miner_id: u64
    }

    struct MinerRecord has key {
        data: TableWithLength<String, address>
    }

    public(friend) fun init(owner: &signer) {
       assert!(signer::address_of(owner) == @resource_war, error::permission_denied(ENOT_RESOURCE_WAR_ADDRESS));

       let (miner_manager_account, signer_cap) =
           account::create_resource_account(owner, b"miner_manager");
       move_to(owner, MinerManagerCap { signer_cap, next_miner_id: 0 });
       move_to(owner, MinerRecord { data: table_with_length::new() });

       token::create_collection(
            &miner_manager_account,
            string::utf8(COLLECTION),
            string::utf8(b""),
            string::utf8(b""),
            18446744073709551615,
            vector<bool>[ false, false, false ]
        );
    }

    #[test_only]
    use aptos_std::debug::print;

    #[test(owner = @resource_war)]
    fun resource_account_address(owner: &signer) {
        let (lp_acc, _) =
            account::create_resource_account(owner, b"miner_manager");
        print(&lp_acc);
    }

    fun u64_to_string(value: u64): String {
        if (value == 0) {
            return string::utf8(b"0")
        };
        let buffer = vector::empty<u8>();
        while (value != 0) {
            vector::push_back(&mut buffer, ((48 + value % 10) as u8));
            value = value / 10;
        };
        vector::reverse(&mut buffer);
        string::utf8(buffer)
    }

    public(friend) fun create_miner(user: &signer) acquires MinerManagerCap, MinerRecord {
        let user_address = signer::address_of(user);

        let deposit_apt = coin::withdraw<AptosCoin>(user, 1000000);
        coin::deposit<AptosCoin>(@resource_war, deposit_apt);

        if (!coin::is_account_registered<Resource>(user_address)){
            coin::register<Resource>(user);
        };

        let miner_record = borrow_global_mut<MinerRecord>(@resource_war);
        let miner_manager_info = borrow_global_mut<MinerManagerCap>(@resource_war);
        let miner_manager_account = account::create_signer_with_capability(&miner_manager_info.signer_cap);

        let miner_name = u64_to_string(miner_manager_info.next_miner_id);

        table_with_length::add(&mut miner_record.data, miner_name, user_address);

        let token_data_id = token::create_tokendata(
            &miner_manager_account,
            string::utf8(COLLECTION),
            miner_name,
            string::utf8(b""),
            1,
            string::utf8(b"https://aptos.dev/img/nyan.jpeg"),
            @resource_war,
            0,
            0,
            token::create_token_mutability_config(
                &vector<bool>[ false, false, false, false, true ]
            ),
            vector<String>[],
            vector<vector<u8>>[],
            vector<String>[],
        );
        let token_id = token::mint_token(&miner_manager_account, token_data_id, 1);
        token::direct_transfer(&miner_manager_account, user, token_id, 1);
        token::mutate_one_token(
            &miner_manager_account,
            user_address,
            token_id,
            vector<String>[string::utf8(LAST_CLAIM_TIMESTAMP)],
            vector<vector<u8>>[bcs::to_bytes<u64>(&timestamp::now_seconds())],
            vector<String>[string::utf8(b"u64")],
        );

        miner_manager_info.next_miner_id = miner_manager_info.next_miner_id + 1;
    }

    public(friend) fun claim_reward(user: &signer, miner_name: String) acquires MinerManagerCap {
        let user_address = signer::address_of(user);

        let miner_manager_info = borrow_global_mut<MinerManagerCap>(@resource_war);
        let miner_manager_account = account::create_signer_with_capability(&miner_manager_info.signer_cap);

        let token_data_id = token::create_token_data_id(signer::address_of(&miner_manager_account), string::utf8(COLLECTION), miner_name);
        let token_id = token::create_token_id(token_data_id, 1);

        let property = token::get_property_map(user_address, token_id);
        let last_claim_timestamp = property_map::read_u64(&property, &string::utf8(LAST_CLAIM_TIMESTAMP));

        let now = timestamp::now_seconds();
        let reward = (now - last_claim_timestamp) / 10;

        mint_resource(user_address, reward);

        token::mutate_one_token(
            &miner_manager_account,
            user_address,
            token_id,
            vector<String>[string::utf8(LAST_CLAIM_TIMESTAMP)],
            vector<vector<u8>>[bcs::to_bytes<u64>(&(last_claim_timestamp + reward * 10))],
            vector<String>[string::utf8(b"u64")],
        );
    }
}