# CPI Failures

Cross-Program Invocation — failure patterns, security issues, and fixes.

---

## CPI Basics

A CPI is when your program calls another program's instruction. Two variants:

- `invoke(instruction, accounts)` — no PDA signer
- `invoke_signed(instruction, accounts, signer_seeds)` — PDA signs

Anchor wraps these as `CpiContext::new()` and `CpiContext::new_with_signer()`.

---

## Most Common CPI Failures

### 1. Missing Account in CPI Context

**Symptom:** `Missing account` or instruction panics mid-execution

Every account the callee program touches must be passed in the CPI accounts list, even if your program doesn't use it directly.

```rust
// BAD — token_program missing
let cpi_accounts = Transfer {
    from: from.to_account_info(),
    to: to.to_account_info(),
    authority: authority.to_account_info(),
};
// GOOD — all required accounts included
let cpi_ctx = CpiContext::new(
    token_program.to_account_info(), // program account always needed
    cpi_accounts,
);
```

### 2. PDA Not Signing Correctly

**Symptom:** `MissingRequiredSignature` inside a CPI

```rust
// BAD — forgot bump in signer_seeds
let seeds = &[b"vault".as_ref(), user.key.as_ref()];

// GOOD — bump must be the last element
let seeds = &[b"vault".as_ref(), user.key.as_ref(), &[vault.bump]];
let signer_seeds = &[&seeds[..]];

let ctx = CpiContext::new_with_signer(
    token_program.to_account_info(),
    cpi_accounts,
    signer_seeds,
);
```

### 3. Writable Account Not Marked Mut in CPI

**Symptom:** `AccountBorrowFailed` or `ConstraintMut`

Any account that will be modified by the callee must be passed as mutable:

```rust
// Ensure account is mutable before CPI
let from_account = from.to_account_info(); // already mut if declared with #[account(mut)]
```

### 4. CPI Depth Exceeded

**Symptom:** `Call depth limit exceeded` or `Program failed to complete`

Solana limits CPI depth to **4 levels**. Your call chain:

```
User → Program A → Program B → Program C → Program D  ✓ (depth 4)
User → Program A → Program B → Program C → Program D → Program E  ✗ (depth 5)
```

Flatten your call chain or batch operations differently.

### 5. Account Already Borrowed

**Symptom:** `AccountBorrowFailed` panic

Occurs when the same account is used twice in a CPI — Rust's borrow checker allows it at compile time but Solana's runtime rejects it.

```rust
// BAD — same account used as both from and to
Transfer {
    from: user_account.to_account_info(),
    to: user_account.to_account_info(), // same account!
    authority: ...
}
```

---

## CPI Security Issues

### Signer Privilege Escalation

**Risk:** CPI passes the original caller's signer privileges down the call chain

Any program you CPI into receives the same signer set as your program. Only invoke programs you trust completely.

```rust
// Dangerous pattern — passing user signer to untrusted program
invoke(
    &untrusted_program_instruction,
    &[user.to_account_info()], // user signer passed along!
)
```

### Reentrancy

Solana's single-threaded execution prevents classic reentrancy, but logic reentrancy (calling back into your own program) can still cause state inconsistency.

**Fix:** Complete all state changes before issuing CPIs (checks-effects-interactions pattern).

```rust
// GOOD — update state first, then CPI
account.balance = account.balance.checked_sub(amount)?;
// Now do the CPI transfer
token::transfer(cpi_ctx, amount)?;
```

### Arbitrary CPI

**Risk:** Program accepts a program_id from user input and invokes it

```rust
// DANGEROUS — never do this
pub fn arbitrary_cpi(ctx: Context<ArbitraryCpi>, program_id: Pubkey) -> Result<()> {
    invoke(&Instruction::new_with_bytes(program_id, ...), ...)
}
```

Always hardcode or validate the program ID against a known constant.

---

## Token Program CPI Patterns

### Transfer

```rust
let cpi_accounts = Transfer {
    from: ctx.accounts.from_ata.to_account_info(),
    to: ctx.accounts.to_ata.to_account_info(),
    authority: ctx.accounts.authority.to_account_info(),
};
let cpi_ctx = CpiContext::new(ctx.accounts.token_program.to_account_info(), cpi_accounts);
token::transfer(cpi_ctx, amount)?;
```

### Transfer with PDA Authority

```rust
let seeds = &[b"vault".as_ref(), &[ctx.accounts.vault.bump]];
let signer = &[&seeds[..]];
let cpi_ctx = CpiContext::new_with_signer(
    ctx.accounts.token_program.to_account_info(),
    cpi_accounts,
    signer,
);
token::transfer(cpi_ctx, amount)?;
```

---

## CPI Diagnostic Checklist

- [ ] All accounts passed to CPI that the callee needs?
- [ ] PDA signer includes bump as last seed element?
- [ ] Mutable accounts marked `#[account(mut)]`?
- [ ] CPI depth ≤ 4?
- [ ] No same account used twice in one CPI?
- [ ] Program ID validated (not from user input)?
- [ ] State updated before CPI (not after)?
- [ ] Token program is spl-token, not arbitrary pubkey?
