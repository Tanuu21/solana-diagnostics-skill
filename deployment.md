# Deployment

Anchor build, deploy, upgrade failures, and deployment readiness checklist.

---

## Build Failures

### "type annotations needed"
→ Add explicit types to ambiguous Rust expressions.

### "cannot find type X in this scope"
→ Missing `use` import or feature flag.

```toml
# Cargo.toml — common missing features
[dependencies]
anchor-lang = { version = "0.30.1", features = ["init-if-needed"] }
anchor-spl = { version = "0.30.1", features = ["token", "associated_token"] }
```

### IDL generation fails
→ Check that all account structs implement `InitSpace` or manually specify `space`.

```rust
#[account]
#[derive(InitSpace)]
pub struct MyAccount {
    pub owner: Pubkey,       // 32
    pub amount: u64,         // 8
    #[max_len(50)]
    pub name: String,        // 4 + 50
}
```

### Stack size exceeded during build
→ Box large structs or move them to heap.

```rust
// Move large data off stack
let large = Box::new(LargeStruct::default());
```

---

## Deploy Failures

### "account data too small for instruction"
→ Program buffer account too small. Use `--max-len` flag.

```bash
anchor deploy --max-len 500000
```

### "Program's authority does not match"
→ Deploying with wrong keypair. Check your `Anchor.toml` wallet setting.

```toml
[provider]
cluster = "devnet"
wallet = "~/.config/solana/id.json" # must match original deployer
```

### "Insufficient funds"
→ Need more SOL for program account rent + deployment fees.

```bash
# Check balance
solana balance

# Airdrop on devnet
solana airdrop 2
```

### Program too large
→ Split into multiple programs or remove unused dependencies.

```bash
# Check binary size
ls -lh target/deploy/*.so

# Optimize for size
[profile.release]
opt-level = "z"
lto = true
codegen-units = 1
```

---

## Program Upgrade

### Upgrading with Anchor

```bash
# Build new version
anchor build

# Deploy upgrade
anchor upgrade target/deploy/my_program.so --program-id YOUR_PROGRAM_ID

# Or with program authority
solana program deploy target/deploy/my_program.so \
  --program-id YOUR_PROGRAM_ID \
  --upgrade-authority YOUR_KEYPAIR.json
```

### Account Migration After Upgrade

If you change account struct layout, you need a migration instruction:

```rust
pub fn migrate_v1_to_v2(ctx: Context<MigrateV2>) -> Result<()> {
    let old = &ctx.accounts.old_account;
    let new = &mut ctx.accounts.new_account;
    
    // Copy fields, set new defaults
    new.owner = old.owner;
    new.amount = old.amount;
    new.version = 2;
    new.new_field = 0; // default for new field
    
    Ok(())
}
```

### Freezing Upgrades (Immutable Programs)

```bash
# Make program non-upgradeable (cannot be undone)
solana program set-upgrade-authority YOUR_PROGRAM_ID \
  --final
```

Only do this after thorough audit.

---

## Deployment Readiness Checklist

### Code Quality
- [ ] All `unwrap()` replaced with `?` or `require!`
- [ ] Checked arithmetic everywhere (no overflow risk)
- [ ] No `todo!()` or `panic!()` in production paths
- [ ] Custom error types with descriptive messages

### Security
- [ ] All signer checks in place
- [ ] Ownership validated on all accounts
- [ ] No arbitrary CPI
- [ ] PDA seeds namespaced (no collisions)
- [ ] Freeze authority revoked if not needed
- [ ] Mint authority locked if supply is fixed
- [ ] Reentrancy-safe (state updated before CPI)

### Testing
- [ ] Unit tests for all instructions
- [ ] Integration tests cover happy path and error cases
- [ ] Fuzz testing on numeric inputs
- [ ] Localnet test passing
- [ ] Devnet deployment verified

### Operations
- [ ] Program ID documented and consistent
- [ ] IDL published (for explorers and indexers)
- [ ] Upgrade authority on multisig (not single key)
- [ ] Monitoring set up (Helius webhooks, etc.)
- [ ] Emergency pause mechanism (if applicable)

---

## Anchor.toml Configuration

```toml
[features]
seeds = true
skip-lint = false

[programs.localnet]
my_program = "YOUR_PROGRAM_ID"

[programs.devnet]
my_program = "YOUR_PROGRAM_ID"

[registry]
url = "https://api.apr.dev"

[provider]
cluster = "devnet"
wallet = "~/.config/solana/id.json"

[scripts]
test = "yarn run ts-mocha -p ./tsconfig.json -t 1000000 tests/**/*.ts"
```
