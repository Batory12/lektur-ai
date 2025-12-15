import json
import os
from llama_cloud_services import LlamaExtract
from llama_cloud.core.api_error import ApiError
from pydantic import BaseModel, Field

class Answer(BaseModel):
    question: int = Field(description="Numer zadania")
    answer: str = Field(description="Kryteria oceny, klucz odpowiedzi, przykładowe odpowiedzi, etc.")
class AnswerSheet(BaseModel):
    answers: list[Answer] = Field(description="Lista odpowiedzi")
llama_extract = LlamaExtract()
try:
    existing_agent = llama_extract.get_agent(name="answers-extractor")
    if existing_agent:
        llama_extract.delete_agent(existing_agent.id)
except ApiError as e:
    if e.status_code == 404:
        pass
    else:
        raise

agent = llama_extract.create_agent(name="answers-extractor",data_schema=AnswerSheet)

file = "/home/bartek/repos/lektur-ai/rozwiązania/jezyk-polski-2025-maj-matura-podstawowa-odpowiedzi.pdf"

with open("extracted_answers.json", "w") as f:
    json.dump(agent.extract(file).data, f, indent=4) 