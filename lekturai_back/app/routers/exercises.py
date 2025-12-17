import random
from fastapi import APIRouter, Depends, HTTPException

from app.db_utils import db_manager
from app.schemas import (
    GradeResponse,
    MaturaDbExercise,
    MaturaDbGradeResponse,
    MaturaDbSubmit,
    MaturaExercise,
    MaturaGradeResponse,
    MaturaSubmit,
    ReadingExerciseGen,
    ReadingExerciseSubmit,
)
from ..db_utils import db_manager
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

# --- Matura z bazy (Firestore) ---
@router.get("/matura_db/random", response_model=MaturaDbExercise)
def get_random_matura_db_task() -> MaturaDbExercise:
    """
    Zwraca losowe zadanie maturalne z bazy:
    - losujemy egzamin (na razie: pierwszy znaleziony)
    - losujemy jedno zadanie (Question) z tego egzaminu
    """

    exam = None
    try:
        # Pobierz pierwszy dostępny egzamin
        exams_query = db_manager.db.collection(db_manager.EXAMS_COLLECTION).limit(1)
        docs = list(exams_query.stream())
        if not docs:
            raise HTTPException(status_code=404, detail="Brak egzaminów w bazie.")
        doc = docs[0]
        exam = db_manager.get_exam(doc.id)
        if not exam:
            raise HTTPException(status_code=404, detail="Nie udało się odczytać egzaminu z bazy.")
    except HTTPException:
        raise
    except Exception as e:
        print(f"Błąd pobierania egzaminu z Firestore: {e}")
        raise HTTPException(status_code=500, detail="Błąd serwera podczas pobierania egzaminu.")

    questions = db_manager.get_exam_questions(exam.id) if exam and exam.id else []
    if not questions:
        raise HTTPException(status_code=404, detail="Brak zadań dla tego egzaminu.")

    question = random.choice(questions)

    # Znormalizuj teksty: jeśli z ekstraktora przychodzą w stronach, łączymy strony w jeden ciąg
    raw_texts = exam.texts or []
    normalized_texts: list[dict] = []
    for t in raw_texts:
        # przykładowa struktura z paginacją: {"number": 1, "author": "...", "title": "...", "pages": [{"page": 1, "text": "..."}, ...]}
        if isinstance(t, dict) and "pages" in t:
            pages = t.get("pages") or []
            full_text_parts = []
            for p in pages:
                part = p.get("text") if isinstance(p, dict) else None
                if part:
                    full_text_parts.append(part)
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
            # już spłaszczony format {"number", "author", "title", "text", ...}
            normalized_texts.append(t)

    return MaturaDbExercise(
        exam_id=exam.id or "",
        question_number=question.number,
        excercise_title=f"Zadanie {question.number}",
        excercise_text=question.text,
        max_points=question.max_points,
        texts=normalized_texts,
    )


@router.post("/matura_db/grade", response_model=MaturaDbGradeResponse)
def grade_matura_db_task(payload: MaturaDbSubmit, ai_service: AIService = Depends(get_ai_service)) -> MaturaDbGradeResponse:
    """
    Ocenia zadanie maturalne na podstawie danych z bazy:
    - pobiera egzamin (teksty) i klucz oceniania do konkretnego zadania
    - przekazuje je jako kontekst do modelu Gemini
    """

    # 1. Pobierz egzamin (teksty) i pytania
    exam = db_manager.get_exam(payload.exam_id)
    if not exam:
        raise HTTPException(status_code=404, detail="Egzamin o podanym ID nie istnieje.")

    questions = db_manager.get_exam_questions(payload.exam_id)
    question = next((q for q in questions if q.number == payload.question_number), None)
    if not question:
        raise HTTPException(status_code=404, detail="Zadanie o podanym numerze nie istnieje dla tego egzaminu.")

    # 2. Pobierz klucz odpowiedzi dla danego zadania
    answers_by_number = db_manager.get_exam_answers(payload.exam_id)
    answer = answers_by_number.get(payload.question_number)
    if not answer:
        raise HTTPException(status_code=404, detail="Brak klucza odpowiedzi dla tego zadania.")

    # 3. Zbuduj kontekst z tekstów egzaminu
    texts = exam.texts or []
    texts_str_parts: list[str] = []
    for t in texts:
        number = t.get("number")
        author = t.get("author")
        title = t.get("title")
        text_body = t.get("text")
        header = f"[TEKST {number}] {author}: {title}" if number is not None else f"[TEKST] {author}: {title}"
        texts_str_parts.append(f"{header}\n{text_body}\n")

    texts_str = "\n\n".join(texts_str_parts) if texts_str_parts else "Brak tekstów źródłowych."

    # 4. Przygotuj prompt dla Gemini
    system_prompt = (
        "Jesteś rygorystycznym egzaminatorem maturalnym języka polskiego. "
        "Oceniasz odpowiedzi zdających wyłącznie na podstawie podanych tekstów źródłowych i oficjalnego klucza oceniania. "
        "Zachowujesz skalę punktacji i kryteria z klucza."
    )

    prompt = (
        "Masz ocenić odpowiedź zdającego na zadanie maturalne.\n\n"
        "TEKSTY EGZAMINACYJNE:\n"
        f"{texts_str}\n\n"
        "ZADANIE:\n"
        f"{question.text}\n\n"
        "OFICJALNY KLUCZ / KRYTERIA OCENY:\n"
        f"{answer.text}\n\n"
        "ODPOWIEDŹ ZDAJĄCEGO:\n"
        f"{payload.user_answer}\n\n"
        "Zadanie ma maksymalnie "
        f"{question.max_points} punktów.\n\n"
        "Zwróć dokładnie dwie części oddzielone separatorem '#GRADE_SEP#':\n"
        "1) liczbę punktów przyznanych zdającemu (np. '2' albo '3').\n"
        "2) szczegółowy feedback dla zdającego, odwołujący się do klucza i tekstów.\n"
    )

    ai_response = ai_service.generate_content(prompt, system_instruction=system_prompt)

    try:
        grade_str, feedback = ai_response.split("#GRADE_SEP#", 1)
        grade_value = float(grade_str.strip().replace(",", "."))
    except Exception:
        # Bezpieczne domyślne wartości przy błędzie parsowania
        grade_value = 0.0
        feedback = f"Nie udało się poprawnie zinterpretować odpowiedzi modelu:\n{ai_response}"

    return MaturaDbGradeResponse(
        exam_id=payload.exam_id,
        question_number=payload.question_number,
        max_points=question.max_points,
        user_answer=payload.user_answer,
        grade=grade_value,
        feedback=feedback.strip(),
        answer_key=answer.text,
    )