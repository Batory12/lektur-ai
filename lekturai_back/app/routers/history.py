from typing import Optional, List
from fastapi import APIRouter, Query
from datetime import datetime
from app.schemas import RecentQuestion, HistoryEntry

router = APIRouter(tags=["History"])


def _within_range(d: datetime, start: Optional[datetime], end: Optional[datetime]) -> bool:
    if start and d < start:
        return False
    if end and d > end:
        return False
    return True


@router.get("/readings_history", response_model=List[HistoryEntry])
def get_readings_history(
    dayfrom: Optional[datetime] = Query(None, description="Start date (inclusive)"),
    dayto: Optional[datetime] = Query(None, description="End date (inclusive)"),
) -> List[HistoryEntry]:
    """Return reading (lektury) history between optional dayfrom and dayto."""
    # WIT_TODO: AI mocked data — replace with DB queries in future
    sample: List[HistoryEntry] = [
        HistoryEntry(date=datetime(2025, 11, 1, 10, 0), summary="Czytanie: Pan Tadeusz - ks.1", points=8),
        HistoryEntry(date=datetime(2025, 11, 5, 15, 30), summary="Czytanie: Lalka - rozdział 2", points=7),
        HistoryEntry(date=datetime(2025, 11, 20, 9, 0), summary="Czytanie: Balladyna - scena 3", points=9),
    ]

    return [h for h in sample if _within_range(h.date, dayfrom, dayto)]


@router.get("/exercise_history", response_model=List[HistoryEntry])
def get_exercise_history(
    dayfrom: Optional[datetime] = Query(None, description="Start date (inclusive)"),
    dayto: Optional[datetime] = Query(None, description="End date (inclusive)"),
) -> List[HistoryEntry]:
    """Return exercises history (matura/ćwiczenia) between optional dayfrom and dayto."""
    # WIT_TODO: AI mocked data — replace with DB queries in future
    sample: List[HistoryEntry] = [
        HistoryEntry(date=datetime(2025, 10, 30, 11, 0), summary="Matura: interpretacja wiersza", points=6),
        HistoryEntry(date=datetime(2025, 11, 10, 12, 0), summary="Zadanie otwarte: rozprawka", points=5),
        HistoryEntry(date=datetime(2025, 11, 18, 14, 0), summary="Zadanie zamknięte: test wiedzy", points=10),
    ]

    return [h for h in sample if _within_range(h.date, dayfrom, dayto)]


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