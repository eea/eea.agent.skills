# Fix loop

Use this loop whenever code-quality checks are already failing:

1. Reproduce the failure with the exact repository or Jenkins command.
2. Save the failing output and identify the smallest affected scope.
3. Apply safe auto-fixes first.
4. Repair remaining logic, typing, or configuration issues directly.
5. Rerun the same command.
6. Repeat until green.
7. After individual commands pass, rerun the full quality sequence in the same order Jenkins uses.

## Key rule

Never replace a failing repository command with a different easier command and call the issue solved. The same failing command must pass by the end.
