# MultiSig Wallet ✍🏼✍🏽✍🏿

A simple implementation of a multi-signature wallet built in Solidity and cooked in some 🌶️ [foundry](https://github.com/foundry-rs/foundry) sauce.

Think of a multi-signature wallet as a supercharged safe or a high-tech joint bank account. Instead of just one key, multiple keys are needed to open it. It's all about sharing the responsibility, like many friends each having a piece of a secret code. More keys mean more security. And hey, if my description made zero sense 🤷‍♂️, check out [this awesome article](https://blog.thirdweb.com/multisig-wallet/) to get the full scoop.

What can you do with it? (for now)

- 🫸 submitting a new transaction (to be reviewed and approved by the wallet owners)
- 👍 approving the submitted transaction (and waiting for other owners to approve)
- 🙅‍♀️ revoking an approval vote on a transaction (if you changed your mind)
- ⚙️ executing the transaction (once the approval quorum has been reached)

The main purpose of this repository is to provide some examples of what concerns:

- Solidity best practices and [style guide](https://docs.soliditylang.org/en/v0.8.17/style-guide.html)
- Foundry test cases (faithful with UncleBob's approach - [3 laws of TDD](http://butunclebob.com/ArticleS.UncleBob.TheThreeRulesOfTdd) - evergreen article)
- Foundry script instructions
- Foundry quick deploy&run
- Foundry contract interactions

You will get to know the entire foundry suite and feel like you're the boss of your crypto! (I mean, imagine that? 😄)

## Requirements

- [**solc**](https://github.com/ethereum/solidity/) - solidity compiler
- [**solc-select**](https://github.com/crytic/solc-select) - manages installing and setting different solc compiler versions **(recommended)**
- foundry (see below 👇)

_Make sure your solidity compiler matches with the minimum specific version or version range defined in the contracts._

### KYF (Know your foundry 🛠️)

> **Foundry is a blazing fast, portable and modular toolkit for Ethereum application development written in Rust.**
>
> Foundry consists of:
>
> - **Forge**: Ethereum testing framework (like Truffle, Hardhat and DappTools).
> - **Cast**: Swiss army knife for interacting with EVM smart contracts, sending transactions and getting chain data.
> - **Anvil**: Local Ethereum node, akin to Ganache, Hardhat Network.
> - **Chisel**: Fast, utilitarian, and verbose solidity REPL.

### Install foundry suite

Download and install `foundryup`:

```shell
curl -L https://foundry.paradigm.xyz | bash
```

Run it to install the full suite:

```shell
foundryup
```

If you are running into errors, just check out the book right here --> [🖐️📕](https://book.getfoundry.sh/getting-started/installation)

## Getting started

### Setup

Setting up the environment variables:

```shell
cp .env.example .env
source .env
```

The default values contained in this file will work just fine, but you are free to make any change you like (e.g. modifying the addresses, changing the number of owners, etc.), keeping into account a few things: see comments in the `.env.example` file.

### Building (aka compiling)

To build the contracts simply run:

```shell
forge build
```

By default, this will compile all the contracts contained in the `lib`, `script`, `src`, `test` directories and store the artifacts ABIs in the `out` folder.

If you prefer to build only the files contained in a specific folder (e.g. the `src`), you can simply run it with the `-C <PATH>` flag:

```shell
forge build -C src
```

### Testing

Easy as:

```shell
forge test
```

This will compile and run all files within the `test` folder. To test a specific contract use the flag `--match-path` as follows:

```shell
forge test --match-path test/<CONTRACT>
```

You can set different levels of verbosity simply by adding thooooousands `v`s as trailing parameters, like that:

```shell
forge test -vvvv
```

### Deploying

From now on, I would recommend opening a side tab in the terminal as we will need to execute a local client - **anvil** - which is the cool-runner and younger brother of ganache and hardhat-node's family.

So, let's run it in one tab:

```shell
anvil
```

**and keep it open!**

In the second tab (we will refer to this as the _mess-things-up-tab_) run:

```shell
forge script script/MultiSigWallet.s.sol:MultiSigWalletScript --rpc-url ${LOCAL_RPC_URL} --private-key ${PRIVATE_KEY} --broadcast
```

If our deployment is successful, we will see something similar to this:

```shell
✅  [Success]Hash: 0xb8a1fe732721d8896cbd12fad87c3657e62831ab9e86f570595732a57ebe7c40
Contract Address: 0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0
Block: 1
Paid: 0.003781237914220259 ETH (1000253 gas * 3.780281503 gwei)
==========================
ONCHAIN EXECUTION COMPLETE & SUCCESSFUL.
Total Paid: 0.003781237914220259 ETH (1000253 gas * avg 3.780281503 gwei)
```

Grab the contract address and let's store it in an environment variable as we will need it later:

```shell
export CONTRACT="0x9fE46736679d2D9a65F0992F2272dE9f3c7fa6e0"
```

### Doing (actual) stuff

And now, the so-long-awaited fun 😄 - let's make some contract calls, shall we?

In the _mess-things-up-tab_, we will start with a simple query:

```shell
cast call ${CONTRACT} "owners(uint256)(address)" 0
```

If things go as planned, you will see the address of the first owner (if not...guess it is bug hunting time! 🐛🔍)

#### GMing wealth 💸

Alright, now that we have gotten our feet wet, let's dive deep and see this multisig in action!

##### The plot

A trio of crypto enthusiasts, united under a DAO, to gather people to invest in their project, have crafted a series of intricate Solidity puzzles. They presented these challenges on their Discord platform with a very generous offer: the first user to decode all the puzzles within 24 hours would be rewarded with 1 ETH. A week later, they proudly announced the lucky winner, and they are ready to transfer the bounty from their multisig account.

0 . 💰 **fund**

As `OWNER1`, funds the contract with `5 ether`:

```shell
cast send --private-key ${OWNERS_PK[1]} ${CONTRACT} --value 5ether
```

I recommend prefixing the command body with the `--private-key` flag, so that we know right away who is executing what (like the subject/persona of a story).

Verify the contract is now funded:

```shell
cast balance ${CONTRACT}
```

1 . 🫸 **submit**

Submit (only propose) the transaction which will send:

- `1 ether`
- to `RECIPIENT`
- setting expiration time to `86400` seconds (24 hours)
  - Execute this command to assign this value to an environment variable: `EXPIRATION=$(($(cast block latest -f timestamp) + 86400))`
- with message `gm` (hexed)
  - you can use `cast from-utf8 <text>` command

```shell
cast send --private-key ${OWNERS_PK[1]} ${CONTRACT} "submit(address,uint256,uint256,bytes)" ${RECIPIENT} 1ether ${EXPIRATION} 0x676d
```

Note that we are using `cast send` to sign and publish a transaction (this will alter the world state).

Let's check our transaction was correctly inserted:

```shell
cast call ${CONTRACT} "transactions(uint256)(address,uint256,uint256,bytes,bool)" 0
```

2 . 👍 **approve**

As the default threshold policy is set to the `uint(numberOfOwners/2 + 1)` (ceiling), for `3` owners we will require `uint(3/2 + 1) = 2` approvals (\*spoiler: nevertheless, as any well-respected story, there will be a twist, get ready 🍿):

`OWNER1` approves:

```shell
cast send --private-key ${OWNERS_PK[1]} ${CONTRACT} "approve(uint256)" 0
```

Let's verify:

```shell
cast call ${CONTRACT} "approved(uint256,address)(bool)" 0 ${OWNER1}
```

Let's move ahead approving the transaction also with `OWNER2`:

```shell
cast send --private-key ${OWNERS_PK[2]} ${CONTRACT} "approve(uint256)" 0
```

And let's verify it was approved:

```shell
cast call ${CONTRACT} "approved(uint256,address)(bool)" 0 ${OWNER2}
```

Alright, we hit our mark and were about to seal the deal, but...hold up! What's going on here? 😳

3 . 🙅‍♀️ **revoke**

Out of nowhere, `OWNER2` gets cold feet. Instead of moving forward, they pull the plug and take back their okay (seriously, not cool 😡):

```shell
cast send --private-key ${OWNERS_PK[2]} ${CONTRACT} "revoke(uint256)" 0
```

Quick check to see the damage:

```shell
cast call ${CONTRACT} "approved(uint256,address)(bool)" 0 ${OWNER2}
```

And yup, it is as bad as we thought. Our lucky 🐰 might not get their prize, and people might just lose faith in the DAO project: a total disaster 😭.

And, when we think everything is lost...a masked hero 🦸🏿 comes to the rescue...it's `OWNER3`! (what a plot twist! 🙄):

```shell
cast send --private-key ${OWNERS_PK[3]} ${CONTRACT} "approve(uint256)" 0
```

```shell
cast call ${CONTRACT} "approved(uint256,address)(bool)" 0 ${OWNER3}
```

4 . ⚙️ **execute**

`OWNER1` can finally execute the transaction.

But before jumping there, let's check first the initial balance of the recipient:

```shell
cast balance ${RECIPIENT}
```

and now let's execute:

```shell
cast send --private-key ${OWNERS_PK[1]} ${CONTRACT} "execute(uint256)" 0
```

And there it is:

```shell
cast call ${CONTRACT} "transactions(uint256)(address,uint256,uint256,bytes,bool)" 0
```

And our lucky 🐰 can count their money 🤑:

```shell
cast balance ${RECIPIENT}
```

Happy ever after ✨

dadadadaaann --- **THE END** (closing credits...)

## Other useful commands

### Formatting

If you are unhappy with your "prettifier" or just tangled in indentation hell, look no further, foundry has a nice 🎁 for you:

```shell
forge fmt
```

### Gas freak?

If you are working on gas optimization and want to check the before-after effect of your hopefully-well-rewarded work, try these out:

```shell
# slower but more comprehensive
forge test --gas-report
# faster and stored in a file
forge snapshot
```

More on [gas tracking](https://book.getfoundry.sh/forge/gas-tracking).

## Making changes

The user is encouraged to _mess-things-up_ (not just on a tab), break everything apart and make it work again - the best way of learning! (a wise 🐨 said).

## Known issues

- foundry (v0.2.0, at the time of writing) does not fully support solidity custom errors (yet), either in [testing](https://github.com/foundry-rs/foundry/issues/5941) or [logging error messages](https://github.com/foundry-rs/foundry/issues/3093)

## Continue learning

- an example of [account abstraction multisig](https://era.zksync.io/docs/dev/tutorials/custom-aa-tutorial.html) (by zksync team)
- [awesome-foundry](https://github.com/crisgarner/awesome-foundry) - a collection of projects built on/around and resources about foundry
