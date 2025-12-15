from typing import List

from fastapi import APIRouter, Depends, HTTPException

from app.schemas import ContextRequest, FoundContext, ReadingChapterInfo
from app.services.ai_service import AIService, get_ai_service

router = APIRouter(tags=["Search & Assistant"])


@router.post("/contexts", response_model=List[FoundContext])
def find_contexts(
    data: ContextRequest, ai_service: AIService = Depends(get_ai_service)
) -> List[FoundContext]:
    """
    Generuje listę kontekstów do rozprawki na podstawie tytułu i preferencji użytkownika.
    """

    # 1. Construct a dynamic part of the prompt based on the list of requests
    requirements_str = ""
    for i, ctx in enumerate(data.contexts, 1):
        details = (
            ctx.context_additional_description
            if ctx.context_additional_description
            else "Brak dodatkowych wymagań"
        )
        requirements_str += f"{i}. Typ: {ctx.context_type} (Szczegóły: {details})\n"

    # 2. Build the Main Prompt
    # We use explicit separators (||| and ###NEXT###) to make parsing reliable.
    prompt = (
        f"Jesteś pomocnikiem maturzysty. Twoim zadaniem jest znalezienie idealnych kontekstów do rozprawki.\n"
        f"Temat rozprawki: '{data.title}'\n\n"
        f"Użytkownik prosi o znalezienie następujących kontekstów:\n"
        f"{requirements_str}\n"
        "Dla każdego punktu z listy powyżej, znajdź jeden konkretny, najlepiej pasujący przykład.\n"
        "Sformatuj odpowiedź ściśle według wzoru dla każdego kontekstu:\n"
        "[TYP_KONTEKSTU]|||[KONKRETNY_TYTUŁ_LUB_WYDARZENIE]|||[UZASADNIENIE_I_OPIS]\n"
        "Oddziel kolejne konteksty znakiem: ###NEXT###\n\n"
        "Przykład:\n"
        "Literacki|||Dżuma (A. Camus)|||Opisuje postawę lekarza...###NEXT###Historyczny|||Powstanie Warszawskie|||Przykład heroizmu..."
    )

    # 3. Call AI
    ai_response = ai_service.generate_content(prompt)

    # 4. Parse Response
    results = []

    # Split by the "Item Separator"
    raw_items = ai_response.split("###NEXT###")

    for item in raw_items:
        if not item.strip():
            continue

        try:
            # Split by the "Field Separator"
            # We expect 3 parts: Type, Title, Description
            parts = item.strip().split("|||")

            if len(parts) >= 3:
                results.append(
                    FoundContext(
                        context_type=parts[0].strip(),
                        context_title=parts[1].strip(),
                        context_description=parts[2].strip(),
                    )
                )
        except Exception as e:
            print(f"Skipping malformed context item: {item} | Error: {e}")
            continue

    if not results:
        raise HTTPException(
            status_code=500,
            detail="Nie udało się wygenerować kontekstów. Spróbuj sformułować temat inaczej.",
        )

    return results


# --- Remaining endpoints (stubs or simple logic) ---


@router.get("/autocomplete_reading", response_model=List[str])
def autocomplete_reading(name_so_far: str | None = "") -> List[str]:
    # In a real app, this would query a database
    all_readings = [
        "Lalka",
        "Ludzie Bezdomni",
        "Pan Tadeusz",
        "Dziady cz. III",
        "Kordian",
        "Ferdydurke",
    ]
    if not name_so_far:
        return all_readings[:5]

    return [r for r in all_readings if name_so_far.lower() in r.lower()]


@router.get("/{reading_name}/chapters", response_model=ReadingChapterInfo)
def get_chapters_count(reading_name: str) -> ReadingChapterInfo:
    # Logic to return chapter count based on reading name
    # Placeholder logic:
    return ReadingChapterInfo(n_chapters=12)
