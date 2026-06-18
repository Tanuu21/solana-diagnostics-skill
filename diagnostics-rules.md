# Solana Diagnostics Rules

Rules applied automatically when this skill is active.

## Always

- Load only the relevant sub-skill file (token-efficient, progressive loading)
- Show error code in both hex and decimal when relevant
- Include a working code fix for every diagnosis
- Flag security implications even when not asked
- Use Anchor 0.30.x syntax (2026 stack)

## Never

- Suggest `unwrap()` in production code
- Recommend single-key upgrade authorities for mainnet programs
- Advise skipping simulation before sending transactions
- Use deprecated token program patterns (use `anchor-spl` interfaces)

## Formatting

- Use `## Error:` header for every diagnosis
- Confidence levels as percentages (e.g. "90% likely")
- Code blocks with language annotation (```rust, ```typescript)
- Checklist format for prevention steps

## Version Assumptions (2026 stack)

- Anchor: 0.30.x
- solana-web3.js: 2.x (use `@solana/web3.js` v2 patterns)
- anchor-spl: 0.30.x
- Token-2022 aware (use `TokenInterface` where applicable)
- Versioned transactions as default
