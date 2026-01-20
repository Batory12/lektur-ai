from fastapi import APIRouter, Query
from typing import List
from app.schemas import *
from app.db_utils import db_manager

router = APIRouter(tags=["Stats"])

@router.get("/avg_school_scores", response_model=AvgScores)
def get_avg_school_scores(school_name: str, city: str)->AvgScores:
    avg_points, avg_streak = db_manager.avg_scores(school_name, city, None)

    return {"avg_points": avg_points,
            "avg_streak": avg_streak}

@router.get("/avg_class_scores", response_model=AvgScores)
def get_avg_class_scores(school_name: str, city: str, class_name: str)->AvgScores:
    avg_points, avg_streak = db_manager.avg_scores(school_name, city, class_name)

    return {"avg_points": avg_points,
            "avg_streak": avg_streak}

@router.get("/user_stats", response_model=UserAllTimeStats)
def get_user_stats(user_id: str):
    stats: UserAllTimeStats = db_manager.get_user_stats(user_id)

    return stats

#last 30 days
@router.get("/user_daily_stats", response_model= List[UserDailyStats])
def get_user_daily_stats(user_id: str):
    stats: List[UserDailyStats] = db_manager.get_last_30_stats(user_id)

    return stats

@router.get("/avg_school_daily", response_model= List[AvgDailyScores])
def get_school_avg_daily_stats(school_name: str, city: str):
    stats: List[UserDailyStats] = db_manager.get_daily_avg(school_name, city, None)

    return stats

@router.get("/avg_class_daily", response_model= List[AvgDailyScores])
def get_school_avg_daily_stats(school_name: str, city: str, class_name: str):
    stats: List[UserDailyStats] = db_manager.get_daily_avg(school_name, city, class_name)

    return stats