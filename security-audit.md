# Security Audit

Solana program security — vulnerability patterns, audit checklist, and hardening guide.

---

## Critical Vulnerability Classes

### 1. Missing Signer Check

**Risk:** Anyone can call privileged instructions.

```rust
// VULNERABLE — no signer check
pub fn admin_withdraw(ctx: Context<AdminWithdraw>, amount: u64) -> Result<()> {
    // Anyone can call this!
    transfer_lamports(&ctx.accounts.vault, &ctx.accounts.attacker, amount)
}

// SECURE
pub fn admin_withdraw(ctx: Context<AdminWithdraw>, amount: u64) -> Result<()> {
    require!(
        ctx.accounts.authority.key() == ctx.accounts.config.admin,
        MyError::Unauthorized
    );
    // ...
}

// BEST — use Anchor constraint
#[account(
    constraint = config.admin == authority.key() @ MyError::Unauthorized
)]
pub config: Account<'info, Config>,
pub authority: Signer<'info>,
```

### 2. Missing Ownership Check

**Risk:** Attacker passes a fake account with matching data layout.

```rust
// VULNERABLE — AccountInfo doesn't check owner
pub fake_account: AccountInfo<'info>,

// SECURE — typed Account checks discriminator + owner
pub real_account: Account<'info, MyStruct>,

// SECURE — explicit check if AccountInfo needed
require!(
    fake_account.owner == &program_id,
    MyError::WrongOwner
);
```

### 3. Arbitrary CPI

**Risk:** Attacker passes a malicious program ID for CPI.

```rust
// VULNERABLE
pub fn cpi_call(ctx: Context<CpiCall>) -> Result<()> {
    invoke(&Instruction {
        program_id: ctx.accounts.program.key(), // attacker controls this!
        ...
    }, ...)
}

// SECURE — hardcode or validate
require!(
    ctx.accounts.token_program.key() == spl_token::ID,
    MyError::InvalidTokenProgram
);
```

### 4. Integer Overflow / Underflow

**Risk:** Balance wraps around, allowing infinite minting or fund drain.

```rust
// VULNERABLE
account.balance += deposit_amount; // can overflow

// SECURE
account.balance = account.balance
    .checked_add(deposit_amount)
    .ok_or(MyError::Overflow)?;
```

### 5. PDA Substitution Attack

**Risk:** Attacker constructs a PDA with valid seeds pointing to an account they control.

```rust
// VULNERABLE — seeds don't include the owner
seeds = [b"vault"]

// SECURE — bind PDA to specific user/mint
seeds = [b"vault", user.key().as_ref(), mint.key().as_ref()]
```

### 6. Reentrancy via CPI

```rust
// VULNERABLE — reads balance after CPI (stale)
let balance_before = ctx.accounts.vault.amount;
token::transfer(cpi_ctx, amount)?;
ctx.accounts.vault.reload()?; // expensive and easy to forget

// SECURE — update state before CPI
ctx.accounts.position.withdrawn += amount;
token::transfer(cpi_ctx, amount)?;
```

### 7. Type Confusion

**Risk:** Two accounts with same layout but different types are interchangeable.

Anchor discriminators prevent this automatically. If using raw accounts:

```rust
// Add discriminator manually
pub fn discriminator() -> [u8; 8] {
    anchor_lang::solana_program::hash::hash(b"account:MyStruct").to_bytes()[..8]
        .try_into().unwrap()
}
```

### 8. Closing Accounts Incorrectly

**Risk:** Account closed but data remains — "zombie account" attack.

```rust
// VULNERABLE — just zeroing lamports
**ctx.accounts.account.try_borrow_mut_lamports()? = 0;

// SECURE — use Anchor's close constraint
#[account(
    mut,
    close = receiver // sends lamports to receiver AND zeroes data
)]
pub account_to_close: Account<'info, MyAccount>,
```

---

## Audit Checklist

### Access Control
- [ ] Every privileged instruction checks authority
- [ ] Admin key stored in program state, not hardcoded
- [ ] No instruction callable by arbitrary accounts

### Account Validation
- [ ] Ownership checked (use typed `Account<>` where possible)
- [ ] Discriminators verified
- [ ] No `AccountInfo` used where `Account<>` would work

### Math
- [ ] All arithmetic uses `checked_*` operations
- [ ] No division before multiplication (precision loss)
- [ ] Amounts validated against minimums/maximums

### CPI
- [ ] All CPI program IDs validated against constants
- [ ] PDA signer seeds include correct bump
- [ ] State updated before CPIs (not after)

### PDAs
- [ ] Seeds namespaced (include program-specific prefix)
- [ ] Seeds include all relevant discriminators (user, mint, etc.)
- [ ] Canonical bump stored and reused

### Token Operations
- [ ] Mint authority set correctly
- [ ] Freeze authority handled
- [ ] Token program validated (SPL vs Token-2022)
- [ ] ATA derivation correct for PDA owners

### Account Lifecycle
- [ ] Accounts properly initialized before use
- [ ] Account closing uses `close =` constraint
- [ ] No zombie accounts (data zeroed on close)

### Error Handling
- [ ] All `Result` values handled (no `let _ =`)
- [ ] Custom errors for all failure paths
- [ ] No `unwrap()` or `expect()` in production

---

## Security Hardening Priorities

**Critical (fix before devnet):**
1. Add signer checks to all privileged instructions
2. Replace `AccountInfo` with typed accounts
3. Fix all integer arithmetic to use `checked_*`

**High (fix before mainnet):**
4. Audit all CPI program IDs
5. Review PDA seed namespacing
6. Implement proper account closing

**Medium (best practice):**
7. Add invariant assertions
8. Fuzz test numeric inputs
9. Add monitoring/alerting

**Recommended tools:**
- `cargo audit` — dependency vulnerabilities
- `soteria` — automated Solana vulnerability scanner
- Trail of Bits `solana-lints` — custom lint rules
- Manual review of all privileged instructions
