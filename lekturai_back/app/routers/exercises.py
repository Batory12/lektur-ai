from fastapi import APIRouter, HTTPException

# --- Importy Gemini ---
from google import genai
from google.genai.errors import APIError

from app.db_utils import db_manager
from app.schemas import (
    GradeResponse,
    MaturaExercise,
    MaturaGradeResponse,
    MaturaSubmit,
    ReadingExerciseGen,
    ReadingExerciseSubmit,
)

# --- Konfiguracja Gemini ---
try:
    # Klient odczyta klucz z zmiennej środowiskowej GEMINI_API_KEY
    ai_client = genai.Client()
except Exception:
    # W przypadku braku klucza, ustawiamy klienta na None i obsłużymy błąd później
    ai_client = None
    print(
        "OSTRZEŻENIE: Klient Gemini nie został zainicjowany. Upewnij się, że GEMINI_API_KEY jest ustawiony."
    )


router = APIRouter(tags=["Exercises"])


# --- Funkcja pomocnicza do komunikacji z Gemini API ---
def call_gemini_api(prompt: str, system_instruction: str = None) -> str:
    if not ai_client:
        raise HTTPException(
            status_code=503,
            detail="Usługa AI jest obecnie niedostępna (Brak klucza API).",
        )

    try:
        config = {}
        if system_instruction:
            config["system_instruction"] = system_instruction

        response = ai_client.models.generate_content(
            model="gemini-2.5-flash", contents=prompt, config=config
        )
        return response.text
    except APIError as e:
        print(f"Błąd API Gemini: {e}")
        raise HTTPException(
            status_code=500, detail="Błąd podczas komunikacji z modelem AI."
        )
    except Exception as e:
        print(f"Nieznany błąd: {e}")
        raise HTTPException(status_code=500, detail="Wystąpił nieznany błąd serwera.")


# --- Lektury ---
@router.get("/reading_ex/{reading_name}", response_model=ReadingExerciseGen)
def generate_reading_exercise(
    reading_name: str, to_chapter: int | None = None
) -> ReadingExerciseGen:
    """Generuje zadanie z lektury przy użyciu Gemini."""

    chapter_info = f" do rozdziału {to_chapter}" if to_chapter else ""

    # Krok 1: Przygotowanie Prompta
    prompt = (
        f"Jesteś nauczycielem polonistą. Wygeneruj jedno, konkretne zadanie otwarte (np. opis, interpretacja, rozprawka) "
        f"na podstawie lektury '{reading_name}'{chapter_info}. Pytanie powinno być sformułowane jako polecenie. "
        f"Nie dodawaj żadnych wstępów ani komentarzy, tylko sam tytuł i treść zadania. "
        f"Tytuł oddziel od treści znakiem '#TITLE_SEP#'."
    )

    # Krok 2: Wywołanie API
    ai_response = call_gemini_api(prompt)

    # Krok 3: Parsowanie odpowiedzi
    try:
        title, text = ai_response.split("#TITLE_SEP#", 1)
        return ReadingExerciseGen(
            excercise_title=title.strip(), excercise_text=text.strip()
        )
    except ValueError:
        # W przypadku, gdy model nie zwróci separatora (awaria), zwracamy standardowy błąd
        return ReadingExerciseGen(
            excercise_title=f"Awaryjne Zadanie z: {reading_name}",
            excercise_text="Opisz zachowanie bohatera w rozdziale... (Błąd generowania AI)",
        )


@router.post("/reading_ex", response_model=GradeResponse)
def grade_reading_exercise(submission: ReadingExerciseSubmit) -> GradeResponse:
    """Ocenia zadanie z lektury przy użyciu Gemini."""

    # TODO: need user id input
    db_manager.update_stats_after_ex("user_name", 10)

    # Krok 1: Przygotowanie Prompta do Oceny
    prompt = (
        "Jesteś ekspertem oceniającym prace szkolne. Twoja rola to ocena i szczegółowy feedback. "
        f"Zadanie: '{submission.excercise_text}'\n"
        f"Odpowiedź ucznia: '{submission.user_answer}'\n\n"
        "Oceń odpowiedź w skali 1.0 (najgorsza) do 6.0 (najlepsza). "
        "Wygeneruj **tylko** dwie rzeczy, oddzielone znakiem '#GRADE_SEP#': "
        "1. Ostateczną ocenę numeryczną (np. 5.5). "
        "2. Szczegółowy feedback dla ucznia (co było dobre, co wymaga poprawy, z konkretnymi wskazówkami)."
    )

    # Krok 2: Wywołanie API
    ai_response = call_gemini_api(prompt)

    # Krok 3: Parsowanie odpowiedzi
    try:
        grade_str, feedback = ai_response.split("#GRADE_SEP#", 1)
        return GradeResponse(grade=float(grade_str.strip()), feedback=feedback.strip())
    except (ValueError, IndexError):
        return GradeResponse(
            grade=3.0, feedback="Błąd parsowania odpowiedzi AI. Spróbuj ponownie."
        )


# --- Matura ---
# Ten endpoint pozostaje bez zmian, ponieważ generuje prostą strukturę zadania
@router.get("/matura_ex", response_model=MaturaExercise)
def get_random_matura_task() -> MaturaExercise:
    # Można by użyć AI do generowania treści, ale na razie używamy prostego szablonu
    return MaturaExercise(
        excercise_id=101,
        excercise_title="Rozprawka",
        excercise_text="Czy praca uszlachetnia? Rozważ na podstawie Lalki.",
    )


@router.post("/matura_ex/{excercise_id}", response_model=MaturaGradeResponse)
def solve_matura_task(
    excercise_id: int, submission: MaturaSubmit
) -> MaturaGradeResponse:
    """Ocenia zadanie maturalne przy użyciu Gemini."""
    # TODO: need user id input
    db_manager.update_stats_after_ex("user_name", 2)

    # Krok 1: Przygotowanie Prompta do Oceny Maturalnej
    # Używamy system_instruction, aby ustawić rolę modelu AI
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

    # Krok 2: Wywołanie API
    ai_response = call_gemini_api(prompt, system_instruction=system_prompt)

    # Krok 3: Parsowanie odpowiedzi
    try:
        parts = ai_response.split("#SEP")
        grade_str = parts[0].strip()
        feedback = parts[1].strip().lstrip("123")  # Usuwamy ew. wiodące cyfry
        answer_key = parts[2].strip().lstrip("123")  # Usuwamy ew. wiodące cyfry

        return MaturaGradeResponse(
            excercise_id=excercise_id,
            user_answer=submission.user_answer,
            grade=float(grade_str),
            feedback=feedback,
            answer_key=answer_key,
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
