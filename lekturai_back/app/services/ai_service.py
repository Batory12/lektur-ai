import logging
import os

from dotenv import load_dotenv
from fastapi import HTTPException
from google import genai
from google.genai.errors import APIError, ClientError, ServerError

# Importy Tenacity
from tenacity import (
    before_sleep_log,
    retry,
    retry_if_exception_type,
    stop_after_attempt,
    wait_exponential,
)

load_dotenv()

# Konfiguracja loggera, aby widzieć, kiedy Tenacity ponawia próbę
logger = logging.getLogger("uvicorn.error")


class AIService:
    def __init__(self):
        self.api_key = os.environ.get("GEMINI_API_KEY")
        if not self.api_key:
            print("WARNING: GEMINI_API_KEY not found in environment variables.")
            self.client = None
        else:
            self.client = genai.Client(api_key=self.api_key)

    @retry(
        retry=retry_if_exception_type((ServerError, APIError)),
        wait=wait_exponential(multiplier=1, min=1, max=10),
        stop=stop_after_attempt(5),
        before_sleep=before_sleep_log(logger, logging.WARNING),
        reraise=True,
    )
    def _send_request_safe(self, model: str, contents: str, config: dict):
        """
        Wewnętrzna metoda wykonująca surowe zapytanie do API.
        To tutaj dzieje się magia ponawiania prób przez Tenacity.
        """
        return self.client.models.generate_content(
            model=model, contents=contents, config=config
        )

    def generate_content(
        self,
        prompt: str,
        system_instruction: str = None,
        model: str = "gemini-2.5-flash",
    ) -> str:
        """
        Publiczna metoda wywoływana przez API.
        Obsługuje błędy ostateczne (gdy retry zawiedzie).
        """
        if not self.client:
            raise HTTPException(
                status_code=503,
                detail="AI Service is not configured (Missing API Key).",
            )

        config = {}
        if system_instruction:
            config["system_instruction"] = system_instruction

        try:
            response = self._send_request_safe(model, prompt, config)

            if not response.text:
                raise ValueError(
                    "Model returned empty response (possibly safety filter)."
                )

            return response.text

        except (APIError, ServerError) as e:
            # Wykona się dopiero, gdy Tenacity zużyje wszystkie 5 prób
            logger.error(f"Gemini API Critical Failure after retries: {e}")
            raise HTTPException(
                status_code=502,
                detail=f"External AI provider unavailable after retries. Error: {str(e)}",
            )
        except ClientError as e:
            # Błędy 4xx (złe zapytanie) - nie chcemy tego ponawiać
            logger.error(f"Gemini Client Error (Bad Request): {e}")
            raise HTTPException(status_code=400, detail=f"Invalid AI Request: {str(e)}")
        except Exception as e:
            logger.error(f"Unexpected AI Service Error: {e}")
            raise HTTPException(status_code=500, detail="Internal AI Service Error.")


def get_ai_service() -> AIService:
    return AIService()
