# Solana Diagnostics Skill

> **"Understand Solana failures in seconds."**

A production-ready Claude Code skill that turns your AI coding agent into an expert Solana diagnostics engineer. Paste an error, log, or code snippet — get root cause analysis, ranked likely causes, a working fix, and security warnings instantly.

Built for the [Solana AI Kit Bounty](https://github.com/solanabr/solana-ai-kit).

---

## What It Solves

Solana and Anchor errors are notoriously cryptic:

```
custom program error: 0x7d6
```

```
AnchorError caused by account: vault. Error Code: ConstraintSeeds. Error Number: 2006.
```

```
Program failed to complete
```

Every Solana developer has lost hours to errors like these. This skill gives your AI agent deep, structured knowledge to diagnose them immediately — with ranked root causes, confidence levels, and code fixes.

---

## Covered Error Categories

| Category | Sub-skill | Errors Covered |
|----------|-----------|---------------|
| Anchor Constraints | `anchor-errors.md` | ConstraintSeeds, ConstraintOwner, ConstraintSigner, ConstraintMut, AccountNotInitialized, InvalidAccountData, and 10+ more |
| PDA Debugging | `pda-debugging.md` | Seed mismatches, bump issues, PDA signing, encoding errors |
| CPI Failures | `cpi-failures.md` | Missing accounts, depth exceeded, reentrancy, arbitrary CPI |
| Compute Budget | `compute-budget.md` | CU exceeded, optimization, priority fees |
| Token Errors | `token-errors.md` | SPL Token, Token-2022, ATA, mint authority, freeze |
| Log Analysis | `log-analyzer.md` | Transaction log parsing, hex error decoding, simulation |
| Deployment | `deployment.md` | Build failures, deploy issues, upgrades, readiness checklist |
| Security Audit | `security-audit.md` | 8 critical vulnerability classes, full audit checklist |

---

## Install

```bash
git clone https://github.com/YOUR_USERNAME/solana-diagnostics-skill
cd solana-diagnostics-skill
bash install.sh
```

Or add directly to your Claude Code skill path:

```
skill/SKILL.md
```

---

## Commands

### `/diagnose`

Instantly diagnose any Solana error:

```
/diagnose ConstraintSeeds Error Number: 2006
/diagnose Program log: AnchorError caused by account: vault
/diagnose custom program error: 0x7d6
/diagnose exceeded CU meter at BPF instruction
```

**Output:** Error type → Root cause → Ranked causes with confidence % → Code fix → Security notes → Prevention checklist

Add `--simple` for beginner-friendly explanations.

### `/audit`

Security audit your Anchor program:

```
/audit
#[program]
pub mod my_program {
    // paste your program here
}
```

**Output:** Critical / High / Medium / Low findings with line-level fixes and deployment recommendation.

---

## Skill Structure

```
solana-diagnostics-skill/
├── skill/
│   ├── SKILL.md              ← Entry point + router
│   ├── anchor-errors.md      ← Anchor constraint errors
│   ├── pda-debugging.md      ← PDA derivation & bump issues
│   ├── cpi-failures.md       ← Cross-program invocation failures
│   ├── compute-budget.md     ← CU management & optimization
│   ├── token-errors.md       ← SPL Token & Token-2022
│   ├── log-analyzer.md       ← Transaction log parsing
│   ├── deployment.md         ← Build, deploy, upgrade
│   └── security-audit.md     ← Security vulnerabilities & audit
├── commands/
│   ├── diagnose.md           ← /diagnose command
│   └── audit.md              ← /audit command
├── agents/
│   └── diagnostics-agent.md  ← Agent persona & behavior
├── rules/
│   └── diagnostics-rules.md  ← Always-on rules
├── install.sh
└── README.md
```

### Progressive Loading

The skill uses token-efficient progressive loading — only the relevant sub-skill file is loaded based on the error category. The full skill hub is never loaded at once.

---

## 2026 Stack Compatibility

- Anchor 0.30.x
- solana-web3.js v2.x
- Token-2022 / `TokenInterface` aware
- Versioned transactions as default
- `InitSpace` derive macro patterns

---

## License

MIT — ready to be merged or submoduled into the Solana AI Kit.
