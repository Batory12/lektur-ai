from fastapi import APIRouter, Depends

from app.db_utils import db_manager
from app.schemas import (
    GradeResponse,
    MaturaExercise,
    MaturaGradeResponse,
    MaturaSubmit,
    ReadingExerciseGen,
    ReadingExerciseSubmit,
)

# Import the service and dependency
from app.services.ai_service import AIService, get_ai_service

router = APIRouter(tags=["Exercises"])

# --- Lektury ---


@router.get("/reading_ex/{reading_name}", response_model=ReadingExerciseGen)
def generate_reading_exercise(
    reading_name: str,
    to_chapter: int | None = None,
    ai_service: AIService = Depends(get_ai_service),
) -> ReadingExerciseGen:
    """Generuje zadanie z lektury przy użyciu Gemini."""

    chapter_info = f" do rozdziału {to_chapter}" if to_chapter else ""

    # Krok 1: Przygotowanie Prompta (Twoja oryginalna treść)
    prompt = (
        f"Jesteś nauczycielem polonistą. Wygeneruj jedno, konkretne zadanie otwarte (np. opis, interpretacja, rozprawka) "
        f"na podstawie lektury '{reading_name}'{chapter_info}. Pytanie powinno być sformułowane jako polecenie. "
        f"Nie dodawaj żadnych wstępów ani komentarzy, tylko sam tytuł i treść zadania. "
        f"Tytuł oddziel od treści znakiem '#TITLE_SEP#'."
    )

    # Krok 2: Wywołanie API przez Service
    ai_response = ai_service.generate_content(prompt)

    # Krok 3: Parsowanie odpowiedzi
    try:
        title, text = ai_response.split("#TITLE_SEP#", 1)
        return ReadingExerciseGen(
            excercise_title=title.strip(), excercise_text=text.strip()
        )
    except ValueError:
        return ReadingExerciseGen(
            excercise_title=f"Awaryjne Zadanie z: {reading_name}",
            excercise_text="Opisz zachowanie bohatera w rozdziale... (Błąd generowania AI)",
        )


@router.post("/reading_ex", response_model=GradeResponse)
def grade_reading_exercise(
    submission: ReadingExerciseSubmit, user_id: str, ai_service: AIService = Depends(get_ai_service),
) -> GradeResponse:
    """Ocenia zadanie z lektury przy użyciu Gemini."""

    # Krok 1: Przygotowanie Prompta do Oceny (Twoja oryginalna treść)
    prompt = (
        "Jesteś ekspertem oceniającym prace szkolne. Twoja rola to ocena i szczegółowy feedback. "
        f"Zadanie: '{submission.excercise_text}'\n"
        f"Odpowiedź ucznia: '{submission.user_answer}'\n\n"
        "Oceń odpowiedź w skali 1.0 (najgorsza) do 6.0 (najlepsza). "
        "Wygeneruj **tylko** dwie rzeczy, oddzielone znakiem '#GRADE_SEP#': "
        "1. Ostateczną ocenę numeryczną (np. 5.5). "
        "2. Szczegółowy feedback dla ucznia (co było dobre, co wymaga poprawy, z konkretnymi wskazówkami)."
    )

    # Krok 2: Wywołanie API przez Service
    ai_response = ai_service.generate_content(prompt)

    # Krok 3: Parsowanie odpowiedzi
    # TODO:: USTALIĆ JAK KONWERTOWAĆ GRADE NA POINTS!!!!!
    # Czy grade może być int? 
    try:
        grade_str, feedback = ai_response.split("#GRADE_SEP#", 1)
        db_manager.update_stats_after_ex(user_id, 2)
        db_manager.save_readings_to_history(user_id, submission, 2, feedback.strip())
        return GradeResponse(grade=float(grade_str.strip()), feedback=feedback.strip())
    except (ValueError, IndexError):
        return GradeResponse(
            grade=3.0, feedback="Błąd parsowania odpowiedzi AI. Spróbuj ponownie."
        )


# --- Matura ---


@router.get("/matura_ex", response_model=MaturaExercise)
def get_random_matura_task() -> MaturaExercise:
    # Ten endpoint nie wymaga AI Service
    return MaturaExercise(
        excercise_id=101,
        excercise_title="Rozprawka",
        excercise_text="Czy praca uszlachetnia? Rozważ na podstawie Lalki.",
    )


@router.post("/matura_ex/{excercise_id}", response_model=MaturaGradeResponse)
def solve_matura_task(
    excercise_id: int,
    submission: MaturaSubmit,
    user_id: str,
    ai_service: AIService = Depends(get_ai_service),
) -> MaturaGradeResponse:
    """Ocenia zadanie maturalne przy użyciu Gemini."""

    # Krok 1: Przygotowanie Prompta (Twoja oryginalna treść)
    system_prompt = (
        "Jesteś rygorystycznym egzaminatorem maturalnym. Twoim celem jest ocena, feedback "
        "oraz podanie wzorcowej tezy/klucza odpowiedzi, ale w sekcjach wydzielonych separatorami."
    )

    prompt = (
        "Oceń i przeanalizuj poniższą odpowiedź maturalną. "
        f"Zadanie: 'Czy praca uszlachetnia? Rozważ na podstawie Lalki.'\n"
        f"Odpowiedź zdającego: '{submission.user_answer}'\n\n"
        "1. Oceń w skali 1.0 do 6.0. "
        "2. Wystaw szczegółowy feedback. "
        "3. Podaj wzorcowy klucz odpowiedzi/tezy.\n\n"
        "FORMAT: [OCENA]#SEP1#[FEEDBACK]#SEP2#[KLUCZ_ODPOWIEDZI]"
    )

    # Krok 2: Wywołanie API przez Service
    ai_response = ai_service.generate_content(prompt, system_instruction=system_prompt)

    # Krok 3: Parsowanie odpowiedzi
    try:
        # Rozdzielanie po separatorach zdefiniowanych w promptcie
        part1, rest = ai_response.split("#SEP1#", 1)
        feedback, answer_key = rest.split("#SEP2#", 1)

        grade_str = part1.strip()

        db_manager.update_stats_after_ex(user_id, int(grade_str))
        db_manager.save_matura_ex_to_history(user_id, submission, int(grade_str), feedback.strip())
        return MaturaGradeResponse(
            excercise_id=excercise_id,
            user_answer=submission.user_answer,
            grade=float(grade_str),
            feedback=feedback.strip(),
            answer_key=answer_key.strip(),
        )
    except (ValueError, IndexError) as e:
        print(f"Błąd parsowania odpowiedzi Matura AI: {e}")
        return MaturaGradeResponse(
            excercise_id=excercise_id,
            user_answer=submission.user_answer,
            grade=1.0,
            feedback="Błąd parsowania odpowiedzi AI. Spróbuj ponownie.",
            answer_key="Brak danych wzorcowych.",
        )
