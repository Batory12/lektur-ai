# daily_update.py

import os
from datetime import datetime, timedelta, timezone
from typing import List

# Importujemy menedżera i schematy z firestore_manager.py
# Zakładamy, że ten plik jest dostępny do importu
from db_service import FirestoreManager, UserAllTimeStats, User

# --- Zmienne Środowiskowe / Konfiguracja ---
# Klucz serwisowy dla Firestore powinien być załadowany
# Upewnij się, że SERVICE_ACCOUNT_PATH w FirestoreManager jest poprawnie ustawiony
# lub użyj zmiennej środowiskowej do jego dynamicznego ładowania.


def _get_yesterday_utc() -> datetime:
    """Zwraca datę wczorajszego dnia o północy (00:00:00) w strefie UTC."""
    # Używamy UTC, ponieważ FirestoreManager używa UTC
    today = datetime.now(timezone.utc).date()
    yesterday = datetime(today.year, today.month, today.day, tzinfo=timezone.utc) - timedelta(days=1)
    return yesterday.replace(hour=0, minute=0, second=0, microsecond=0)


def run_daily_update():
    """
    Główna funkcja logiki codziennej aktualizacji statystyk.
    
    1. Pobiera listę wszystkich user_id.
    2. Dla każdego user_id:
       a. Sprawdza/Tworzy profil statystyk.
       b. Aktualizuje serię (streak) na podstawie daty ostatniego zadania.
    """
    print(f"--- Uruchomienie Codziennej Aktualizacji Statystyk: {datetime.now(timezone.utc)} ---")
    
    try:
        # Inicjalizacja menedżera Firestore
        manager = FirestoreManager()
        
    except RuntimeError as e:
        print(f"BŁĄD KRYTYCZNY: Nie można zainicjalizować FirestoreManager. {e}")
        return

    # W FirestoreManager brakuje metody get_all_users.
    # Użyjemy prostej funkcji do pobrania wszystkich ID użytkowników.
    # W dużej aplikacji zalecany jest mechanizm paginacji.
    try:
        user_docs = manager.db.collection(manager.USERS_COLLECTION).stream()
        all_user_ids: List[str] = [doc.id for doc in user_docs]
    except Exception as e:
        print(f"BŁĄD: Nie można pobrać listy użytkowników: {e}")
        return

    yesterday_midnight = _get_yesterday_utc()
    print(f"Przetwarzam {len(all_user_ids)} użytkowników. Graniczna data wczoraj: {yesterday_midnight.date()}")

    for user_id in all_user_ids:
        # 1. Pobierz obecne statystyki
        stats = manager.get_user_stats(user_id)
        
        # Flaga do śledzenia, czy statystyki zostały zmienione
        updated_data = {}
        
        # Jeśli stats nie istnieją, tworzymy nowy profil (Krok 1)
        if stats is None:
            # Tworzenie nowego profilu statystyk (założenie, że user_id będzie też ID dokumentu statystyk)
            new_stats = UserAllTimeStats(
                current_streak=0,
                longest_streak=0,
                last_task_date=datetime(1970, 1, 1, tzinfo=timezone.utc), # Bardzo stara data jako domyślna
                total_tasks_done=0,
                user_id=user_id
            )
            # Używamy user_id jako doc_id, zgodnie z ustaloną logiką
            manager.add_user_stats(new_stats, doc_id=user_id)
            stats = new_stats
            print(f"✅ Utworzono nowy profil statystyk dla użytkownika: {user_id}")
            # Pomijamy dalszą aktualizację streaka, ponieważ jest to nowo utworzony profil.
            continue 

        # 2. Sprawdzenie streaka
        
        # Musimy porównywać tylko datę (bez godziny), aby sprawdzić, czy zadanie było "wczoraj"
        last_task_date_only = stats.last_task_date.date()
        yesterday_date_only = yesterday_midnight.date()
        
        # Sprawdzamy, czy ostatnie zadanie było WŁAŚNIE WCZORAJ
        if last_task_date_only == yesterday_date_only:
            # Seria została już przedłużona (lub była to data dzisiejsza i zostanie przedłużona następnego dnia)
            # Sprawdzamy jednak, czy seria już nie jest aktualna, to znaczy:
            # Ostatnie zadanie było wczoraj, ale dzisiaj jeszcze nic nie zrobiono (normalne).
            pass # Nie ruszamy streaka, bo jest aktualny, zadanie było wczoraj.
        
        # Jeśli ostatnie zadanie było PRZEDWCZORAJ lub wcześniej (streak przerwany)
        elif last_task_date_only < yesterday_date_only:
            # Sprawdzamy, czy zadanie było w jakikolwiek inny dzień niż wczoraj
            # Oznacza to, że streak jest przerwany (brak zadania wczoraj)
            if stats.current_streak > 0:
                print(f"❌ Seria przerwana dla {user_id}. Reset z {stats.current_streak} do 0.")
                updated_data['current_streak'] = 0
            
        # Zapisanie zmian w Firestorze
        if updated_data:
            manager.db.collection(manager.STATS_COLLECTION).document(user_id).update(updated_data)
            print(f"🛠️ Zaktualizowano statystyki dla {user_id}: {updated_data}")
            
    print(f"--- Zakończenie Codziennej Aktualizacji Statystyk ---")


if __name__ == "__main__":
    # Uruchomienie skryptu (symulacja uruchomienia przez scheduler)
    # Wymaga ustawienia SERVICE_ACCOUNT_PATH w firestore_manager.py
    run_daily_update()