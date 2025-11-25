from fastapi import FastAPI
from app.routers import auth, core

app = FastAPI()

app.include_router(auth.router)
app.include_router(core.router)