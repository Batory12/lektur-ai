from fastapi import APIRouter
from app.schemas import City, School, SchoolAssign, ClassAssign

router = APIRouter(tags=["Schools & Classes"])

@router.get("/cities", response_model=list[City])
def autocomplete_cities(name_so_far: str | None = "") -> list[City]:
    return [City(name="Warszawa"), City(name="Wrocław")]

@router.get("/schools", response_model=list[School])
def get_schools(city: str) -> list[School]:
    return [
        School(school_id=1, school_name="LO nr 1"),
        School(school_id=2, school_name="Technikum nr 5")
    ]

@router.post("/schools")
def assign_user_to_school(data: SchoolAssign) -> dict[str, str | int]:
    return {"status": "assigned", "school_id": data.school_id}

@router.post("/class")
def assign_user_to_class(data: ClassAssign) -> dict[str, str]:
    return {"status": "assigned", "class": data.classname}