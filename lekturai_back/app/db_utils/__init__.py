# database/__init__.py (jeśli tworzysz pakiet)
from .db_service import FirestoreManager

# Globalna instancja, która zostanie utworzona raz przy starcie serwera
db_manager = FirestoreManager()