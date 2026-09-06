#!/usr/bin/env python3
"""Fix Python 3.13 regex incompatibility in ansible-lockdown.RHEL9-CIS role.
   Moves inline flags from ^(?i) to (?i)^ across all task files."""

import os

role_tasks = os.path.join(
    os.path.dirname(__file__),
    ".ansible/roles/ansible-lockdown.RHEL9-CIS/tasks"
)

fixed = 0
for root, dirs, files in os.walk(role_tasks):
    for f in files:
        if not f.endswith(".yml"):
            continue
        path = os.path.join(root, f)
        with open(path, "r") as fh:
            content = fh.read()
        if "^(?i)" in content:
            with open(path, "w") as fh:
                fh.write(content.replace("^(?i)", "(?i)^"))
            print(f"fixed: {path.replace(role_tasks, '')}")
            fixed += 1

print(f"\n{fixed} file(s) fixed")
