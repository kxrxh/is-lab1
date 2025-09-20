# Информационная безопасность. Работа 1. P3412. Пархоменко К. А

Spring Boot приложение с JWT аутентификацией, защитой от SQL-инъекций, XSS-атак и других уязвимостей.

## Запуск

```bash
mvn spring-boot:run
```

## API Эндпоинты

### Аутентификация

#### Регистрация пользователя

```http
POST /auth/register
Content-Type: application/json

{
  "username": "testuser",
  "password": "password123",
  "name": "Test User"
}
```

**Curl пример:**

```bash
curl -X POST http://localhost:8080/auth/register \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123",
    "name": "Test User"
  }'
```

#### Вход в систему

```http
POST /auth/login
Content-Type: application/json

{
  "username": "testuser",
  "password": "password123"
}

Response:
{
  "token": "jwt_token_here",
  "username": "testuser",
  "name": "Test User"
}
```

**Curl пример:**

```bash
curl -X POST http://localhost:8080/auth/login \
  -H "Content-Type: application/json" \
  -d '{
    "username": "testuser",
    "password": "password123"
  }'
```

### Защищенные эндпоинты

Все следующие эндпоинты требуют JWT-токен:

```http
Authorization: Bearer <jwt_token>
```

#### Получение данных пользователя

```http
GET /api/data

Response:
{
  "currentUser": "Test User",
  "allUsers": ["user1", "user2", "testuser"]
}
```

**Curl пример:**

```bash
curl -X GET http://localhost:8080/api/data \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

#### Получение всех постов

```http
GET /api/posts

Response:
[
  {
    "id": 1,
    "title": "Sample Post",
    "content": "Post content...",
    "author": "Test User",
    "createdAt": "2024-01-01T10:00:00",
    "updatedAt": "2024-01-01T10:00:00"
  }
]
```

**Curl пример:**

```bash
curl -X GET http://localhost:8080/api/posts \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
```

#### Создание нового поста

```http
POST /api/posts
Content-Type: application/json

{
  "title": "New Post Title",
  "content": "Post content here..."
}

Response:
{
  "id": 2,
  "title": "New Post Title",
  "content": "Post content here...",
  "author": "Test User",
  "createdAt": "2024-01-01T10:30:00",
  "updatedAt": "2024-01-01T10:30:00"
}
```

**Curl пример:**

```bash
curl -X POST http://localhost:8080/api/posts \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..." \
  -d '{
    "title": "New Post Title",
    "content": "Post content here..."
  }'
```

## Меры безопасности

### Аутентификация и авторизация

- **JWT-токены**: Stateless аутентификация, токены передаются в заголовке Authorization ([`JwtUtil.java`](src/main/java/com/example/secureapi/security/JwtUtil.java), [`JwtAuthenticationFilter.java`](src/main/java/com/example/secureapi/security/JwtAuthenticationFilter.java))
- **BCrypt хэширование**: Пароли хэшируются перед сохранением в БД ([`UserService.java`](src/main/java/com/example/secureapi/service/UserService.java), [`SecurityConfig.java`](src/main/java/com/example/secureapi/security/SecurityConfig.java))
- **Stateless сессии**: Вся информация о пользователе хранится в JWT-токене ([`SecurityConfig.java`](src/main/java/com/example/secureapi/security/SecurityConfig.java))

### Защита от SQL-инъекций

- **JPA/Hibernate**: Все запросы выполняются через JPA с параметризованными запросами
- **JPQL**: В [`PostRepository.java`](src/main/java/com/example/secureapi/repository/PostRepository.java) используются параметры вместо конкатенации строк

### Защита от XSS-атак

- **Автоматическое HTML escaping**: Все пользовательские данные в JSON ответах экранируются Jackson сериализатором
- **Расширенная Jackson конфигурация**: Настроена в [`JacksonConfig.java`](src/main/java/com/example/secureapi/config/JacksonConfig.java) с полным HTML экранированием
- **Экранируемые символы**: `<`, `>`, `&`, `"`, `'`, а также все non-ASCII символы
- **Unicode escaping**: HTML-теги преобразуются в Unicode escape-последовательности (`\u003Cscript\u003E`)

### Конфигурация безопасности

- **AuthenticationEntryPoint**: Настроен в [`SecurityConfig.java`](src/main/java/com/example/secureapi/security/SecurityConfig.java) для корректной обработки неавторизованных запросов
- **Defensive copying**: В entity-классах используются конструкторы копирования

## Отчеты

Отчеты статического анализа безопасности и анализа зависимостей доступны в артефактах workflow:

- Скриншоты CI/CD: [`SpotBugs`](files/1.png), [`Snyk`](files/2.png)
