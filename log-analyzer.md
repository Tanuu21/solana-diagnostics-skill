# Log Analyzer

Reading, parsing, and diagnosing Solana transaction logs and simulation output.

---

## Log Structure

A Solana transaction log looks like this:

```
Program 11111111111111111111111111111111 invoke [1]
Program log: Instruction: Initialize
Program 11111111111111111111111111111111 success
Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA invoke [1]
Program log: Instruction: Transfer
Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA consumed 4736 of 200000 compute units
Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA success
Program AbcDef...YourProgram invoke [1]
Program log: AnchorError caused by account: vault. Error Code: ConstraintSeeds. Error Number: 2006. Error Message: A seeds constraint was violated.
Program AbcDef...YourProgram failed: custom program error: 0x7d6
```

---

## Reading the Failure Line

The failure is almost always the **last non-success program log line**.

```
Program XYZ failed: custom program error: 0x7d6
```

Convert hex error code to decimal: `0x7d6 = 2006 = ConstraintSeeds`

Common hex → error mapping:

| Hex | Decimal | Error |
|-----|---------|-------|
| 0x7d0 | 2000 | ConstraintMut |
| 0x7d2 | 2002 | ConstraintSigner |
| 0x7d4 | 2004 | ConstraintOwner |
| 0x7d6 | 2006 | ConstraintSeeds |
| 0xbbb | 3003 | InvalidAccountData |
| 0xbbf | 3007 | AccountOwnedByWrongProgram |
| 0xbbc | 3012 | AccountNotInitialized |
| 0x1 | 1 | InsufficientFunds (token) |
| 0x4 | 4 | OwnerMismatch (token) |

Custom program errors start at 6000+ (0x1770+).

---

## CPI Depth in Logs

The `[1]`, `[2]`, `[3]` numbers show CPI depth:

```
Program A invoke [1]          ← top-level call
  Program B invoke [2]        ← A called B
    Program C invoke [3]      ← B called C
      Program C failed        ← failure is here
    Program B failed          ← propagated up
  Program A failed            ← propagated up
```

The **innermost failure** is the true root cause.

---

## Simulation vs On-Chain Logs

**Simulation** (preflight): Catches most errors before spending fees. Always simulate first.

```typescript
const simulation = await connection.simulateTransaction(tx, {
  sigVerify: false,
  replaceRecentBlockhash: true,
  commitment: "processed",
});

if (simulation.value.err) {
  console.log("Simulation failed:", simulation.value.logs);
}
```

**On-chain**: After submission. Access via `getTransaction`:

```typescript
const tx = await connection.getTransaction(signature, {
  maxSupportedTransactionVersion: 0,
  commitment: "confirmed",
});
console.log(tx?.meta?.logMessages);
```

---

## Log Patterns and What They Mean

### "Program log: AnchorError caused by account: X"
→ Constraint failed on account X. Check the constraint type and that account.

### "Program log: Panicked at 'arithmetic operation overflowed'"
→ Integer overflow. Use `checked_add`, `checked_sub`, `checked_mul`.

### "Program failed to complete"
→ Compute budget exceeded. Simulate to measure CUs, then request more.

### "Transaction leaves an account with a lower balance than rent-exempt minimum"
→ Not enough lamports in the account after instruction. Ensure rent-exempt balance.

### "Program log: Error: insufficient lamports"
→ Account being created doesn't have enough SOL for rent. Increase `space` or add more lamports.

### "invalid account data for instruction"
→ Wrong account type passed — discriminator mismatch. Check account order in instruction.

### "Transaction version is not supported"
→ Sending versioned transaction to RPC that doesn't support it, or vice versa.

---

## Fetching Logs Programmatically

```typescript
// Get logs with error details
async function debugTransaction(signature: string) {
  const tx = await connection.getTransaction(signature, {
    maxSupportedTransactionVersion: 0,
    commitment: "confirmed",
  });

  if (!tx) return console.log("Transaction not found");

  const logs = tx.meta?.logMessages ?? [];
  const error = tx.meta?.err;

  console.log("Error:", JSON.stringify(error, null, 2));
  console.log("Logs:");
  logs.forEach((log, i) => console.log(`  ${i}: ${log}`));

  // Find failure line
  const failLine = logs.findIndex(l => l.includes("failed"));
  if (failLine > 0) {
    console.log("\nContext around failure:");
    logs.slice(Math.max(0, failLine - 3), failLine + 2).forEach(l => console.log(" →", l));
  }
}
```

---

## Log Analyzer Diagnostic Flow

```
Paste logs here →

1. Find the innermost [N] failure
2. Read the AnchorError line (if present)
3. Convert hex error code to decimal
4. Map to error name → route to correct sub-skill
5. Check account name in "caused by account: X"
6. Trace up the call chain for context
```
