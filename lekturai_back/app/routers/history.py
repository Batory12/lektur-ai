from typing import Optional, List
from fastapi import APIRouter, Query
from datetime import datetime
from app.schemas import RecentQuestion, HistoryEntry
from app.db_utils import db_manager
from app.db_utils.db_service import FirestoreManager, UserHistoryEntry

router = APIRouter(tags=["History"])

## SORT_BY = {date, points} 
@router.get("/readings_history", response_model=List[UserHistoryEntry])
def get_readings_history(user_id: str, sort_by: str, from_: int, to: int)->List[UserHistoryEntry]:
    hist = db_manager.get_history_by_range(user_id, "reading", sort_by, from_, to)
    return hist

@router.get("/exercise_history", response_model=List[HistoryEntry])
def get_exercise_history(user_id: str, sort_by: str, from_: int, to: int)->List[UserHistoryEntry]:
    hist = db_manager.get_history_by_range(user_id, "exercise", sort_by, from_, to)
    return hist


@router.get("/recent_questions", response_model=List[RecentQuestion])
def get_recent_questions() -> List[RecentQuestion]:
    """Return a list of recent questions seen by the user.
    `type` may be one of: "reading", "matura", "otwarte", "zamkniete".
    """
    # WIT_TODO: AI mocked data — replace with DB queries in future
    return [
        RecentQuestion(
            type="reading",
            title="Pan Tadeusz - Inwokacja",
            description="Zinterpretuj początek utworu i wskaż epitetu.",
            user_answer="W mojej opinii inwokacja...",
            feedback="Dobrze uchwycone epitety, dodaj jeszcze kontekst historyczny.",
            grade=4.0,
        ),
        RecentQuestion(
            type="matura",
            title="Matura 2025 - zadanie 2",
            description="Analiza fragmentu prozy.",
            user_answer="Odpowiedź maturalna...",
            feedback="Brak rozwinięcia argumentacji.",
            grade=3.0,
        ),
        RecentQuestion(
            type="otwarte",
            title="Zadanie otwarte: rozprawka",
            description="Napisz rozprawkę na temat roli pamięci w literaturze.",
            user_answer="Pamięć odgrywa rolę...",
            feedback="Struktura ok, potrzebne przykłady z tekstów.",
            grade=4.2,
        ),
    ]