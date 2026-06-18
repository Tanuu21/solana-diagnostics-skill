# Compute Budget

Compute unit management, optimization, and budget failure patterns.

---

## Compute Unit Basics

Every Solana transaction has a **compute budget** — a cap on CPU cycles your program can consume.

| Limit | Value |
|-------|-------|
| Default CU per instruction | 200,000 |
| Max CU per transaction | 1,400,000 |
| Max instructions per transaction | 64 |

**"Program failed to complete"** or **"exceeded CU meter"** = you hit the limit.

---

## Setting Compute Budget

Always request the CUs you actually need. Over-requesting wastes fees; under-requesting fails transactions.

```typescript
import { ComputeBudgetProgram, TransactionMessage, VersionedTransaction } from "@solana/web3.js";

const modifyComputeUnits = ComputeBudgetProgram.setComputeUnitLimit({
  units: 400_000, // request what you need
});

const addPriorityFee = ComputeBudgetProgram.setComputeUnitPrice({
  microLamports: 50_000, // priority fee to get included faster
});

const message = new TransactionMessage({
  payerKey: payer.publicKey,
  recentBlockhash: blockhash,
  instructions: [modifyComputeUnits, addPriorityFee, ...yourInstructions],
}).compileToV0Message();
```

On the program side (Anchor):

```rust
use anchor_lang::solana_program::compute_budget::ComputeBudgetInstruction;

// Request additional compute in instruction (rarely needed — set on client)
```

---

## Measuring Actual CU Usage

**Simulate first, then set limit:**

```typescript
// Simulate to get actual CU consumption
const simulation = await connection.simulateTransaction(transaction, {
  sigVerify: false,
  replaceRecentBlockhash: true,
});

const unitsUsed = simulation.value.unitsConsumed;
console.log(`Estimated CUs: ${unitsUsed}`);

// Set limit with 10-20% buffer
const safeLimit = Math.ceil(unitsUsed * 1.2);
```

---

## Common High-CU Operations

| Operation | Typical CU cost |
|-----------|----------------|
| Simple transfer | ~150 |
| SPL token transfer | ~4,000 |
| Initialize account | ~5,000 |
| Anchor account init | ~8,000–15,000 |
| `msg!()` log per char | ~100 per character |
| `require!()` check | ~100–300 |
| Secp256k1 verify | ~200,000 |
| Large account iteration | 1,000+ per element |

---

## Optimization Techniques

### 1. Remove Unnecessary Logs

```rust
// BAD — expensive in production
msg!("Processing user: {}", user.key());
msg!("Amount: {}", amount);
msg!("Balance before: {}", account.balance);

// GOOD — log only in debug builds or remove entirely
#[cfg(feature = "debug")]
msg!("Processing user: {}", user.key());
```

### 2. Use Zero-Copy Accounts for Large Data

```rust
// For accounts > 10KB, use zero-copy to avoid deserialization cost
#[account(zero_copy)]
pub struct LargeData {
    pub data: [u64; 1000],
}

// Access via AccountLoader, not Account<>
pub large_data: AccountLoader<'info, LargeData>,
```

### 3. Avoid Iteration Where Possible

```rust
// BAD — O(n) on-chain iteration
for item in &account.items {
    total += item.value;
}

// GOOD — maintain running total, update on write
account.total += new_item.value;
```

### 4. Use Checked Math Only Where Needed

```rust
// checked_add costs ~3x more than wrapping_add
// Use checked for user inputs, wrapping for internal math you control
let safe_input = user_amount.checked_add(fee).ok_or(MyError::Overflow)?;
let internal = internal_a.wrapping_add(internal_b); // known safe
```

### 5. Minimize Account Clones

```rust
// BAD — clones account data
let info = account.to_account_info().clone();

// GOOD — use reference
let info = account.to_account_info();
```

---

## Priority Fees

Priority fees (microlamports per CU) increase the chance of transaction inclusion during congestion.

```typescript
// Dynamic priority fee — get current median from RPC
const recentFees = await connection.getRecentPrioritizationFees();
const medianFee = recentFees
  .map(f => f.prioritizationFee)
  .sort((a, b) => a - b)[Math.floor(recentFees.length / 2)];

const priorityFee = ComputeBudgetProgram.setComputeUnitPrice({
  microLamports: Math.max(medianFee * 1.5, 1000), // 50% above median, min 1000
});
```

---

## Diagnostic: "Program failed to complete"

```
Program failed to complete?
│
├── Check simulation for unitsConsumed
├── Is it > 200,000? → Need to request more CUs
├── Is it > 1,400,000? → Must optimize or split instruction
│
├── What's consuming the most?
│   ├── Remove msg!() logs
│   ├── Remove debug assertions
│   ├── Simplify loops
│   └── Move computation off-chain
│
└── Still too high after optimization?
    └── Split into multiple transactions with separate instructions
```
