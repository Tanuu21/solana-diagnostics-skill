#!/bin/bash

# Solana Diagnostics Skill — Installer
# Installs the skill into Claude Code / Codex configuration

set -e

SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="${HOME}/.claude/skills/solana-diagnostics-skill"

echo "🔧 Installing Solana Diagnostics Skill..."

# Create target directory
mkdir -p "$TARGET_DIR"

# Copy skill files
cp -r "$SKILL_DIR/skill" "$TARGET_DIR/"
cp -r "$SKILL_DIR/commands" "$TARGET_DIR/"
cp -r "$SKILL_DIR/agents" "$TARGET_DIR/"
cp -r "$SKILL_DIR/rules" "$TARGET_DIR/"
cp "$SKILL_DIR/README.md" "$TARGET_DIR/"

echo "✅ Skill installed to $TARGET_DIR"

# Check for Claude Code config
CLAUDE_CONFIG="${HOME}/.claude/config.json"
if [ -f "$CLAUDE_CONFIG" ]; then
  echo "📋 Found Claude Code config at $CLAUDE_CONFIG"
  echo "   Add the following to your skills array:"
  echo '   { "path": "~/.claude/skills/solana-diagnostics-skill/skill/SKILL.md" }'
else
  echo ""
  echo "📋 Next steps:"
  echo "   1. Open your Claude Code configuration"
  echo "   2. Add this skill path:"
  echo "      $TARGET_DIR/skill/SKILL.md"
  echo ""
  echo "   Or for Claude Code CLI:"
  echo "   claude --skill $TARGET_DIR/skill/SKILL.md"
fi

echo ""
echo "🚀 Available commands after install:"
echo "   /diagnose  — Diagnose Solana errors instantly"
echo "   /audit     — Security audit your Anchor program"
echo ""
echo "📚 Documentation: $TARGET_DIR/README.md"
