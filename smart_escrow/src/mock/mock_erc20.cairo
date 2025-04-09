#[starknet::contract]
pub mod mock_ERC20 {
    // ***************************************************************************************
    //                            IMPORT
    // ***************************************************************************************
    use core::num::traits::Zero;
    use core::starknet::storage::{
        Map, StorageMapReadAccess, StorageMapWriteAccess, StoragePathEntry,
    };
    use core::starknet::syscalls::deploy_syscall;
    use core::starknet::{
        ClassHash, ContractAddress, contract_address_const, get_block_timestamp, get_caller_address,
        get_contract_address,
    };
    use smart_escrow::interfaces::IERC20;

    #[storage]
    pub struct Storage {
        name: ByteArray,
        symbol: ByteArray,
        decimal: u8,
        total_supply: u256,
        owner: ContractAddress,
        allowance: Map<
            (ContractAddress, ContractAddress), u256,
        >, // map => [(owner, spender), amount]
        balances: Map<ContractAddress, u256>,
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    pub enum Event {
        Transfer: Transfer,
        Approval: Approval,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Transfer {
        #[key]
        from: ContractAddress,
        #[key]
        to: ContractAddress,
        amount: u256,
    }

    #[derive(Drop, starknet::Event)]
    pub struct Approval {
        #[key]
        owner: ContractAddress,
        #[key]
        spender: ContractAddress,
        value: u256,
    }

    #[constructor]
    fn constructor(ref self: ContractState) {
        self.name.write('Mock Token');
        self.symbol.write('MOK');
        self.owner(get_caller_address());
        self.decimals.write(18)
    }

    #[abi(embed_v0)]
    impl ERC20Impl of IERC20<ContractState> {
        fn transfer(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            let caller = get_caller_address();
            let caller_provious_balance = self.balances.read(caller);
            let recipient_prev_balance = self.balances.read(recipient);

            assert(caller_provious_balance <= amount, 'Insufficient amount');
            let caller_new_balance = caller_provious_balance - amount;

            self.balances.write(caller, caller_new_balance);

            let recipient_new_balance = recipient_prev_balance + amount;
            slef.balances.write(recipient, recipient_new_balance);

            // emint event
            self.emit(Transfer { from: sender, to: recipient, amount });

            true
        }

        fn transfer_from(
            ref self: ContractState,
            sender: ContractAddress,
            recipient: ContractAddress,
            amount: u256,
        ) -> bool {
            let spender = get_caller_address(); // caller as the spender 

            let spender_allowance = self.allowances.read((sender, spender));

            let sender_balance = self.balances.read(sender);
            let recipient_balance = self.balances.read(recipient);

            assert(amount <= spender_allowance, 'amount exceeds allowance');
            assert(amount <= sender_balance, 'amount exceeds balance');

            let new_spender_allowance = spender_allowance - amount;
            self.allowances.write((sender, spender), new_spender_allowance);

            let new_sender_balance = sender_balance - amount;
            self.balances.write(sender, new_sender_balance);

            let new_recipient_balance = recipient_balance + amount;
            self.balances.write(recipient, new_recipient_balance);

            self.emit(Transfer { from: sender, to: recipient, amount });

            true
        }
        fn approve(ref self: ContractState, spender: ContractAddress, amount: u256) -> bool {
            let caller = get_caller_address();
            //set allowance
            self.allowances((caller, spender), amount);
            self.emit(Approval { owner: caller, spender, value: amount });
            true
        }

        fn mint(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            let prev_total_supply = self.total_supply.read();
            let prev_recipient_balance = self.balances.read(recipient);

            // update total supply
            let new_total_supply = prev_total_supply + amount;
            self.total_supply.write(new_total_supply);

            // update recipient balance
            let new_recipient_balance = prev_recipient_balance + amount;
            self.balances.write(recipient, new_recipient_balance);

            let zero_address = Zero::zero();

            self.emit(Transfer { from: zero_address, to: recipient, amount });

            true
        }

        fn burn(ref self: ContractState, recipient: ContractAddress, amount: u256) -> bool {
            let prev_total_supply = self.total_supply.read();
            let prev_recipient_balance = self.balances.read(recipient);

            // update total supply
            let new_total_supply = prev_total_supply - amount;
            self.total_supply.write(new_total_supply);

            // update recipient balance
            let new_recipient_balance = prev_recipient_balance - amount;
            self.balances.write(recipient, new_recipient_balance);

            let zero_address = Zero::zero();

            self.emit(Transfer { from: zero_address, to: recipient, amount });

            true
        }

        // Getter Functions
        fn name(self: @ContractState) -> ByteArray {
            self.name.read()
        }

        fn symbol(self: @ContractState) -> ByteArray {
            self.symbol.read()
        }

        fn decimals(self: @ContractState) -> u8 {
            self.decimal.read()
        }

        fn total_supply(self: @ContractState) -> u256 {
            self.total_supply.read()
        }

        fn balance_of(self: @ContractState, account: ContractAddress) -> u256 {
            let balance = self.balances.read(account);

            balance
        }

        fn allowance(
            self: @ContractState, owner: ContractAddress, spender: ContractAddress,
        ) -> u256 {
            let allowance = self.allowances.read((owner, spender));

            allowance
        }
    }
}
