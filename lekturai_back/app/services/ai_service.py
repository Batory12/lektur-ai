import os

from dotenv import load_dotenv
from fastapi import HTTPException
from google import genai
from google.genai.errors import APIError

load_dotenv()


class AIService:
    def __init__(self):
        self.api_key = os.environ.get("GEMINI_API_KEY")
        if not self.api_key:
            # We don't raise an error here to allow the app to start,
            # but we log a warning.
            print("WARNING: GEMINI_API_KEY not found in environment variables.")
            self.client = None
        else:
            self.client = genai.Client(api_key=self.api_key)

    def generate_content(
        self,
        prompt: str,
        system_instruction: str = None,
        model: str = "gemini-2.5-flash",
    ) -> str:
        """
        Sends a request to the Gemini API and returns the text response.
        """
        if not self.client:
            raise HTTPException(
                status_code=503,
                detail="AI Service is not configured (Missing API Key).",
            )

        try:
            config = {}
            if system_instruction:
                config["system_instruction"] = system_instruction

            response = self.client.models.generate_content(
                model=model, contents=prompt, config=config
            )

            if not response.text:
                raise ValueError("Model returned empty response.")

            return response.text

        except APIError as e:
            print(f"Gemini API Error: {e}")
            raise HTTPException(
                status_code=502, detail="Error communicating with external AI provider."
            )
        except Exception as e:
            print(f"Unexpected AI Error: {e}")
            raise HTTPException(status_code=500, detail="Internal AI Service Error.")


def get_ai_service() -> AIService:
    return AIService()
