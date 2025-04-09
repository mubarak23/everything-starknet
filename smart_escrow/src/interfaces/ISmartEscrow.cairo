#[starknet::interface]
pub trait ISmartEscrow<TContractState> {
    fn transact(ref self: TContractState, token: ContractAddress, amount: u256, fee: u256);
    fn refund_user(ref self: TContractState, transaction_id: u256);
    fn verify_transaction(ref self: TContractState, transaction_id: u256);
    fn withdraw(ref self: TContractState, token: ContractAddress);
    fn change_admin(ref self: TContractState, new_admin: ContractAddress);
    fn get_all_transaction(self: @TContractState) -> Array<Escrow::Transaction>;
}
