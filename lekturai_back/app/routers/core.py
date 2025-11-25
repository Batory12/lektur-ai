from ollama import chat, generate

from fastapi import APIRouter, Request
import logging
import json
router = APIRouter(prefix="/api")

@router.post("/reading_ex")
async def evaluate_reading_exercise(request: Request):
    data = await request.json()
    student_answer = data.get("student_answer", "")
    
    prompt = f"""
    Jesteś ekspertem w ocenie odpowiedzi językowych. Oceń poniższą odpowiedź ucznia pod względem gramatyki, spójności i zgodności z tematem.

    Odpowiedź ucznia:
    {student_answer}

    Podaj ocenę w skali od 1 do 10 oraz krótkie uzasadnienie swojej oceny. Odpowiedz w formacie JSON:
    {{
        "score": <ocena>,
        "justification": "<uzasadnienie>",
        "suggestions": "<sugestie poprawy>",
        "errors": "<wykryte błędy>"
    }}
    {{
    """

    response = chat(model="deepseek-r1:1.5b", messages=[{"role": "user", "content": prompt}])
    logging.info("Odpowiedź modelu:", response["message"].content)
    try:
        # Extract the JSON part from the response content
        response_content = response["message"].content
        json_start = response_content.find("{")
        json_end = response_content.rfind("}") + 1
        if json_start == -1 or json_end == -1:
            raise ValueError("JSON not found in the response content")
        response_json = response_content[json_start:json_end]
        evaluation = json.loads(response_json)
        response_content = response["message"].content
        evaluation = json.loads(response_content)
    except (json.JSONDecodeError, KeyError) as e:
        logging.error("Failed to parse JSON response: %s", e)
        evaluation = {"error": "Invalid response format"}

    return {"evaluation": evaluation}
