# Assembly style

Alien Soldier uses the same deterministic Mega Drive assembly layout as the
Flicky Source Reconstruction 1.0 tree:

- definitions begin in column zero;
- mnemonics begin in column 16;
- operands begin in column 24;
- ordinary inline comments begin in column 56, or two spaces after unusually
  long code;
- tabs, trailing whitespace, CR line endings, and non-ASCII source text are
  rejected;
- whole-line comments are indented in multiples of four;
- consecutive blank lines and redundant final blank lines are collapsed.

The same text rules apply outside the assembly. `make lint` checks every tracked
text file in the repository - source, includes, Python, Markdown, JSON, the
Makefile and the dotfiles - for valid UTF-8, LF line endings, exactly one final
newline and no trailing whitespace. `.gitattributes` normalizes what git stores;
the check is what notices when a tool or an editor writes CRLF back into the
working tree, which is the copy the assembler actually reads.

`make format` applies the canonical form to every `.s` and `.inc` file and then
runs `make lint`. The operation must be idempotent. Because label width can
change alignment, normal rename workflow is:

```text
make format
make verify
make test
make lint
```

Formatting is never allowed to explain a ROM difference. If `make verify` fails
after formatting, the formatter or source edit is wrong.
