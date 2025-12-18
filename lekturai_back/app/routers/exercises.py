import random

from fastapi import APIRouter, Depends, HTTPException

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

from ..db_utils import db_manager

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
    submission: ReadingExerciseSubmit,
    user_id: str,
    ai_service: AIService = Depends(get_ai_service),
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
        db_manager.update_stats_after_ex(user_id, int(float(grade_str.strip())*10))
        db_manager.save_readings_to_history(user_id, submission, 2, feedback.strip())
        return GradeResponse(grade=float(grade_str.strip()), feedback=feedback.strip())
    except (ValueError, IndexError):
        return GradeResponse(
            grade=3.0, feedback="Błąd parsowania odpowiedzi AI. Spróbuj ponownie."
        )


# --- Matura ---


@router.get("/matura_ex", response_model=MaturaExercise)
def get_random_matura_task() -> MaturaExercise:
    exam = None
    try:
        # Pobierz pierwszy dostępny egzamin (lub losowy z puli)
        exams_query = db_manager.db.collection(db_manager.EXAMS_COLLECTION).limit(5)
        docs = list(exams_query.stream())
        if not docs:
            raise HTTPException(status_code=404, detail="Brak egzaminów w bazie.")

        # Losujemy jeden dokument
        doc = random.choice(docs)
        exam = db_manager.get_exam(doc.id)
        if not exam:
            raise HTTPException(
                status_code=404, detail="Nie udało się odczytać egzaminu z bazy."
            )
    except Exception as e:
        print(f"Błąd pobierania egzaminu z Firestore: {e}")
        raise HTTPException(
            status_code=500, detail="Błąd serwera podczas pobierania egzaminu."
        )

    questions = db_manager.get_exam_questions(exam.id) if exam and exam.id else []
    if not questions:
        raise HTTPException(status_code=404, detail="Brak zadań dla tego egzaminu.")

    question = random.choice(questions)

    # Znormalizuj teksty: jeśli z ekstraktora przychodzą w stronach, łączymy strony w jeden ciąg
    raw_texts = exam.texts or []
    normalized_texts: list[dict] = []
    for t in raw_texts:
        if isinstance(t, dict) and "pages" in t:
            pages = t.get("pages") or []
            full_text_parts = [
                p.get("text") for p in pages if isinstance(p, dict) and p.get("text")
            ]
            full_text = "\n\n".join(full_text_parts)

            normalized_texts.append(
                {
                    "number": t.get("number"),
                    "author": t.get("author"),
                    "title": t.get("title"),
                    "text": full_text,
                }
            )
        else:
            normalized_texts.append(t)

    # Tworzymy composite ID: EXAM_ID:QUESTION_NUMBER
    composite_id = f"{exam.id}:{question.number}"

    return MaturaExercise(
        excercise_id=composite_id,
        excercise_title=f"Zadanie {question.number}",
        excercise_text=question.text,
        max_points=question.max_points,
        texts=normalized_texts,
    )


@router.post("/matura_ex/{excercise_id}", response_model=MaturaGradeResponse)
def solve_matura_task(
    excercise_id: str,
    submission: MaturaSubmit,
    user_id: str,
    ai_service: AIService = Depends(get_ai_service),
) -> MaturaGradeResponse:
    """Ocenia zadanie maturalne przy użyciu Gemini."""

    # Parsowanie ID (ExamID:QuestionNumber)
    try:
        exam_id, q_num_str = excercise_id.split(":", 1)
        question_number = int(q_num_str)
    except ValueError:
        raise HTTPException(status_code=400, detail="Nieprawidłowe ID zadania.")

    # Pobieranie danych z bazy
    exam = db_manager.get_exam(exam_id)
    if not exam:
        raise HTTPException(status_code=404, detail="Egzamin nie istnieje.")

    questions = db_manager.get_exam_questions(exam_id)
    question = next((q for q in questions if q.number == question_number), None)

    answers_map = db_manager.get_exam_answers(exam_id)
    answer = answers_map.get(question_number)

    if not question or not answer:
        raise HTTPException(status_code=404, detail="Brak danych zadania w bazie.")

    # Budowanie kontekstu tekstów
    texts = exam.texts or []
    texts_str_parts = []
    for t in texts:
        number = t.get("number")
        author = t.get("author")
        title = t.get("title")
        # Obsługa paginacji w locie dla prompta
        if "pages" in t:
            text_body = "\n".join([p.get("text", "") for p in t.get("pages", [])])
        else:
            text_body = t.get("text", "")

        header = (
            f"[TEKST {number}] {author}: {title}"
            if number is not None
            else f"[TEKST] {author}: {title}"
        )
        texts_str_parts.append(f"{header}\n{text_body}\n")

    texts_str = (
        "\n\n".join(texts_str_parts) if texts_str_parts else "Brak tekstów źródłowych."
    )

    # Krok 1: Przygotowanie Prompta
    system_prompt = (
        "Jesteś rygorystycznym egzaminatorem maturalnym. Twoim celem jest ocena, feedback "
        "oraz podanie wzorcowej tezy/klucza odpowiedzi, ale w sekcjach wydzielonych separatorami. "
        "Oceniasz na podstawie oficjalnego klucza i tekstów źródłowych."
    )

    prompt = (
        "Oceń i przeanalizuj poniższą odpowiedź maturalną. \n\n"
        "TEKSTY EGZAMINACYJNE:\n"
        f"{texts_str}\n\n"
        f"Zadanie: '{question.text}'\n"
        f"Oficjalny klucz/kryteria: '{answer.text}'\n"
        f"Max punktów: {question.max_points}\n\n"
        f"Odpowiedź zdającego: '{submission.user_answer}'\n\n"
        "1. Oceń (liczba punktów). Nie przekraczaj max punktów. "
        "2. Wystaw szczegółowy feedback. "
        "3. Podaj wzorcowy klucz odpowiedzi (przepisz go lub streść).\n\n"
        "FORMAT: [OCENA]#SEP1#[FEEDBACK]#SEP2#[KLUCZ_ODPOWIEDZI]"
    )

    # Krok 2: Wywołanie API przez Service
    ai_response = ai_service.generate_content(prompt, system_instruction=system_prompt)

    # Krok 3: Parsowanie odpowiedzi
    try:
        # Rozdzielanie po separatorach zdefiniowanych w promptcie
        part1, rest = ai_response.split("#SEP1#", 1)
        feedback, answer_key_ai = rest.split("#SEP2#", 1)

        grade_str = part1.strip().replace(",", ".")
        # Prosta sanityzacja jeśli AI zwróci np. "2/3"
        if "/" in grade_str:
            grade_str = grade_str.split("/")[0]

        grade_val = float(grade_str)

        db_manager.update_stats_after_ex(user_id, int(float(grade_val)*10))
        db_manager.save_matura_ex_to_history(
            user_id, question.text, submission.user_answer, int(grade_val), feedback.strip()
        )

        return MaturaGradeResponse(
            excercise_id=excercise_id,
            user_answer=submission.user_answer,
            grade=grade_val,
            feedback=feedback.strip(),
            answer_key=answer.text,  # Zwracamy klucz z bazy (pewniejszy) lub ten z AI (answer_key_ai)
        )
    except (ValueError, IndexError) as e:
        print(f"Błąd parsowania odpowiedzi Matura AI: {e}")
        return MaturaGradeResponse(
            excercise_id=excercise_id,
            user_answer=submission.user_answer,
            grade=0.0,
            feedback=f"Błąd parsowania odpowiedzi AI: {ai_response}",
            answer_key=answer.text,
        )
