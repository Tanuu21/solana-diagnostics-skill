# /diagnose command

Instantly diagnose a Solana or Anchor error from logs, error messages, or code snippets.

## Usage

```
/diagnose <error message, transaction log, or code snippet>
```

## Examples

```
/diagnose ConstraintSeeds Error Number: 2006
/diagnose Program log: AnchorError caused by account: vault
/diagnose custom program error: 0x7d6
/diagnose exceeded CU meter at BPF instruction
```

## What this command does

1. Reads the pasted error or log
2. Identifies error type and category
3. Loads the relevant skill file
4. Returns ranked root causes with confidence levels
5. Provides a code fix with explanation
6. Lists a prevention checklist

## Beginner mode

Add `--simple` for plain-language explanations:

```
/diagnose ConstraintSeeds --simple
```

## Output format

```
## Error: [Name]
Category: [Anchor / PDA / CPI / Token / Compute / Deployment]

## Root Cause
[Clear explanation of what went wrong]

## Most Likely Causes
1. [Cause] — XX% likely
2. [Cause] — XX% likely
3. [Cause] — XX% likely

## Fix
[Code example]

## Security Notes
[Any security implications]

## Prevention
- [ ] item
- [ ] item
```
