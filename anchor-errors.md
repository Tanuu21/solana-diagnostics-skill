# Anchor Errors

Complete reference for Anchor framework constraint and runtime errors.

---

## ConstraintSeeds (Error 2006)

**What it means:** The PDA provided does not match the PDA derived from the seeds declared in `#[account(seeds = [...], bump)]`.

**Common causes:**
1. Seeds in client-side derivation don't match seeds in the program (most common)
2. Wrong bump used — not using the canonical bump
3. Extra or missing seed in the array
4. Seed byte encoding mismatch (e.g. string vs `b"string"`)
5. Wrong program ID used in `findProgramAddressSync`

**Fix:**

```rust
// Program side — seeds must match exactly
#[account(
    seeds = [b"vault", user.key().as_ref()],
    bump,
)]
pub vault: Account<'info, Vault>,
```

```typescript
// Client side — must match program exactly
const [vault] = PublicKey.findProgramAddressSync(
  [Buffer.from("vault"), user.publicKey.toBuffer()],
  program.programId
);
```

**Beginner explanation:** The program expected a special address built from specific ingredients (seeds), but the address you provided was built with different ingredients. Like using the wrong combination on a combination lock.

---

## ConstraintOwner (Error 2004)

**What it means:** The account's owner does not match the expected program ID.

**Common causes:**
1. Account owned by System Program instead of your program
2. Account not yet initialized
3. Wrong program ID in constraint
4. Using a token account where a program account is expected

**Fix:**

```rust
// Ensure account is owned by your program
#[account(
    constraint = my_account.owner == program_id @ MyError::WrongOwner
)]
pub my_account: AccountInfo<'info>,
```

Or use typed accounts which enforce ownership automatically:

```rust
// Typed account automatically checks owner = program_id
pub my_account: Account<'info, MyStruct>,
```

---

## ConstraintSigner (Error 2002)

**What it means:** The account was required to be a signer but its `is_signer` flag is false.

**Common causes:**
1. Caller not included in the signers array on the client
2. PDA used where a user signature is expected
3. Wrong account passed as the signer
4. CPI context missing the signer

**Fix:**

```typescript
// Client: ensure signer is in signers array
await program.methods
  .myInstruction()
  .accounts({ authority: wallet.publicKey })
  .signers([wallet]) // must be here
  .rpc();
```

```rust
// Program: use Signer type
pub authority: Signer<'info>,
```

---

## ConstraintMut (Error 2000)

**What it means:** The account was required to be writable (`mut`) but was passed as read-only.

**Common causes:**
1. Account not marked writable in the client transaction
2. Using `AccountInfo` without `#[account(mut)]`
3. Passing a read-only account to a writable constraint

**Fix:**

```typescript
// Client: mark account as writable
const tx = await program.methods
  .myInstruction()
  .accounts({
    myAccount: myAccountPubkey, // Anchor handles mut automatically from IDL
  })
  .rpc();
```

```rust
// Program: declare mutability
#[account(mut)]
pub my_account: Account<'info, MyData>,
```

---

## ConstraintAddress (Error 2012)

**What it means:** The account's public key does not match the expected hard-coded address.

**Fix:**

```rust
#[account(
    address = EXPECTED_PUBKEY @ MyError::WrongAddress
)]
pub config: Account<'info, Config>,
```

---

## AccountNotInitialized (Error 3012)

**What it means:** The account discriminator is missing or zeroed — the account exists but has never been written by your program's `init` instruction.

**Common causes:**
1. Calling an instruction before `initialize`
2. Account created but `init` instruction never ran
3. Wrong account passed (an unrelated account)

**Fix:**

```rust
// Ensure init runs first
#[account(
    init,
    payer = user,
    space = 8 + MyData::INIT_SPACE,
)]
pub my_data: Account<'info, MyData>,
```

Always call `initialize` before any instruction that reads program state.

---

## InvalidAccountData (Error 3003)

**What it means:** The account data cannot be deserialized into the expected struct. The discriminator is wrong or data is malformed.

**Common causes:**
1. Passing account from a different program
2. Account was created with a different version of the struct
3. Account data was manually corrupted
4. Wrong account type passed

**Fix:** Verify the account address and ensure it was created by the correct instruction with the correct struct definition.

---

## MissingRequiredSignature

**What it means:** A signature required to authorize the transaction is absent.

**Common causes:**
1. Multisig — not enough signers
2. PDA signer not included via `invoke_signed`
3. Fee payer not signing

**Fix:**

```typescript
// Add all required signers
await program.methods.myIx().accounts({...}).signers([signer1, signer2]).rpc();
```

---

## IncorrectProgramId

**What it means:** The program ID in the instruction does not match the deployed program.

**Common causes:**
1. Stale IDL — program was redeployed with a new ID
2. Wrong network (devnet vs mainnet ID)
3. Hardcoded program ID in client doesn't match deployment

**Fix:** Re-run `anchor build && anchor deploy`, update your IDL and program ID in the client.

---

## AccountOwnedByWrongProgram (Error 3007)

**What it means:** An account you're trying to use is owned by a different program than expected.

**Fix:**

```rust
// Be explicit about expected owner
constraint = token_account.owner == token::ID @ MyError::WrongTokenProgram
```

---

## Error Code Quick Reference

| Code | Name | Meaning |
|------|------|---------|
| 2000 | ConstraintMut | Account must be writable |
| 2001 | ConstraintHasOne | has_one field mismatch |
| 2002 | ConstraintSigner | Account must be signer |
| 2003 | ConstraintRaw | Raw constraint failed |
| 2004 | ConstraintOwner | Wrong owner program |
| 2006 | ConstraintSeeds | PDA seeds mismatch |
| 2007 | ConstraintExecutable | Must be executable program |
| 2009 | ConstraintAssociated | Associated token account mismatch |
| 2012 | ConstraintAddress | Address mismatch |
| 3003 | InvalidAccountData | Cannot deserialize account |
| 3007 | AccountOwnedByWrongProgram | Wrong owning program |
| 3012 | AccountNotInitialized | Account not initialized |
| 6000+ | Custom errors | Program-defined errors |
