import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:lekturai_front/services/profile_service.dart';
import 'api_config.dart';

class Context {
  final String contextType;
  final String contextTitle;
  final String contextDescription;

  Context({
    required this.contextType,
    required this.contextTitle,
    required this.contextDescription,
  });

  factory Context.fromJson(Map<String, dynamic> json) {
    return Context(
      contextType: json['context_type'],
      contextTitle: json['context_title'],
      contextDescription: json['context_description'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'context_type': contextType,
      'context_title': contextTitle,
      'context_description': contextDescription,
    };
  }
}

class ContextRequest {
  final String contextType;
  final String contextAdditionalDescription;

  ContextRequest({
    required this.contextType,
    required this.contextAdditionalDescription,
  });

  Map<String, dynamic> toJson() {
    return {
      'context_type': contextType,
      'context_additional_description': contextAdditionalDescription,
    };
  }
}

class EssayContextsRequest {
  final String title;
  final List<ContextRequest> contexts;

  EssayContextsRequest({
    required this.title,
    required this.contexts,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'contexts': contexts.map((c) => c.toJson()).toList(),
    };
  }
}

class ContextsResult {
  final List<Context> contexts;
  final bool isMockData;
  final String? errorMessage;

  ContextsResult({
    required this.contexts,
    this.isMockData = false,
    this.errorMessage,
  });
}

class ContextsApi {
  final ProfileService profileService = ProfileService();

  Future<ContextsResult> getContexts(EssayContextsRequest request) async {
    final String userId = profileService.currentUser!.uid;

    final url = Uri.parse(ApiConfig.contextsUrl).replace(
      queryParameters: {'user_id': userId},
    );
    final headers = {
      'Content-Type': 'application/json',
    };
    final body = jsonEncode(request.toJson());
    
    // Log the request
    ApiConfig.logRequest(
      method: 'POST',
      url: url.toString(),
      headers: headers,
      body: body,
    );
    
    try {
      final response = await http.post(
        url,
        headers: headers,
        body: body,
      );

      // Log the response
      ApiConfig.logResponse(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> contextsJson = data;
        final contexts = contextsJson.map((json) => Context.fromJson(json)).toList();
        return ContextsResult(contexts: contexts, isMockData: false);
      } else {
        throw Exception('Failed to get contexts: ${response.statusCode}');
      }
    } catch (e) {
      print('=== API ERROR ===');
      print('Error getting contexts: $e');
      print('Falling back to mock data...');
      print('=================');
      
      // Return mock data as fallback
      return ContextsResult(
        contexts: generateMockContexts(request),
        isMockData: true,
        errorMessage: e.toString(),
      );
    }
  }

  // Mock data for testing and fallback
  static List<Context> generateMockContexts(EssayContextsRequest request) {
    final mockContexts = <Context>[];
    
    for (final contextRequest in request.contexts) {
      final mockContext = _createMockContext(
        contextRequest.contextType, 
        request.title,
        contextRequest.contextAdditionalDescription,
      );
      mockContexts.add(mockContext);
    }
    
    return mockContexts;
  }
  
  static Context _createMockContext(String contextType, String essayTitle, String additionalDescription) {
    final mockData = _getMockDataForContextType(contextType, essayTitle, additionalDescription);
    return Context(
      contextType: contextType,
      contextTitle: mockData['title']!,
      contextDescription: mockData['description']!,
    );
  }
  
  static Map<String, String> _getMockDataForContextType(String contextType, String essayTitle, String additionalDescription) {
    final hasAdditionalDescription = additionalDescription.isNotEmpty;
    final additionalContext = hasAdditionalDescription ? " (uwzględniając: $additionalDescription)" : "";
    
    switch (contextType) {
      case 'literacki':
        return {
          'title': 'Porównanie z innymi utworami polskiej literatury',
          'description': 'W rozprawce "$essayTitle" warto wykorzystać kontekst literacki poprzez porównanie do innych znaczących dzieł polskiej literatury. Można odwołać się do podobnych motywów, technik narracyjnych czy charakterystyki bohaterów w dziełach takich jak "Lalka" Prusa czy "Pan Tadeusz" Mickiewicza$additionalContext. Taki kontekst wzbogaci analizę i pokaże szersze literackie tło tematu.'
        };
      case 'historyczny':
        return {
          'title': 'Tło historyczne epoki i jego wpływ na utwór',
          'description': 'Rozprawka "$essayTitle" powinna uwzględnić kontekst historyczny epoki, w której powstało dzieło. Należy odnieść się do ważnych wydarzeń historycznych, takich jak powstania narodowe, zmiany społeczno-polityczne czy przemiany cywilizacyjne$additionalContext. Ten kontekst pomoże zrozumieć motywacje bohaterów i uniwersalne przesłanie utworu.'
        };
      case 'filozoficzny':
        return {
          'title': 'Filozoficzne podstawy światopoglądu prezentowanego w utworze',
          'description': 'W kontekście rozprawki "$essayTitle" istotne jest odwołanie się do filozoficznych nurtów epoki, takich jak pozytywizm, romantyzm czy egzystencjalizm. Można przywołać myśl filozoficzną autorów takich jak Schopenhauer, Nietzsche czy polskich myślicieli$additionalContext. Taki kontekst pogłębi analizę światopoglądu bohaterów i uniwersalnych dylematów przedstawionych w utworze.'
        };
      case 'społeczny':
        return {
          'title': 'Obraz społeczeństwa i relacji międzyludzkich',
          'description': 'Rozprawka "$essayTitle" może zostać wzbogacona o kontekst społeczny, przedstawiający strukturę społeczeństwa epoki, relacje między różnymi warstwami społecznymi, obyczaje i normy moralne$additionalContext. Można odwołać się do przemian społecznych, konfliktów klasowych czy ewolucji mentalności społecznej, co pomoże zrozumieć uniwersalne przesłanie utworu.'
        };
      case 'kulturowy':
        return {
          'title': 'Tradycje kulturowe i wartości epoki',
          'description': 'W rozprawce "$essayTitle" warto wykorzystać kontekst kulturowy, odwołując się do tradycji, obyczajów, wierzeń i wartości charakterystycznych dla danej epoki. Można przywołać elementy kultury materialnej i duchowej, święta, rytuały czy sposoby spędzania czasu$additionalContext. Ten kontekst pomoże pokazać, jak bohaterowie funkcjonują w swoim środowisku kulturowym.'
        };
      case 'biograficzny':
        return {
          'title': 'Wydarzenia z życia autora wpływające na dzieło',
          'description': 'Kontekst biograficzny w rozprawce "$essayTitle" pozwoli na odwołanie się do kluczowych wydarzeń z życia autora, jego doświadczeń osobistych, traumy lub radości, które mogły wpłynąć na powstanie utworu$additionalContext. Można przywołać konkretne fakty biograficzne, które znajdują odzwierciedlenie w tematyce, problemach czy postawach bohaterów dzieła.'
        };
      case 'religijny':
        return {
          'title': 'Motywy i wartości religijne w utworze',
          'description': 'W rozprawce "$essayTitle" kontekst religijny może obejmować odwołania do tradycji chrześcijańskiej, wartości moralnych, dylematów etycznych czy kwestii wiary i zwątpienia. Można przywołać fragmenty Biblii, tradycję teologiczną lub ludowe wierzenia religijne$additionalContext. Ten kontekst pomoże zrozumieć duchowy wymiar utworu i dylematy moralne bohaterów.'
        };
      case 'mitologiczny':
        return {
          'title': 'Nawiązania do mitologii antycznej i słowiańskiej',
          'description': 'Kontekst mitologiczny w rozprawce "$essayTitle" pozwoli na odwołanie się do mitów greckich, rzymskich lub słowiańskich, które mogą być obecne w utworze w postaci aluzji, symboli czy archetypów$additionalContext. Można przywołać konkretne mity, postaci mitologiczne czy motywy mityczne, które wzbogacą interpretację dzieła i pokażą jego uniwersalny charakter.'
        };
      case 'teoretycznoliteracki':
        return {
          'title': 'Analiza gatunku i środków artystycznych',
          'description': 'W rozprawce "$essayTitle" kontekst teoretycznoliteracki obejmuje analizę gatunku literackiego, kompozycji, środków stylistycznych, technik narracyjnych i innych elementów poetyki$additionalContext. Można odwołać się do teorii literatury, definicji gatunków czy koncepcji estetycznych, co pomoże w profesjonalnej analizie artystycznej warstwy utworu.'
        };
      case 'historycznoliteracki':
        return {
          'title': 'Prądy i kierunki literackie epoki',
          'description': 'Kontekst historycznoliteracki w rozprawce "$essayTitle" pozwala na umieszczenie utworu w kontekście prądów literackich epoki, takich jak romantyzm, pozytywizm czy modernizm. Można odwołać się do charakterystycznych cech kierunku, programów estetycznych i ideowych$additionalContext. Ten kontekst pomoże zrozumieć, jak utwór wpisuje się w tradycję literacką swojej epoki.'
        };
      case 'artystyczny':
        return {
          'title': 'Związki z innymi dziedzinami sztuki',
          'description': 'W rozprawce "$essayTitle" kontekst artystyczny może obejmować nawiązania do malarstwa, muzyki, architektury czy teatru epoki. Można przywołać konkretne dzieła sztuki, style artystyczne czy estetyczne koncepcje, które korespondują z tematyką utworu$additionalContext. Ten kontekst wzbogaci analizę o interdyscyplinarny wymiar i pokaże uniwersalność artystycznych poszukiwań epoki.'
        };
      case 'egzystencjalny':
        return {
          'title': 'Problemy egzystencjalne i sens życia',
          'description': 'Kontekst egzystencjalny w rozprawce "$essayTitle" pozwala na skupienie się na fundamentalnych pytaniach o sens życia, śmierć, cierpienie, wolność i odpowiedzialność. Można odwołać się do dylematów egzystencjalnych bohaterów, ich poszukiwań tożsamości i miejsca w świecie$additionalContext. Ten kontekst pomoże zrozumieć uniwersalne problemy ludzkiej egzystencji przedstawione w utworze.'
        };
      case 'polityczny':
        return {
          'title': 'Ustrój polityczny i władza w utworze',
          'description': 'W rozprawce "$essayTitle" kontekst polityczny może obejmować analizę systemów władzy, ideologii politycznych, walk o niepodległość czy krytyki ustroju przedstawionego w utworze. Można odwołać się do konkretnych wydarzeń politycznych epoki, postaw obywatelskich bohaterów$additionalContext. Ten kontekst pomoże zrozumieć polityczne uwikłania i aspiracje przedstawione w dziele.'
        };
      case 'biblijny':
        return {
          'title': 'Motywy i symbolika biblijna',
          'description': 'Kontekst biblijny w rozprawce "$essayTitle" pozwala na odwołanie się do konkretnych fragmentów Starego i Nowego Testamentu, przypowieści, postaci biblijnych czy symboliki religijnej. Można przywołać archetypy biblijne, motywy odkupienia, grzechu czy sprawiedliwości$additionalContext. Ten kontekst wzbogaci interpretację o duchowy i moralny wymiar utworu.'
        };
      default:
        return {
          'title': 'Kontekst dla "$essayTitle"',
          'description': 'Kontekst ${getContextTypeDisplayName(contextType)} w rozprawce "$essayTitle" pozwoli na pogłębioną analizę utworu$additionalContext. Ten kontekst pomoże w lepszym zrozumieniu dzieła i jego uniwersalnego przesłania.'
        };
    }
  }

  // Predefined context types based on docs/rozprawka.md
  static const List<String> availableContextTypes = [
    'literacki',
    'historycznoliteracki',
    'teoretycznoliteracki',
    'historyczny',
    'filozoficzny',
    'kulturowy',
    'biograficzny',
    'biblijny',
    'mitologiczny',
    'religijny',
    'egzystencjalny',
    'społeczny',
    'polityczny',
    'artystyczny',
  ];

  static String getContextTypeDisplayName(String contextType) {
    switch (contextType) {
      case 'literacki':
        return 'Kontekst literacki';
      case 'historycznoliteracki':
        return 'Kontekst historycznoliteracki';
      case 'teoretycznoliteracki':
        return 'Kontekst teoretycznoliteracki';
      case 'historyczny':
        return 'Kontekst historyczny';
      case 'filozoficzny':
        return 'Kontekst filozoficzny';
      case 'kulturowy':
        return 'Kontekst kulturowy';
      case 'biograficzny':
        return 'Kontekst biograficzny';
      case 'biblijny':
        return 'Kontekst biblijny';
      case 'mitologiczny':
        return 'Kontekst mitologiczny';
      case 'religijny':
        return 'Kontekst religijny';
      case 'egzystencjalny':
        return 'Kontekst egzystencjalny';
      case 'społeczny':
        return 'Kontekst społeczny';
      case 'polityczny':
        return 'Kontekst polityczny';
      case 'artystyczny':
        return 'Kontekst artystyczny';
      default:
        return contextType;
    }
  }

  static String getContextTypeDescription(String contextType) {
    switch (contextType) {
      case 'literacki':
        return 'Odniesienie do innych utworów literackich';
      case 'historycznoliteracki':
        return 'Odniesienie do prądów literackich danej epoki, np. romantyzmu czy pozytywizmu';
      case 'teoretycznoliteracki':
        return 'Odniesienie do wiedzy z zakresu teorii literatury, np. gatunków literackich';
      case 'historyczny':
        return 'Odniesienie do konkretnych wydarzeń historycznych, np. powstania, wojen';
      case 'filozoficzny':
        return 'Odniesienie do poglądów filozoficznych i traktatów filozoficznych';
      case 'kulturowy':
        return 'Odniesienie do wierzeń, tradycji i wartości kulturowych';
      case 'biograficzny':
        return 'Odniesienie do faktów z życia autora, które miały wpływ na powstanie dzieła';
      case 'biblijny':
        return 'Odniesienie do treści, motywów lub postaci z Biblii';
      case 'mitologiczny':
        return 'Odniesienie do mitów greckich, rzymskich lub innych';
      case 'religijny':
        return 'Odniesienie do zasad wiary, dogmatów czy podstaw danej religii';
      case 'egzystencjalny':
        return 'Odniesienie do problemów związanych z losem człowieka, sensu życia i śmierci';
      case 'społeczny':
        return 'Odniesienie do zjawisk społecznych, struktury społeczeństwa, obyczajowości';
      case 'polityczny':
        return 'Odniesienie do działań politycznych, ustroju państwa czy władzy';
      case 'artystyczny':
        return 'Odniesienie do innych dziedzin sztuki, takich jak film, malarstwo czy muzyka';
      default:
        return '';
    }
  }
}