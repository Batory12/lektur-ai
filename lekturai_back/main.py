import os

import uvicorn
from dotenv import load_dotenv

load_dotenv()

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host=os.getenv("LEKTURAI_URL", "0.0.0.0"),
        port=int(os.getenv("LEKTURAI_PORT", "8000")),
        reload=True,
    )
