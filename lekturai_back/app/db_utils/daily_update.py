# daily_update.py

import os
from datetime import datetime, timedelta, timezone
from typing import List

# Import the manager and schemas from firestore_manager.py
# We assume that file is available for import
from db_service import FirestoreManager, UserAllTimeStats, User

# --- Environment Variables / Configuration ---
# Firestore service key should be loaded
# Make sure SERVICE_ACCOUNT_PATH in FirestoreManager is set correctly
# or use an environment variable for dynamic loading.


def _get_yesterday_utc() -> datetime:
    """Return yesterday's date at midnight (00:00:00) in UTC."""
    # We use UTC because FirestoreManager uses UTC
    today = datetime.now(timezone.utc).date()
    yesterday = datetime(today.year, today.month, today.day, tzinfo=timezone.utc) - timedelta(days=1)
    return yesterday.replace(hour=0, minute=0, second=0, microsecond=0)


def run_daily_update():
    """
    Main daily stats update logic.

    1. Fetch list of all user_ids.
    2. For each user_id:
       a. Check/Create stats profile.
       b. Update streak based on date of last task.
    """
    print(f"--- Starting Daily Stats Update: {datetime.now(timezone.utc)} ---")
    
    try:
        # Initialize Firestore manager
        manager = FirestoreManager()
        
    except RuntimeError as e:
        print(f"CRITICAL ERROR: Unable to initialize FirestoreManager. {e}")
        return

    # FirestoreManager lacks a get_all_users method.
    # We'll use a simple function to fetch all user IDs.
    # For a large application, pagination is recommended.
    try:
        user_docs = manager.db.collection(manager.USERS_COLLECTION).stream()
        all_user_ids: List[str] = [doc.id for doc in user_docs]
    except Exception as e:
        print(f"ERROR: Unable to fetch list of users: {e}")
        return

    yesterday_midnight = _get_yesterday_utc()
    print(f"Processing {len(all_user_ids)} users. Cutoff (yesterday): {yesterday_midnight.date()}")

    for user_id in all_user_ids:
        # 1. Fetch current stats
        stats = manager.get_user_stats(user_id)
        
        # Flag to track if stats were changed
        updated_data = {}
        
        # We must compare only the date (without time) to check if the task was "yesterday"
        last_task_date_only = stats.last_task_date.date()
        yesterday_date_only = yesterday_midnight.date()
        
        # Check if the last task was EXACTLY YESTERDAY
        if last_task_date_only == yesterday_date_only:
            # The streak was already extended (or it was today's date and will be extended the next day)
            # We also check that the streak isn't out of date, meaning:
            # The last task was yesterday, but nothing has been done today (normal).
            pass # Do not modify the streak because it's current; the task was yesterday.
        
        # If the last task was THE DAY BEFORE YESTERDAY or earlier (streak broken)
        elif last_task_date_only < yesterday_date_only:
            # Check whether the task was on any day other than yesterday
            # This means the streak is broken (no task yesterday)
            if stats.current_streak > 0:
                print(f"❌ Streak broken for {user_id}. Reset from {stats.current_streak} to 0.")
                updated_data['current_streak'] = 0
            
        # Save changes to Firestore
        if updated_data:
            manager.db.collection(manager.STATS_COLLECTION).document(user_id).update(updated_data)
            print(f"🛠️ Updated stats for {user_id}: {updated_data}")
            
    print(f"--- Finished Daily Stats Update ---")


if __name__ == "__main__":
    # Run the script (simulate scheduler run)
    # Requires SERVICE_ACCOUNT_PATH to be set in firestore_manager.py
    run_daily_update()