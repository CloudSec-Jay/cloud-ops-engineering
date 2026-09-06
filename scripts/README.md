# Repository Scripts

This directory contains narrowly scoped helpers used by repository workflows or maintenance tasks.

- [`ansible/fix_py313_regex.py`](ansible/fix_py313_regex.py): compatibility helper associated with the Ansible toolchain

Scripts belong here only when they support more than one component or repository-level maintenance. Component-specific deployment and teardown scripts should stay beside the component they operate.

Inspect a script before execution, run it against disposable inputs first, and document any destructive or privileged behavior.
