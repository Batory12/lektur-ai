from __future__ import annotations

from typing import Optional, List

from pydantic import BaseModel, Field


class Exam(BaseModel):
    """
    Logical DB schema for an exam.

    Relationships:
    - Many-to-many with Question (via ExamQuestionLink)
    """

    id: Optional[str] = Field(default=None, alias="doc_id")
    # e.g. "Matura język polski 2025 maj – poziom podstawowy"
    title: str
    description: Optional[str] = None
    # Raw texts/tasks structure as extracted from PDF (optional, you can also store texts separately)
    texts: Optional[List[dict]] = None
    tasks: Optional[List[dict]] = None


class Question(BaseModel):
    """
    Logical DB schema for a question.

    Relationships:
    - Many-to-many with Exam (via ExamQuestionLink)
    - One-to-one with Answer (Answer.question_id is unique)
    """

    id: Optional[str] = Field(default=None, alias="doc_id")
    # Number from extracted_tasks.json -> "number"
    number: int
    # Max points from extracted_tasks.json -> "max_points"
    max_points: int
    # Question text from extracted_tasks.json -> "question"
    text: str


class Answer(BaseModel):
    """
    Logical DB schema for an answer.

    Relationships:
    - One-to-one with Question (question_id is both FK and unique)
    """

    id: Optional[str] = Field(default=None, alias="doc_id")
    # Logical link to Question.number (not to Firestore doc id),
    # because extracted_answers.json uses "Zadanie X" rather than raw number.
    question_number: int
    # Full answer key / grading criteria from extracted_answers.json -> "answer"
    text: str


class ExamQuestionLink(BaseModel):
    """
    Join entity implementing the many-to-many relationship
    between Exam and Question.
    """

    id: Optional[str] = Field(default=None, alias="doc_id")
    exam_id: str
    question_id: str
    order: Optional[int] = None


