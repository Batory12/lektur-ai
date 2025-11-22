from fastapi import APIRouter
from app.schemas import LoginRequest, Token

router = APIRouter(tags=["Auth"])

@router.post("/login", response_model=Token)
def login(creds: LoginRequest):
    # TODO: login logic
    return {"access_token": "", "token_type": "bearer"}