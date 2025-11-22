from fastapi import FastAPI
from app.routers import history, exercises, schools, chat, search

app = FastAPI(title="LekturAI Backend")

app.include_router(history.router)
app.include_router(exercises.router)
app.include_router(schools.router)
app.include_router(chat.router)
app.include_router(search.router)

@app.get("/")
def root() -> dict[str, str]:
    return {"message": "LekturAI API is running"}