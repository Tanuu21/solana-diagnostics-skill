# /audit command

Security audit your Anchor program code for critical vulnerabilities.

## Usage

```
/audit <paste Anchor program code or file path>
```

## What this command does

1. Scans for the 8 critical Solana vulnerability classes
2. Ranks findings by severity (Critical → High → Medium → Low)
3. Provides specific line-level fix recommendations
4. Generates an audit summary report

## Severity levels

| Level | Meaning |
|-------|---------|
| 🔴 Critical | Exploitable now, fix before any deployment |
| 🟠 High | Fix before mainnet |
| 🟡 Medium | Best practice violation |
| 🟢 Low | Code quality / gas optimization |

## Vulnerability classes checked

- Missing signer checks
- Missing ownership validation  
- Arbitrary CPI
- Integer overflow / underflow
- PDA substitution attack
- Reentrancy via CPI
- Type confusion
- Incorrect account closing

## Output format

```
## Audit Report: [Program Name]

### 🔴 Critical Issues
[Issue + line + fix]

### 🟠 High Risk Issues
[Issue + line + fix]

### 🟡 Medium Issues
[Issue + line + fix]

### 🟢 Low / Best Practice
[Issue + line + fix]

### Overall Readiness
[Deployment recommendation]
```

## Example

```
/audit
#[program]
pub mod my_program {
    pub fn admin_withdraw(ctx: Context<AdminWithdraw>, amount: u64) -> Result<()> {
        // ... paste full program
    }
}
```
