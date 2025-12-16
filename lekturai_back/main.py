import os

import uvicorn
from dotenv import load_dotenv

load_dotenv()

if __name__ == "__main__":
    uvicorn.run(
        "app.main:app",
        host=os.environ.get("LEKTURAI_URL"),
        port=os.environ.get("LEKTURAI_PORT"),
        reload=True,
    )
