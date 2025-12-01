# firestore_manager.py

import firebase_admin
from firebase_admin import credentials, firestore
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime, timezone 

class User(BaseModel):
    city: str
    className: str
    createdAt: datetime
    displayName: str
    email: str
    lastLoginAt: datetime
    notificationFrequency: str
    school: str
    updatedAt: datetime
    id: Optional[str] = Field(None, alias='doc_id')

class UserHistoryEntry(BaseModel):
    type: str
    prompt: str
    response: str
    # Default value set to now 
    date: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    
class UserAllTimeStats(BaseModel):
    current_streak: int
    longest_streak: int
    last_task_date: datetime 
    total_tasks_done: int
    user_id: str 
    id: Optional[str] = Field(None, alias='doc_id')

class School(BaseModel):
    name: str
    city: str
    id: Optional[str] = Field(None, alias='doc_id')

# ====================================================================
# B. CLASS MANAGING CONNECTION TO FIRESTORE (CRUD)
# ====================================================================

class FirestoreManager:
    
    # ⚠️ Zmień tę ścieżkę na ścieżkę do Twojego pliku JSON klucza serwisowego ⚠️
    SERVICE_ACCOUNT_PATH = 'path/to/file' 
    
    def __init__(self):
        self.USERS_COLLECTION = 'users'
        self.STATS_COLLECTION = 'user-all-time-stats'
        self.HISTORY_SUBCOLLECTION = 'history'
        self.SCHOOLS_COLLECTION = 'schools'
        
        try:
            if not firebase_admin._apps:
                cred = credentials.Certificate(self.SERVICE_ACCOUNT_PATH)
                firebase_admin.initialize_app(cred)
            
            self.db = firestore.client()
        except Exception as e:
            self.db = None
            raise RuntimeError(f"Błąd inicjalizacji Firestore: {e}. Sprawdź SERVICE_ACCOUNT_PATH.")

    # ---------------------------------
    # CRUD OPERATIONS FOR 'users'
    # ---------------------------------
    
    # ➕ ADD USER (Create)
    def add_user(self, user_data: User) -> Optional[str]:
        if not self.db: return None
        
        current_time_utc = datetime.now(timezone.utc)
        
        # Convert Pydantic model to a dict, excluding fields that we will overwrite
        data = user_data.model_dump(exclude_none=True, exclude={'id', 'createdAt', 'updatedAt', 'lastLoginAt'})
        
        data['createdAt'] = current_time_utc
        data['updatedAt'] = current_time_utc
        data['lastLoginAt'] = current_time_utc

        try:
            # 1. Create a new empty reference (automatically generates a unique ID)
            new_doc_ref = self.db.collection(self.USERS_COLLECTION).document()
        
            # 2. Use this reference to write the data (SET operation)
            new_doc_ref.set(data)
        
            # 3. Return the ID directly from the reference (safe)
            return new_doc_ref.id
        except Exception as e:
            print(f"❌ Error adding user: {e}")
            return None

    # 🔍 GET USER (Read)
    def get_user(self, user_id: str) -> Optional[User]:
        if not self.db: 
            return None
        try:
            doc = self.db.collection(self.USERS_COLLECTION).document(user_id).get()
            if doc.exists:
                # Firebase SDK automatically converts Timestamp to Python datetime.
                return User(**doc.to_dict(), doc_id=doc.id)
            return None
        except Exception as e:
            print(f"❌ Error reading user: {e}")
            return None

    # ✏️ UPDATE USER (Update)
    def update_user(self, user_id: str, update_data: Dict[str, Any]) -> bool:
        if not self.db: return False
        try:
            # Set updatedAt field to current UTC datetime
            update_data['updatedAt'] = datetime.now(timezone.utc) 
            self.db.collection(self.USERS_COLLECTION).document(user_id).update(update_data)
            return True
        except Exception as e:
            print(f"❌ Error updating user: {e}")
            return False

    # 🗑️ DELETE USER (Delete)
    def delete_user(self, user_id: str) -> bool:
        if not self.db: return False
        try:
            self.db.collection(self.USERS_COLLECTION).document(user_id).delete()
            self.db.collection(self.STATS_COLLECTION).document(user_id).delete()
            return True
        except Exception as e:
            print(f"❌ Error deleting user: {e}")
            return False
            
    # ---------------------------------
    # CRUD OPERATIONS FOR 'user-all-time-stats'
    # ---------------------------------

    # ➕ ADD STATS (Create)
    def add_user_stats(self, stats_data: UserAllTimeStats, doc_id: Optional[str] = None) -> Optional[str]:
        if not self.db: return None
        
        # Ensure last_task_date has UTC timezone set
        if stats_data.last_task_date.tzinfo is None:
             stats_data.last_task_date = stats_data.last_task_date.replace(tzinfo=timezone.utc)
             
        data = stats_data.model_dump(exclude_none=True, exclude={'id'})
        try:
            if doc_id:
                # Use the provided ID (common scenario, e.g. user ID)
                self.db.collection(self.STATS_COLLECTION).document(doc_id).set(data)
                return doc_id
            else:
                # Generate a new unique document ID and use SET
                new_doc_ref = self.db.collection(self.STATS_COLLECTION).document()
                new_doc_ref.set(data)
                return new_doc_ref.id
        except Exception as e:
            print(f"❌ Error adding stats: {e}")
            return None
            
    # 🔍 GET STATS (Read)
    def get_user_stats(self, stat_id: str) -> Optional[UserAllTimeStats]:
        if not self.db: return None
        try:
            doc = self.db.collection(self.STATS_COLLECTION).document(stat_id).get()
            if doc.exists:
                return UserAllTimeStats(**doc.to_dict(), doc_id=doc.id)
            return None
        except Exception as e:
            print(f"❌ Error reading stats: {e}")
            return None

    # ---------------------------------
    # CRUD OPERATIONS FOR 'history' SUBCOLLECTION
    # ---------------------------------

    # ➕ Add History Entry (Create)
    def add_history_entry(self, stat_id: str, entry_data: UserHistoryEntry) -> Optional[str]:
        if not self.db: return None
        data = entry_data.model_dump(exclude_none=True)
        
        try:
            # 1. Get reference to the 'history' subcollection
            history_collection_ref = (self.db.collection(self.STATS_COLLECTION)
                                    .document(stat_id)
                                    .collection(self.HISTORY_SUBCOLLECTION))
            
            # 2. Generate a new document reference (with unique ID) in the subcollection
            new_doc_ref = history_collection_ref.document()
            
            # 3. Use SET on the new reference
            new_doc_ref.set(data)

            # 4. Return ID directly from the reference (safe)
            return new_doc_ref.id
        
        except Exception as e:
            print(f"❌ Error adding history entry: {e}")
            return None

    # 🔍 Get History Entries (Read)
    def get_history_entries(self, stat_id: str) -> List[UserHistoryEntry]:
        if not self.db: return []
        entries = []
        try:
            history_ref = (self.db.collection(self.STATS_COLLECTION)
                                 .document(stat_id)
                                 .collection(self.HISTORY_SUBCOLLECTION))
            
            docs = history_ref.stream() 
            
            for doc in docs:
                entries.append(UserHistoryEntry(**doc.to_dict(), doc_id=doc.id))
            
            return entries
        except Exception as e:
            print(f"❌ Error reading history: {e}")
            return []
            
    # 🗑️ Delete History Entry (Delete)
    def delete_history_entry(self, stat_id: str, history_id: str) -> bool:
        if not self.db: return False
        try:
            (self.db.collection(self.STATS_COLLECTION)
                   .document(stat_id)
                   .collection(self.HISTORY_SUBCOLLECTION)
                   .document(history_id)
                   .delete())
            return True
        except Exception as e:
            print(f"❌ Error deleting history entry: {e}")
            return False

# ---------------------------------
    # OPERATIONS FOR 'schools'
    # ---------------------------------

    # Helper function to generate prefix search range (without lowercasing)
    def _get_prefix_range(self, phrase: str) -> tuple[str, str]:
        """Creates a query range to search prefixes in Firestore (Case-Sensitive)."""
        
        # Search phrase is used WITHOUT converting to lowercase
        start = phrase
        
        # Generate the end of the range. E.g. for 'Wroc' end becomes 'Wrod'
        # This ensures we only find documents that START with 'Wroc'.
        end = start[:-1] + chr(ord(start[-1]) + 1) if start else ' '
        
        return start, end

    # 🔍 1. Search by City (Case-Sensitive Prefix Search)
    def get_schools_by_city(self, city_phrase: str) -> List[School]:
       
        if not self.db or not city_phrase:
            # When phrase is empty, still return everything (or none, depending on expected behavior)
            return self.get_all_schools() 
        
        try:
            start, end = self._get_prefix_range(city_phrase)
            
            query = (self.db.collection(self.SCHOOLS_COLLECTION)
                     .where('City', '>=', start)
                     .where('City', '<', end))
            
            docs = query.stream()
            return [School(**doc.to_dict(), doc_id=doc.id) for doc in docs]
            
        except Exception as e:
            print(f"❌ Error reading schools by city: {e}")
            return []


    # 🔍 2. Search by Name (Case-Sensitive Prefix Search)
    def get_schools_by_name(self, name_phrase: str) -> List[School]:
       
        if not self.db or not name_phrase:
            return self.get_all_schools()
        
        try:
            start, end = self._get_prefix_range(name_phrase)
            
            query = (self.db.collection(self.SCHOOLS_COLLECTION)
                     .where('Name', '>=', start)
                     .where('Name', '<', end))
            
            docs = query.stream()
            return [School(**doc.to_dict(), doc_id=doc.id) for doc in docs]
            
        except Exception as e:
            print(f"❌ Error reading schools by name: {e}")
            return []