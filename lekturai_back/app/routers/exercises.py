from fastapi import APIRouter
from app.db_utils import db_manager
from app.schemas import (
    ReadingExerciseGen, ReadingExerciseSubmit, GradeResponse,
    MaturaExercise, MaturaSubmit, MaturaGradeResponse
)

router = APIRouter(tags=["Exercises"])

# --- Lektury ---
@router.get("/reading_ex/{reading_name}", response_model=ReadingExerciseGen)
def generate_reading_exercise(reading_name: str, to_chapter: int | None = None) -> ReadingExerciseGen:
    return ReadingExerciseGen(
        excercise_title=f"Zadanie z: {reading_name}",
        excercise_text="Opisz zachowanie bohatera w rozdziale..."
    )

@router.post("/reading_ex", response_model=GradeResponse)
def grade_reading_exercise(submission: ReadingExerciseSubmit) -> GradeResponse:
    #need user id input
    db_manager.update_stats_after_ex('user_name', 10)
    return GradeResponse(grade=5.0, feedback="Świetna analiza.")

# --- Matura ---
@router.get("/matura_ex", response_model=MaturaExercise)
def get_random_matura_task() -> MaturaExercise:
    return MaturaExercise(
        excercise_id=101,
        excercise_title="Rozprawka",
        excercise_text="Czy praca uszlachetnia? Rozważ na podstawie Lalki."
    )

@router.post("/matura_ex/{excercise_id}", response_model=MaturaGradeResponse)
def solve_matura_task(excercise_id: int, submission: MaturaSubmit) -> MaturaGradeResponse:
    #need user id input
    db_manager.update_stats_after_ex('user_name', 2)
    return MaturaGradeResponse(
        excercise_id=excercise_id,
        user_answer=submission.user_answer,
        grade=3.5,
        feedback="Zbyt krótka odpowiedź.",
        answer_key="Przykładowa teza: Praca jest sensem życia Wokulskiego...",
    )