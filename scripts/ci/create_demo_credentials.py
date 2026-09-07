"""Write GitHub Actions demo credentials to a temporary dart-define file."""

import json
import os
from pathlib import Path
import sys


username = os.environ.get("DEMO_LOGIN_USERNAME", "")
password = os.environ.get("DEMO_LOGIN_PASSWORD", "")
output = Path(sys.argv[1])
output.unlink(missing_ok=True)

if not username or not password:
    print(
        "DEMO_LOGIN_USERNAME and DEMO_LOGIN_PASSWORD GitHub Secrets are required.",
        file=sys.stderr,
    )
    sys.exit(1)

output.write_text(
    json.dumps(
        {
            "DEMO_LOGIN_USERNAME": username,
            "DEMO_LOGIN_PASSWORD": password,
            "REQUIRE_DEMO_CREDENTIALS": True,
        }
    ),
    encoding="utf-8",
)
