from datetime import datetime, timezone
from typing import Optional

from pydantic import BaseModel, Field


# --- Auth ---
class LoginRequest(BaseModel):
    username: str
    password: str


class Token(BaseModel):
    access_token: str
    token_type: str


# --- History ---
class RecentQuestion(BaseModel):
    type: str
    title: str
    description: str
    user_answer: str
    feedback: str
    grade: float


class UserHistoryEntry(BaseModel):
    type: str
    question: str
    response: str
    eval: str
    points: int
    # Default value set to now
    date: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    id: Optional[str] = Field(None, alias="doc_id")


# USER
class User(BaseModel):
    city: str
    className: str
    createdAt: datetime
    displayName: str
    email: str
    lastLoginAt: datetime
    notificationFrequency: str
    school: str
    updatedAt: datetime
    id: Optional[str] = Field(None, alias="doc_id")


# --- STATS ---
class UserAllTimeStats(BaseModel):
    current_streak: int
    longest_streak: int
    last_task_date: datetime
    total_tasks_done: int
    points: int
    id: Optional[str] = Field(None, alias="doc_id")


class AvgScores(BaseModel):
    avg_points: float
    avg_streak: float

class UserDailyStats(BaseModel):
    points: int
    id: Optional[str] = Field(None, alias="doc_id")

class AvgDailyScores(BaseModel):
    avg_points: float

# --- Exercises (Lektury) ---
class ReadingExerciseGen(BaseModel):
    excercise_title: str
    excercise_text: str


class ReadingExerciseSubmit(BaseModel):
    excercise_title: str
    excercise_text: str
    user_answer: str


class GradeResponse(BaseModel):
    grade: float
    feedback: str
    ai_detection_score: float | None = None


# --- Exercises (Matura) ---
class MaturaExercise(BaseModel):
    excercise_id: str
    excercise_title: str
    excercise_text: str
    max_points: int
    texts: list[dict] = []


class MaturaSubmit(BaseModel):
    user_answer: str


class MaturaGradeResponse(BaseModel):
    excercise_id: str
    user_answer: str
    grade: float
    feedback: str
    answer_key: str
    ai_detection_score: float | None = None
#    max_points: int


# --- Schools ---
class City(BaseModel):
    name: str


class School(BaseModel):
    name: str
    city: str
    id: Optional[str] = Field(None, alias="doc_id")


class SchoolAssign(BaseModel):
    school_id: int


class ClassAssign(BaseModel):
    classname: str


# --- Chat ---
class ChatMessage(BaseModel):
    message: str


class ChatResponse(BaseModel):
    conversation_id: int
    message: str


class Context(BaseModel):
    context_type: str
    context_additional_description: str


# --- Search / Context ---
class ContextQuery(BaseModel):
    context_type: str
    context_additional_description: Optional[str] = None


class ContextRequest(BaseModel):
    title: str
    contexts: list[ContextQuery]


class FoundContext(BaseModel):
    context_type: str
    context_title: str
    context_description: str


class ReadingChapterInfo(BaseModel):
    n_chapters: int
