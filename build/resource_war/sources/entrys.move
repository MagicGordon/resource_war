module resource_war::entrys {
    use std::string::String;
    use resource_war::resource;
    use resource_war::resource_pool;

    public entry fun init(owner: &signer) {
        resource::init(owner);
        resource_pool::init(owner);
    }

    public entry fun create_miner(owner: &signer) {
        resource_pool::create_miner(owner);
    }

    public entry fun claim_reward(user: &signer, miner_name: String) {
        resource_pool::claim_reward(user, miner_name);
    }
}