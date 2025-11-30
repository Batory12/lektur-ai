# firestore_manager.py

import firebase_admin
from firebase_admin import credentials, firestore
from pydantic import BaseModel, Field
from typing import List, Optional, Dict, Any
from datetime import datetime, timezone # Używamy datetime i timezone do obsługi UTC

# ====================================================================
# A. DEKLARACJA MODELI PYDANTIC (daty to datetime)
# ====================================================================

class User(BaseModel):
    city: str
    className: str
    # Daty to obiekty datetime Pythona
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
    # Domyślna wartość ustawiana na teraz, z UTC
    date: datetime = Field(default_factory=lambda: datetime.now(timezone.utc))
    
class UserAllTimeStats(BaseModel):
    current_streak: int
    longest_streak: int
    last_task_date: datetime # Data to obiekt datetime
    total_tasks_done: int
    user_id: str 
    id: Optional[str] = Field(None, alias='doc_id')

# ====================================================================
# B. KLASA ZARZĄDZAJĄCA POŁĄCZENIEM Z FIRESTORE (CRUD)
# ====================================================================

class FirestoreManager:
    
    # ⚠️ Zmień tę ścieżkę na ścieżkę do Twojego pliku JSON klucza serwisowego ⚠️
    SERVICE_ACCOUNT_PATH = 'path/to/file' 
    
    def __init__(self):
        self.USERS_COLLECTION = 'users'
        self.STATS_COLLECTION = 'user-all-time-stats'
        self.HISTORY_SUBCOLLECTION = 'history'
        
        try:
            if not firebase_admin._apps:
                cred = credentials.Certificate(self.SERVICE_ACCOUNT_PATH)
                firebase_admin.initialize_app(cred)
            
            self.db = firestore.client()
        except Exception as e:
            self.db = None
            raise RuntimeError(f"Błąd inicjalizacji Firestore: {e}. Sprawdź SERVICE_ACCOUNT_PATH.")

    # ---------------------------------
    # OPERACJE CRUD DLA 'users'
    # ---------------------------------
    
    # ➕ DODAWANIE UŻYTKOWNIKA (Create)
    def add_user(self, user_data: User) -> Optional[str]:
        if not self.db: return None
        
        # Używamy UTC (wymagane dla poprawnej serializacji przez Firebase SDK)
        current_time_utc = datetime.now(timezone.utc)
        
        # Konwersja Pydantic na słownik, wykluczenie pól, które nadpiszemy
        data = user_data.model_dump(exclude_none=True, exclude={'id', 'createdAt', 'updatedAt', 'lastLoginAt'})
        
        # Ustawiamy pola daty na aktualny datetime UTC
        data['createdAt'] = current_time_utc
        data['updatedAt'] = current_time_utc
        data['lastLoginAt'] = current_time_utc

        try:
            # 1. Tworzymy nową, pustą referencję (automatycznie generuje unikalne ID)
            new_doc_ref = self.db.collection(self.USERS_COLLECTION).document()
        
            # 2. Używamy tej referencji do zapisania danych (operacja SET)
            new_doc_ref.set(data)
        
            # 3. Zwracamy ID bezpośrednio z referencji (bezpieczne)
            return new_doc_ref.id
        except Exception as e:
            print(f"❌ Błąd dodawania użytkownika: {e}")
            return None

    # 🔍 POBIERANIE UŻYTKOWNIKA (Read)
    def get_user(self, user_id: str) -> Optional[User]:
        if not self.db: return None
        try:
            doc = self.db.collection(self.USERS_COLLECTION).document(user_id).get()
            if doc.exists:
                # Firebase SDK automatycznie konwertuje Timestamp na Python datetime.
                return User(**doc.to_dict(), doc_id=doc.id)
            return None
        except Exception as e:
            print(f"❌ Błąd odczytu użytkownika: {e}")
            return None

    # ✏️ AKTUALIZACJA UŻYTKOWNIKA (Update)
    def update_user(self, user_id: str, update_data: Dict[str, Any]) -> bool:
        if not self.db: return False
        try:
            # Ustawiamy pole updatedAt na aktualny datetime UTC
            update_data['updatedAt'] = datetime.now(timezone.utc) 
            self.db.collection(self.USERS_COLLECTION).document(user_id).update(update_data)
            return True
        except Exception as e:
            print(f"❌ Błąd aktualizacji użytkownika: {e}")
            return False

    # 🗑️ USUWANIE UŻYTKOWNIKA (Delete)
    def delete_user(self, user_id: str) -> bool:
        if not self.db: return False
        try:
            self.db.collection(self.USERS_COLLECTION).document(user_id).delete()
            self.db.collection(self.STATS_COLLECTION).document(user_id).delete()
            return True
        except Exception as e:
            print(f"❌ Błąd usuwania użytkownika: {e}")
            return False
            
    # ---------------------------------
    # OPERACJE CRUD DLA 'user-all-time-stats'
    # ---------------------------------

    # ➕ DODAWANIE STATYSTYK (Create)
    def add_user_stats(self, stats_data: UserAllTimeStats, doc_id: Optional[str] = None) -> Optional[str]:
        if not self.db: return None
        
        # Upewnienie się, że last_task_date ma ustawiony UTC
        if stats_data.last_task_date.tzinfo is None:
             stats_data.last_task_date = stats_data.last_task_date.replace(tzinfo=timezone.utc)
             
        data = stats_data.model_dump(exclude_none=True, exclude={'id'})
        try:
            if doc_id:
                # Używamy podanego ID (najczęstszy scenariusz, np. ID użytkownika)
                self.db.collection(self.STATS_COLLECTION).document(doc_id).set(data)
                return doc_id
            else:
                # Generujemy nowe, unikalne ID dokumentu i używamy metody SET
                new_doc_ref = self.db.collection(self.STATS_COLLECTION).document()
                new_doc_ref.set(data)
                return new_doc_ref.id
        except Exception as e:
            print(f"❌ Błąd dodawania statystyk: {e}")
            return None
            
    # 🔍 POBIERANIE STATYSTYK (Read)
    def get_user_stats(self, stat_id: str) -> Optional[UserAllTimeStats]:
        if not self.db: return None
        try:
            doc = self.db.collection(self.STATS_COLLECTION).document(stat_id).get()
            if doc.exists:
                return UserAllTimeStats(**doc.to_dict(), doc_id=doc.id)
            return None
        except Exception as e:
            print(f"❌ Błąd odczytu statystyk: {e}")
            return None

    # ---------------------------------
    # OPERACJE CRUD DLA PODKOLEKCJI 'history'
    # ---------------------------------

    # ➕ Dodawanie Historii (Create)
    def add_history_entry(self, stat_id: str, entry_data: UserHistoryEntry) -> Optional[str]:
        if not self.db: return None
        data = entry_data.model_dump(exclude_none=True)
        
        try:
            # 1. Uzyskujemy referencję do podkolekcji 'history'
            history_collection_ref = (self.db.collection(self.STATS_COLLECTION)
                                    .document(stat_id)
                                    .collection(self.HISTORY_SUBCOLLECTION))
            
            # 2. Generujemy nową referencję dokumentu (z unikalnym ID) w podkolekcji
            new_doc_ref = history_collection_ref.document()
            
            # 3. Używamy metody SET na nowej referencji
            new_doc_ref.set(data)

            # 4. Zwracamy ID bezpośrednio z referencji (bezpieczne)
            return new_doc_ref.id
        
        except Exception as e:
            print(f"❌ Błąd dodawania wpisu historycznego: {e}")
            return None

    # 🔍 Wyświetlanie Historii (Read)
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
            print(f"❌ Błąd odczytu historii: {e}")
            return []
            
    # 🗑️ Usuwanie Historii (Delete)
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
            print(f"❌ Błąd usuwania wpisu historycznego: {e}")
            return False