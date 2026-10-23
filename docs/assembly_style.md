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

`make lint` runs Retrolarium Kit's shared linter (`rltool lint`, configured by
`config/lint.json`): the assembly layout, and every tracked text file in the
repository - source, includes, Python, Markdown, JSON, the Makefile and the
dotfiles - for valid UTF-8, LF line endings, exactly one final newline, no
trailing whitespace and the shared formatters' output. `.gitattributes`
normalizes what git stores; the check is what notices when a tool or an editor
writes CRLF back into the working tree, which is the copy the assembler actually
reads.

`make format` applies the canonical form to every `.s` and `.inc` file and the
formatters to the rest. The operation must be idempotent. Because label width
can change alignment, normal rename workflow is:

```text
make format
make verify-revisions
make test
make lint
```

Formatting is never allowed to explain a ROM difference. If `make verify` fails
after formatting, the formatter or source edit is wrong.
