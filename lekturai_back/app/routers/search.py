from fastapi import APIRouter
from app.schemas import ReadingChapterInfo, ContextRequest, FoundContext

router = APIRouter(tags=["Search & Assistant"])

@router.post("/find_contexts", response_model=list[FoundContext])
def find_contexts(data: ContextRequest) -> list[FoundContext]:
    return [
        FoundContext(
            context_type=data.contexts[0].context_type,
            context_title="Lalka to argument na wszystko",
            context_description="Lalka Bolesława Prusa to powieść realistyczna..."
        )
    ]

@router.get("/autocomplete_reading", response_model=list[str])
def autocomplete_reading(name_so_far: str | None = "") -> list[str]:
    return ["Lalka", "Ludzie Bezdomni", "Pan Tadeusz"]

@router.get("/{reading_name}/chapters", response_model=ReadingChapterInfo)
def get_chapters_count(reading_name: str) -> ReadingChapterInfo:
    return ReadingChapterInfo(n_chapters=12)