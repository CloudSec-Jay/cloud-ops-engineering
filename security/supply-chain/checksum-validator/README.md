# Checksum Validator

Small local tools for comparing a downloaded file with a publisher-provided checksum.

## Verify an existing file

```bash
python3 checksum.py \
  --file PATH/TO/FILE \
  --checksum EXPECTED_PUBLISHER_HASH \
  --algo sha256
```

Exit status `0` means the computed value matched. Status `1` means mismatch; status `2` means an unsupported algorithm, missing file, or permission failure.

## Download and verify

`vget.sh` defines a Bash function that uses `curl` and `checksum.py`:

```bash
source security/supply-chain/checksum-validator/vget.sh
vget URL EXPECTED_PUBLISHER_HASH sha256
```

Run it in an empty temporary directory. The current helper derives the output filename from the URL, may overwrite a same-named local file, and deletes that filename when verification fails. Review this behavior before use.

## Trust boundary

- Retrieve the artifact and expected checksum through independently authenticated channels when possible.
- Do not use a checksum supplied only beside an artifact from an untrusted mirror.
- Prefer SHA-256 or SHA-512; MD5 and SHA-1 remain available for compatibility, not security-sensitive verification.
- A matching checksum proves byte equality with the expected value, not that the publisher or software is trustworthy.
