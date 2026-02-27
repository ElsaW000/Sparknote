import os
from backend.ai_provider import get_provider

# ensure we pick up env vars
provider = get_provider()
print("using provider", type(provider))
print(provider.get_reply("你好"))
