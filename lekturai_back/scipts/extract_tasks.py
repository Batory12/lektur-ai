import json
import os
from llama_cloud_services import LlamaExtract
from llama_cloud.core.api_error import ApiError
from pydantic import BaseModel, Field

class Task(BaseModel):
    number: int = Field(description="Numer zadania")
    max_points: int = Field(description="Maksymalna liczba punktów za zadanie")
    question: str = Field(description="Treść zadania")
class Text(BaseModel):
    number: int = Field(description="Numer tekstu")
    author: str = Field(description="Autor tekstu")
    title: str = Field(description="Tytuł tekstu")
    text: str = Field(description="Treść tekstu")
class Exam(BaseModel):
    texts: list[Text] = Field(description="Lista tekstów")
    tasks: list[Task] = Field(description="Lista zadań")
llama_extract = LlamaExtract()

try:
    existing_agent = llama_extract.get_agent(name="tasks-extractor")
    if existing_agent:
        llama_extract.delete_agent(existing_agent.id)
except ApiError as e:
    if e.status_code == 404:
        pass
    else:
        raise

agent = llama_extract.create_agent(name="tasks-extractor",data_schema=Exam)

file = "/home/bartek/repos/lektur-ai/matury/jezyk-polski-2025-maj-matura-podstawowa.pdf"

with open("extracted_tasks.json", "w") as f:
    json.dump(agent.extract(file).data, f, indent=4)