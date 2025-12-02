from fastapi import APIRouter
from app.schemas import ChatMessage, ChatResponse

router = APIRouter(prefix="/chat", tags=["ChatBot"])

@router.post("/new")
def create_conversation() -> dict[str, int]:
    return {"conversation_id": 123}

@router.post("/{conversation_id}", response_model=ChatResponse)
def send_message(conversation_id: int, msg: ChatMessage) -> ChatResponse:
    return ChatResponse(
        conversation_id=conversation_id,
        message=f"Otrzymałem: {msg.message}"
    )