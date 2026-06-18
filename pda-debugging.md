# PDA Debugging

Program Derived Addresses — derivation, bump, seeds, and common failure patterns.

---

## How PDAs Work

A PDA is a public key derived deterministically from:
- A list of seeds (byte arrays)
- A program ID
- A bump (0–255) to push it off the ed25519 curve

```
PDA = hash(seeds + program_id + bump) — not on curve
```

The **canonical bump** is the highest value (closest to 255) that produces a valid off-curve address. Always store and reuse this bump — never re-search for it at runtime.

---

## Seed Mismatch — Most Common PDA Failure

**Symptom:** `ConstraintSeeds` error (2006), or simulation returns "invalid account data"

**Diagnosis checklist:**

1. Do client seeds **exactly** match program seeds byte-for-byte?
2. Is the seed a string literal? → use `b"string"` in Rust, `Buffer.from("string")` in TS
3. Does the seed include a public key? → use `.as_ref()` in Rust, `.toBuffer()` in TS
4. Does the seed include a number (u8/u64)? → must use little-endian encoding
5. Is the program ID correct on both sides?

**Fix example:**

```rust
// Program — Rust
#[account(
    seeds = [
        b"position",           // string literal
        user.key().as_ref(),   // pubkey seed
        &position_id.to_le_bytes(), // u64 as little-endian bytes
    ],
    bump,
)]
pub position: Account<'info, Position>,
```

```typescript
// Client — TypeScript (must match exactly)
const positionId = new BN(1);
const [position] = PublicKey.findProgramAddressSync(
  [
    Buffer.from("position"),
    user.publicKey.toBuffer(),
    positionId.toArrayLike(Buffer, "le", 8), // u64 little-endian
  ],
  program.programId
);
```

---

## Wrong Bump Value

**Symptom:** PDA address derives but instruction fails or account not found

**Rule:** Always use the **canonical bump** stored in the account, never re-derive.

```rust
// BAD — re-deriving bump wastes compute and can mismatch
let (_, bump) = Pubkey::find_program_address(&[b"vault", user.as_ref()], program_id);

// GOOD — store canonical bump in account at init time
#[account(
    init,
    seeds = [b"vault", user.key().as_ref()],
    bump,
    payer = user,
    space = 8 + Vault::INIT_SPACE,
)]
pub vault: Account<'info, Vault>,

// Then in subsequent instructions, load stored bump:
#[account(
    seeds = [b"vault", user.key().as_ref()],
    bump = vault.bump, // use stored bump
)]
pub vault: Account<'info, Vault>,
```

---

## PDA as Signer (invoke_signed)

**Symptom:** `MissingRequiredSignature` when PDA should be signing a CPI

PDAs cannot hold a private key — they sign via `invoke_signed` with their seeds.

```rust
// Correct way to sign with a PDA
let seeds = &[
    b"vault".as_ref(),
    user.key.as_ref(),
    &[vault.bump],
];
let signer_seeds = &[&seeds[..]];

let cpi_ctx = CpiContext::new_with_signer(
    token_program.to_account_info(),
    Transfer {
        from: vault_token_account.to_account_info(),
        to: user_token_account.to_account_info(),
        authority: vault.to_account_info(),
    },
    signer_seeds,
);

token::transfer(cpi_ctx, amount)?;
```

---

## Multiple PDAs with Same Seeds

**Symptom:** Two accounts collide — same address derived for different purposes

Always namespace your seeds with a unique prefix:

```rust
// BAD — collision possible
seeds = [user.key().as_ref()]

// GOOD — namespaced
seeds = [b"user-vault", user.key().as_ref()]
seeds = [b"user-stake", user.key().as_ref()]
```

---

## PDA Diagnostic Flow

```
Error with PDA?
│
├── ConstraintSeeds (2006)?
│   ├── Check seeds match client ↔ program
│   ├── Check encoding (string/pubkey/number)
│   └── Check program ID
│
├── Account not found?
│   ├── Was init instruction called?
│   └── Is correct network (devnet/mainnet)?
│
├── MissingRequiredSignature on CPI?
│   ├── Using invoke_signed with correct seeds?
│   └── Bump correct in signer_seeds?
│
└── AccountNotInitialized?
    └── Call init instruction first
```

---

## Common Encoding Mistakes

| Seed type | Rust | TypeScript |
|-----------|------|------------|
| String literal | `b"vault"` | `Buffer.from("vault")` |
| Public key | `key.as_ref()` | `key.toBuffer()` |
| u8 | `&[value]` | `Buffer.from([value])` |
| u16 | `&value.to_le_bytes()` | `buf.writeUInt16LE(value)` |
| u32 | `&value.to_le_bytes()` | `buf.writeUInt32LE(value)` |
| u64 | `&value.to_le_bytes()` | `new BN(value).toArrayLike(Buffer, "le", 8)` |
| String (dynamic) | `name.as_bytes()` | `Buffer.from(name)` |
