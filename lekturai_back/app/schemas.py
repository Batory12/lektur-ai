from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime, timezone

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
    id: Optional[str] = Field(None, alias='doc_id')

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
    id: Optional[str] = Field(None, alias='doc_id')

class UserAllTimeStats(BaseModel):
    current_streak: int
    longest_streak: int
    last_task_date: datetime 
    total_tasks_done: int
    points: int
    id: Optional[str] = Field(None, alias='doc_id')

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

# --- Exercises (Matura) ---
class MaturaExercise(BaseModel):
    excercise_id: int
    excercise_title: str
    excercise_text: str

class MaturaSubmit(BaseModel):
    user_answer: str

class MaturaGradeResponse(GradeResponse):
    excercise_id: int
    user_answer: str
    answer_key: str

# --- Schools ---
class City(BaseModel):
    name: str

class School(BaseModel):
    name: str
    city: str
    id: Optional[str] = Field(None, alias='doc_id')

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

# --- Search / Context ---
class ContextRequest(BaseModel):
    title: str
    contexts: list[str]

class FoundContext(BaseModel):
    found_context: str
    context_n: int | None = None
    argument: str | None = None

class ReadingChapterInfo(BaseModel):
    n_chapters: int