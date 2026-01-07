import logging
import os

import requests
from dotenv import load_dotenv
from fastapi import HTTPException

load_dotenv()

logger = logging.getLogger("uvicorn.error")


class SaplingService:
    """Service for detecting AI-generated text using Sapling AI API."""

    def __init__(self):
        self.api_key = os.environ.get("SAPLING_API_KEY")
        self.api_url = "https://api.sapling.ai/api/v1/aidetect"
        if not self.api_key:
            logger.warning("SAPLING_API_KEY not found in environment variables. AI detection will be disabled.")

    def detect_ai_text(self, text: str) -> float | None:
        """
        Detect if text is AI-generated using Sapling AI API.
        
        Args:
            text: The text to analyze
            
        Returns:
            Probability score (0.0 to 1.0) that text is AI-generated, or None if detection fails
        """
        if not self.api_key:
            logger.warning("SAPLING_API_KEY not configured. Skipping AI detection.")
            return None

        if not text or not text.strip():
            logger.warning("Empty text provided for AI detection.")
            return None

        try:
            response = requests.post(
                self.api_url,
                json={
                    "key": self.api_key,
                    "text": text,
                },
                timeout=10,  # 10 second timeout
            )

            if 200 <= response.status_code < 300:
                result = response.json()
                score = result.get("score", None)
                if score is not None:
                    return float(score)
                else:
                    logger.warning(f"Sapling API response missing 'score' field: {result}")
                    return None
            else:
                logger.error(
                    f"Sapling API error: status_code={response.status_code}, "
                    f"response={response.text}"
                )
                return None

        except requests.exceptions.Timeout:
            logger.error("Sapling API request timed out.")
            return None
        except requests.exceptions.RequestException as e:
            logger.error(f"Sapling API request failed: {e}")
            return None
        except (ValueError, KeyError) as e:
            logger.error(f"Error parsing Sapling API response: {e}")
            return None
        except Exception as e:
            logger.error(f"Unexpected error in Sapling AI detection: {e}")
            return None


def get_sapling_service() -> SaplingService:
    return SaplingService()

