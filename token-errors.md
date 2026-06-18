# Token Errors

SPL Token program errors, mint authority issues, ATA failures, and Token-2022.

---

## Common SPL Token Errors

### InsufficientFunds (Error 1)

**Symptom:** Transfer fails with "insufficient funds"

```rust
// Check balance before transfer
require!(
    source_account.amount >= transfer_amount,
    TokenError::InsufficientFunds
);
```

### InvalidMint (Error 2)

**Symptom:** Token account mint doesn't match expected mint

```rust
// Anchor constraint — verify mint
#[account(
    constraint = token_account.mint == expected_mint.key() @ MyError::WrongMint
)]
pub token_account: Account<'info, TokenAccount>,
```

### OwnerMismatch (Error 4)

**Symptom:** Token account authority doesn't match signer

Token accounts have an `owner` field (the wallet that controls them) — distinct from the SPL account owner (always the token program).

```rust
// Check token account authority
#[account(
    constraint = token_account.owner == authority.key() @ MyError::WrongAuthority
)]
pub token_account: Account<'info, TokenAccount>,
```

### UninitializedState (Error 5)

**Symptom:** Operating on a token account that hasn't been initialized

Always initialize the ATA before using it:

```typescript
import { getOrCreateAssociatedTokenAccount } from "@solana/spl-token";

const ata = await getOrCreateAssociatedTokenAccount(
  connection,
  payer,
  mintAddress,
  ownerAddress
);
```

---

## Associated Token Account (ATA) Errors

### ATA Derivation

```typescript
import { getAssociatedTokenAddressSync } from "@solana/spl-token";

const ata = getAssociatedTokenAddressSync(
  mintAddress,      // mint pubkey
  ownerAddress,     // owner wallet
  false,            // allowOwnerOffCurve — true if owner is PDA
  TOKEN_PROGRAM_ID  // use TOKEN_2022_PROGRAM_ID for Token-2022
);
```

### PDA Owning an ATA

When the ATA owner is a PDA, you must set `allowOwnerOffCurve = true`:

```typescript
const pdaAta = getAssociatedTokenAddressSync(
  mintAddress,
  pdaAddress,
  true, // allowOwnerOffCurve — required for PDA owners
);
```

On-chain initialization:

```rust
#[account(
    init_if_needed,
    payer = payer,
    associated_token::mint = mint,
    associated_token::authority = vault, // vault is a PDA
)]
pub vault_ata: Account<'info, TokenAccount>,
```

---

## Mint Authority Errors

### Unauthorized Mint

```rust
// Verify caller is the mint authority
#[account(
    constraint = mint.mint_authority == COption::Some(authority.key()) @ MyError::NotMintAuthority
)]
pub mint: Account<'info, Mint>,
```

### Transferring Mint Authority

```rust
// Transfer mint authority to a PDA (for program-controlled minting)
let cpi_ctx = CpiContext::new(
    ctx.accounts.token_program.to_account_info(),
    SetAuthority {
        account_or_mint: ctx.accounts.mint.to_account_info(),
        current_authority: ctx.accounts.current_authority.to_account_info(),
    },
);
token::set_authority(
    cpi_ctx,
    AuthorityType::MintTokens,
    Some(new_authority),
)?;
```

### Revoking Freeze Authority

```rust
token::set_authority(
    cpi_ctx,
    AuthorityType::FreezeAccount,
    None, // None = permanently revoke
)?;
```

---

## Token-2022 (Token Extensions)

Token-2022 uses a different program ID. Mixing them causes `IncorrectProgramId`.

```rust
use anchor_spl::token_interface::{Mint, TokenAccount, TokenInterface};

// Use TokenInterface instead of specific token program
pub token_program: Interface<'info, TokenInterface>,
pub mint: InterfaceAccount<'info, Mint>,
pub token_account: InterfaceAccount<'info, TokenAccount>,
```

```typescript
import { TOKEN_2022_PROGRAM_ID, TOKEN_PROGRAM_ID } from "@solana/spl-token";

// Check which program the mint uses
const mintInfo = await connection.getAccountInfo(mintAddress);
const programId = mintInfo.owner.equals(TOKEN_2022_PROGRAM_ID)
  ? TOKEN_2022_PROGRAM_ID
  : TOKEN_PROGRAM_ID;
```

---

## Freeze Authority

```rust
// Frozen accounts cannot be transferred from
// Check before transfer if freeze authority exists
require!(
    !token_account.is_frozen(),
    MyError::AccountFrozen
);
```

---

## Token Diagnostic Checklist

- [ ] Using correct token program (SPL vs Token-2022)?
- [ ] ATA initialized before use?
- [ ] `allowOwnerOffCurve = true` if ATA owner is PDA?
- [ ] Mint authority set correctly?
- [ ] Token account owner (authority) matches signer?
- [ ] Sufficient balance before transfer?
- [ ] Account not frozen?
- [ ] Correct mint on both source and destination ATAs?
