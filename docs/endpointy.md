# Endpoint

# Format w tym dokumencie

/ścieżka/\[argument w ścieżce : typ\]/ścieżka dalej?(query arg 1 : typ, query arg 2\) {body arg 1 : typ, body arg 2} \-\> zwracane rzeczy

# Logowanie

/login {username: String, password: String} \-\> JWT

# JWT

JWT powinien zawierać informacje jednoznacznie identyfikujące użytkownika, żeby nie wysyłać ich w każdym requeście osobno

# Historia, statystyki

/readings\_history?(dayfrom : datetime, dayto : datetime) \-\> List\[eval\_summary, eval\] \~może eval\_points? nwm  
/exercise\_history \~ podobnie

# Generacja zadań z lektur

/reading\_ex/\[reading\_name : String\]?(to\_chapter : Int) \-\> excercise\_title, excercise\_text  
/exam\_ex \~ w sumie nie wiem jak kategoryzować te zadania na razie

# Rozwiązywanie zadań maturalnych
### GET /matura_ex 
-> Zwraca losowe zadanie maturalne w formacie
{excercise_id: Int, excercise_title: String, excercise_text: String}

### POST /matura_ex
#### Request Body:
{
    excercise_id: Int,
    user_answer: String
}
#### Response
{
    excercise_id: Int,
    user_answer: String,
    grade: Float,
    feedback: String,
    answer_key: String
}

# Asystent rozprawki

/find\_contexts {title : String, List\[context : String\]} \-\> List\[found\_context : String\], List\[context\_n : Int, argument : String\] \~nie wiem o co chodzi z argumentami

# Wyszukiwanie

/autocomplete\_reading?(name\_so\_far : String) \-\> List\[reading\_name : String\] \~ autocomplete do wyszukiwania lektur (patrz: Figma)  
/{reading\_name}/chapters \-\> n\_chapters : Int  
