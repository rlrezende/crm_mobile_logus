## Logus CRM Mobile

Aplicativo Flutter (Android/iOS) que consome a API `LogusCrmApi` para autenticação e leitura do módulo de alertas. O projeto já nasce preparado para:

- Login via `/api/Login/authenticate` usando `Dio`.
- Armazenamento seguro do token + dados do usuário com `flutter_secure_storage`.
- Desbloqueio via biometria/Face ID com `local_auth`.
- Tela inicial que consome `/api/Alerts/summary` para exibir indicadores.

### Pré-requisitos

- Flutter SDK 3.24.x (já baixamos em `~/.flutter-sdk/flutter`).
- Android SDK/Xcode de acordo com a documentação oficial.
- API .NET rodando localmente (`dotnet run --project LogusCrmApi.API`).

### Executando

1. Instale as dependências:
   ```bash
   cd crm_mobile_logus
   flutter pub get
   ```
2. Informe a URL da API ao subir o app (por padrão usamos a API pública `https://crmapi.loguscapital.com:446/api`):
   ```bash
   flutter run \
     --dart-define API_BASE_URL=http://10.0.2.2:5283/api   # para ambiente local
   ```
   - Para dispositivos físicos, substitua pelo IP da máquina onde a API está rodando.
   - No iOS, verifique se a rede está acessível; o `Info.plist` já libera HTTP simples para desenvolvimento.

Opcionalmente, passe `--dart-define LOG_NETWORK=true` para log detalhado das chamadas HTTP.

### Estrutura principal

```
lib/
 ├─ core/
 │   ├─ config/app_config.dart        # leitura de API_BASE_URL/LOG_NETWORK
 │   ├─ network/api_client.dart       # cliente Dio comum com Bearer token
 │   ├─ services/biometric_auth_service.dart
 │   └─ storage/token_storage.dart    # persiste sessão em storage seguro
 ├─ features/
 │   ├─ auth/                         # login + controller + tela + modelos
 │   └─ alerts/                       # consumo de /alerts/summary
 ├─ widgets/summary_card.dart
 └─ app.dart / main.dart              # composição de providers e rotas
```

### Fluxo implementado

1. Usuário informa `email`/`password`. A resposta (`LoginResponseDTO`) é convertida para `AuthSession` e salva.
2. Tokens ficam em `flutter_secure_storage` e o app atualiza o header `Authorization`.
3. Se biometria estiver disponível, em próximos acessos pede Face ID/biometria antes de liberar o dashboard.
4. Dashboard chama `/Alerts/summary` e mostra cards + chips com dados por tipo/status.

### Próximos passos sugeridos

- Criar camadas adicionais (ex.: alert list/detail).
- Tratar refresh de token quando expirar (hoje exige novo login).
- Adicionar testes widget/unitários para AuthController e AlertRepository.
