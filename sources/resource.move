module resource_war::resource {
    use std::error;
    use std::string;
    use std::signer;

    use aptos_framework::coin;
    use aptos_framework::coin::{MintCapability, BurnCapability};

    friend resource_war::entrys;
    friend resource_war::resource_pool;

    const ENOT_RESOURCE_WAR_ADDRESS: u64 = 1;

    struct Resource {}

    struct Cap has key {
        mint: MintCapability<Resource>,
        burn: BurnCapability<Resource>,
    }

    public(friend) fun init(owner: &signer) {
        assert!(signer::address_of(owner) == @resource_war, error::permission_denied(ENOT_RESOURCE_WAR_ADDRESS));

        let (b_cap, f_cap, m_cap) = coin::initialize<Resource>(
            owner,
            string::utf8(b"Resource War Token"),
            string::utf8(b"RW"),
            8,
            true
        );
        coin::destroy_freeze_cap(f_cap);

        move_to(owner, Cap {
            mint: m_cap,
            burn: b_cap
        });

        coin::register<Resource>(owner);
    }

    public(friend) fun mint_resource(to: address, amount: u64) acquires Cap {
        let cap = borrow_global<Cap>(@resource_war);
        let mint_resource = coin::mint(amount, &cap.mint);
        coin::deposit(to, mint_resource);
    }
}