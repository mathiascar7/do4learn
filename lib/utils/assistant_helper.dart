import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:dart_jsonwebtoken/dart_jsonwebtoken.dart';

class AssistantHelper {
  final String languageCode;
  late String projectId;
  late String sessionId;
  late String accessToken;
  late String clientEmail;
  late String privateKey;

  AssistantHelper(this.languageCode);

  Future<void> init() async {
    final jsonString = await rootBundle.loadString('assets/dialog_flow_auth.json');
    final credentials = json.decode(jsonString);

    projectId = credentials["project_id"];
    clientEmail = credentials["client_email"];
    privateKey = credentials["private_key"];
    sessionId = "flutter-session-${DateTime.now().millisecondsSinceEpoch}";

    accessToken = await _generateAccessToken();

    print("🔐 Token generado para ES");
    print("🔍 Endpoint:");
    print("https://dialogflow.googleapis.com/v2/projects/$projectId/agent/sessions/$sessionId:detectIntent");
  }

  Future<String> ask(String userMessage) async {
    final url = Uri.parse(
      "https://dialogflow.googleapis.com/v2/projects/$projectId/agent/sessions/$sessionId:detectIntent",
    );

    final payload = {
      "queryInput": {
        "text": {
          "text": userMessage,
          "languageCode": languageCode,
        }
      }
    };

    print("📦 Payload enviado a Dialogflow ES:");
    print(jsonEncode(payload));

    final response = await http.post(
        url,
      headers: {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      },

      body: jsonEncode(payload),
    );

    print("📥 Respuesta HTTP: ${response.statusCode}");
    print("📄 Cuerpo: ${response.body}");

    if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final fulfillment = data["queryResult"]["fulfillmentText"];
    return fulfillment ?? "No hubo respuesta del agente.";
    } else {
    final error = jsonDecode(response.body)["error"];
    return "Error ${error["code"]}: ${error["message"]}";
    }
  }

  Future<String> _generateAccessToken() async {
    final iat = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final exp = iat + 3600;

    final jwt = JWT(
      {
        "iss": clientEmail,
        "scope": "https://www.googleapis.com/auth/cloud-platform",
        "aud": "https://oauth2.googleapis.com/token",
        "exp": exp,
        "iat": iat,
      },
    );

    final signedJwt = jwt.sign(RSAPrivateKey(privateKey), algorithm: JWTAlgorithm.RS256);

    final response = await http.post(
      Uri.parse("https://oauth2.googleapis.com/token"),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        "grant_type": "urn:ietf:params:oauth:grant-type:jwt-bearer",
        "assertion": signedJwt,
      },
    );

    final tokenData = jsonDecode(response.body);
    return tokenData["access_token"];
  }
}
