import hashlib
import argparse
import sys
import os

def calculate_hash(file_path, algorithm='sha256'):
    """Calculates the cryptographic hash of a file using an efficient chunked stream."""
    try:
        hash_func = hashlib.new(algorithm)
        with open(file_path, 'rb') as f:
            # Read in 64KB chunks to handle large files (ISOs, Binaries) efficiently
            for chunk in iter(lambda: f.read(65536), b''):
                hash_func.update(chunk)
        return hash_func.hexdigest()
    except ValueError:
        print(f"❌ Error: Unsupported hashing algorithm '{algorithm}'")
        sys.exit(2)
    except FileNotFoundError:
        print(f"❌ Error: File not found at '{file_path}'")
        sys.exit(2)
    except PermissionError:
        print(f"❌ Error: Permission denied reading '{file_path}'")
        sys.exit(2)

def main():
    parser = argparse.ArgumentParser(
        description="🛡️ Secure Checksum Validator — Automated Data Integrity Verification",
        epilog="Example: python3 checksum.py --file ubuntu.iso --checksum <hash_string> --algo sha256"
    )

    parser.add_argument("-f", "--file", required=True, help="Path to the target file for verification")
    parser.add_argument("-c", "--checksum", required=True, help="The expected cryptographic hash string (provided by the source)")
    parser.add_argument("-a", "--algo", default="sha256", choices=['md5', 'sha1', 'sha256', 'sha512'],
                        help="Cryptographic hashing algorithm (default: sha256)")

    # Print help if no arguments provided
    if len(sys.argv) == 1:
        parser.print_help()
        sys.exit(1)

    args = parser.parse_args()

    print(f"🔍 Validating {args.file} using {args.algo.upper()}...")

    computed_hash = calculate_hash(args.file, args.algo)

    # Compare hashes (case-insensitive)
    if computed_hash.lower() == args.checksum.lower():
        print(f"✅ SUCCESS: Checksum matches!")
        print(f"   Result: {computed_hash}")
        sys.exit(0) # Success code for pipeline integration
    else:
        print(f"❌ FAILURE: Checksum mismatch!")
        print(f"   Expected: {args.checksum.lower()}")
        print(f"   Computed: {computed_hash.lower()}")
        sys.exit(1) # Error code to break a secure download pipeline

if __name__ == "__main__":
    main()
