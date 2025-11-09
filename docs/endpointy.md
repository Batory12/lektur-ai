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

# Generacja zadań

/reading\_ex/\[reading\_name : String\]?(to\_chapter : Int) \-\> excercise\_title, excercise\_text  
/exam\_ex \~ w sumie nie wiem jak kategoryzować te zadania na razie

# Asystent rozprawki

/find\_contexts {title : String, List\[context : String\]} \-\> List\[found\_context : String\], List\[context\_n : Int, argument : String\] \~nie wiem o co chodzi z argumentami

# Wyszukiwanie

/autocomplete\_reading?(name\_so\_far : String) \-\> List\[reading\_name : String\] \~ autocomplete do wyszukiwania lektur (patrz: Figma)  
/{reading\_name}/chapters \-\> n\_chapters : Int  
