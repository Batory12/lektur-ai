from fastapi import FastAPI
from app.routers import history, exercises, schools, chat, search, stats
from fastapi.middleware.cors import CORSMiddleware


app = FastAPI(title="LekturAI Backend")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],        # Allow all origins
    allow_credentials=True,
    allow_methods=["*"],        # Allow all HTTP methods
    allow_headers=["*"],        # Allow all headers
)

app.include_router(history.router)
app.include_router(exercises.router)
app.include_router(schools.router)
app.include_router(chat.router)
app.include_router(search.router)
app.include_router(stats.router)

@app.get("/")
def root() -> dict[str, str]:
    return {"message": "LekturAI API is running"}