"""Make Provider and Contract class available on the command line."""
import click

from blockchain.contract import Contract
from blockchain.provider import Provider


@click.command()
@click.option("--address")
def balance(address, chain, fork) -> None:
    """Get native chain asset balance at address."""
    provider = Provider(chain=chain, fork=fork)
    balance = provider.w3.eth.get_balance(
        account=provider.w3.to_checksum_address(address)
    )
    click.echo(f"Native asset balance of {address}: {balance}")


@click.command()
@click.option("--token", "-t", help="ERC20 token address")
@click.option("--address", "-a", help="Address to get balance for")
def balance_of(token: str, address: str, chain: str, fork: bool) -> None:
    """Get ERC20 token balance of address."""
    contract = Contract(address=token, chain=chain, fork=fork)
    balance = contract.functions.balanceOf(
        contract.w3.to_checksum_address(address)
    ).call()
    click.echo(f"ERC20 {token} balance of address {address}: {balance}")


@click.command()
@click.option("--sender", help="Address to transfer from")
@click.option("--to", help="Address to deposit funds to")
@click.option("--amount", help="Amount to transfer in ether", type=int)
def transfer(sender: str, to: str, amount: int, chain: str, fork: bool):
    provider = Provider(chain=chain, fork=fork)
    provider.transfer(sender=sender, to=to, amount=amount)


@click.group()
@click.option("--chain", help="Chain of address: main, goerli, ...", default="main")
@click.option("--fork", help="Whether to use a fork or not", default=True)
def cli():
    """Utility commands."""
    pass


cli.add_command(balance)
cli.add_command(balance_of)
cli.add_command(transfer)

if __name__ == "__main__":
    cli()
