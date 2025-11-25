from ollama import chat, generate

from fastapi import APIRouter, Request
router = APIRouter(prefix="/api")

@router.post("/reading_ex")
async def evaluate_reading_exercise(request: Request):
    data = await request.json()
    student_answer = data.get("student_answer", "")
    
    prompt = f"""
    You are an expert language model evaluator. Evaluate the following student's answer for grammar, coherence, and relevance to the topic.

    Student's Answer:
    {student_answer}

    Provide a score from 1 to 10 and a brief explanation for your score.
    """

    response = chat(model="deepseek", messages=[{"role": "user", "content": prompt}])
    
    return {"evaluation": response}
