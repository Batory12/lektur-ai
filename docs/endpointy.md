# Endpoint

# Format w tym dokumencie

/ścieżka/\[argument w ścieżce : typ\]/ścieżka dalej?(query arg 1 : typ, query arg 2\) {body arg 1 : typ, body arg 2} \-\> zwracane rzeczy

# Logowanie

/login {username: String, password: String} \-\> JWT

# JWT

JWT powinien zawierać informacje jednoznacznie identyfikujące użytkownika, żeby nie wysyłać ich w każdym requeście osobno

# Historia, statystyki

### GET /readings_question_history?(sortby : string, from : int, to : int) 
możliwe wartości sortby : {"recent", "best_eval", "worst_eval"} (można dorobić więcej)
response -> List[question_title, question, answer, eval_summary, eval, submit_time : datetime] ~może eval_points? nwm  
### GET /exercise_history ~ podobnie

### GET /recent_questions ~ być może niepotrzebne

response -> array of questions{
    type: String ("reading", "matura", "otwarte", "zamkniete"),
    title: String,
    description: String,
    user_answer: String,
    feedback: String,
    grade: Float
}

# Generacja zadań z lektur

/reading\_ex/\[reading\_name : String\]?(to\_chapter : Int) \-\> excercise\_title, excercise\_text  
/exam\_ex \~ w sumie nie wiem jak kategoryzować te zadania na razie

### Ocenianie zadania z lektury POST /reading_ex
{
    excercise_title: String,
    excercise_text: String,
    user_answer: String
}
#### Response
{
    grade: float,
    feedback: String
}

# Rozwiązywanie zadań maturalnych
### GET /matura_ex 
-> Zwraca losowe zadanie maturalne w formacie
{excercise_id: Int, excercise_title: String, excercise_text: String}

### POST /matura_ex/:[excercise_id: Int]
#### Request Body:
{
    user_answer: String
}
#### Response
{
    excercise_id: Int,
    user_answer: String,
    grade: Float,
    feedback: String,
    answer_key: String // klucz odpowiedzi maturalny
}

# Lista szkół, klas
User najpierw wybiera Miejscowość w której jest jego szkoła
## GET /cities?(name_so_far: String) -> List<City>
Podpowiadanie wyboru miejscowości szkoły

## GET /schools?(city: String) -> List<School>
Zwraca listę szkół, gdzie każda szkoła ma format:
{
    school_id: Int,
    school_name: String
}
## POST /schools
{
    school_id: Int
}
Zapisanie danego użytkownika do danej szkoły. school_id w query parameter.

## POST /class
{
    classname: String
}
Przypisuje ucznia do danej klasy jeśli ma wybraną szkołę.
Np klasa 4a.


# Asystent rozprawki

### GET /contexts
{
    title: String // tytuł rozprawki,
    contexts: [
        context_type: String // historyczny, literacki, artystyczny itp -> zobacz docs/rozprawka.md
        context_additional_description: String // user może dopisać jakieś swoje preferencje - na przykład dla kontekstu historycznego może dopisać, że chce coś z II wojny światowej
    ]
}
Response -> {
    contexts: [
        context_type: String,
        context_title: String,
        context_description: String // tutaj mógłby być jakiś argument, uzasadnienie, dlaczego to pasuje i jak tego użyć. 
    ]
}

# Wyszukiwanie

/autocomplete\_reading?(name\_so\_far : String) \-\> List\[reading\_name : String\] \~ autocomplete do wyszukiwania lektur (patrz: Figma)  
/{reading\_name}/chapters \-\> n\_chapters : Int  
