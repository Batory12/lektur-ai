from pydantic import BaseModel
from datetime import datetime

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

class HistoryEntry(BaseModel):
    date: datetime
    summary: str
    points: int

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
    school_id: int
    school_name: str

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
class ContextRequest(BaseModel):
    title: str
    contexts: list[Context]

class FoundContext(BaseModel):
    found_context: str
    context_n: int | None = None
    argument: str | None = None



class ReadingChapterInfo(BaseModel):
    n_chapters: int