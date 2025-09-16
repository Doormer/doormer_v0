## Project Overview
**Project Name:** Doormer  
**Framework:** Flutter 3.27.1  
**Language:** Dart  
**Target Platforms:** Web (Primary), iOS, Android, Linux, Windows, macOS  
**Architecture Pattern:** Clean Architecture with Repository Pattern and BLoC State Management  

## Tech Stack & Dependencies

### Core Flutter Dependencies
- **flutter_bloc**: State management using BLoC pattern
- **go_router**: Declarative routing and navigation
- **dio**: HTTP client for API communication
- **get_it**: Dependency injection container
- **flutter_secure_storage**: Secure token storage
- **google_sign_in**: Google OAuth authentication
- **file_picker**: File selection for document uploads
- **flutter_screenutil**: Responsive UI scaling
- **toastification**: Toast notifications
- **flutter_markdown/flutter_html**: Rich text rendering

### Development Tools
- **bloc_test**: Testing BLoC components
- **freezed_annotation**: Code generation for immutable classes
- **json_annotation**: JSON serialization support

## Architecture Overview

### Clean Architecture Layers
The project follows Clean Architecture principles with clear separation of concerns:

```
lib/
├── main.dart                    # Application entry point
└── src/
    ├── core/                    # Core infrastructure & shared utilities
    ├── features/                # Feature-specific modules
    └── shared/                  # Shared entities & components
```

### Layer Responsibilities

#### 1. Domain Layer (Business Logic)
- **Entities**: Pure business objects with no dependencies
- **Repositories**: Abstract contracts for data access
- **Use Cases**: Business logic implementation

#### 2. Data Layer (External Interfaces)
- **Models**: Data transfer objects with JSON serialization
- **Data Sources**: Remote (API) and local (storage) data access
- **Repository Implementations**: Concrete repository implementations

#### 3. Presentation Layer (UI & State Management)
- **Pages**: UI screens and widgets
- **BLoC**: State management with events and states
- **Widgets**: Reusable UI components

## Directory Structure Guide

### Core Infrastructure (`/src/core/`)
```
core/
├── agreement_texts/           # Legal agreement text constants
├── config/                    # App configuration (API URLs, constants)
├── connection/               # HTTP client setup and interceptors
│   ├── dio_client.dart      # Configured Dio HTTP client
│   └── interceptors/        # Request/response interceptors
├── di/                      # Dependency injection setup
├── errors/                  # Error handling and custom exceptions
├── routes/                  # Navigation and routing configuration
├── services/                # Core services (session management)
├── theme/                   # UI theme (colors, text styles)
└── utils/                   # Utilities (logging, token storage, UUID)
```

### Features (`/src/features/`)
Each feature follows the same modular structure:

```
features/
├── auth/                    # Authentication feature
│   ├── data/               # Data layer
│   │   ├── datasource/     # API and local data sources
│   │   ├── model/          # DTOs and JSON models
│   │   └── repository/     # Repository implementations
│   ├── di/                 # Feature-specific dependency injection
│   ├── domain/             # Business logic layer
│   │   ├── entity/         # Domain entities
│   │   ├── repository/     # Repository interfaces
│   │   └── usecase/        # Use cases (business operations)
│   ├── presentation/       # UI layer
│   │   ├── bloc/           # BLoC state management
│   │   ├── pages/          # Screen widgets
│   │   └── widget/         # Feature-specific widgets
│   └── utils/              # Feature-specific utilities
└── registration/           # Candidate registration feature
    └── [same structure as auth/]
```

### Shared Components (`/src/shared/`)
```
shared/
├── sessions/               # Global session state management
├── user/                   # User entity and models
└── widget/                 # Reusable UI components
```

## Key Components & Patterns

### 1. Dependency Injection Pattern
- **Service Locator**: `GetIt` container for dependency registration
- **Module Pattern**: Feature-specific DI modules (`auth_module.dart`, `registration_module.dart`)
- **Lazy Loading**: Services registered as lazy singletons where appropriate

### 2. State Management (BLoC Pattern)
- **Events**: User interactions and external triggers
- **States**: UI state representations (Loading, Success, Error)
- **BLoCs**: Business logic components that transform events to states

### 3. Repository Pattern
- **Abstract Repositories**: Domain layer contracts
- **Repository Implementations**: Data layer concrete classes
- **Data Sources**: Separate remote (API) and local (storage) data access

### 4. Entity-Model Mapping
- **Entities**: Domain objects in `/domain/entity/`
- **Models**: Data objects in `/data/model/` with `fromJson/toJson`
- **Mappers**: `fromEntity/toEntity` methods for layer conversion

## Authentication Flow
1. **Sign Up/Login**: Email/password or Google OAuth
2. **Token Management**: JWT tokens stored securely
3. **Session Management**: Global session state with BLoC
4. **Automatic Renewal**: Token refresh via interceptors

## Registration Flow
1. **Candidate Details**: Personal information collection
2. **Document Upload**: CV/Resume upload to cloud storage
3. **Preferences**: Job preferences and requirements
4. **Validation**: File format and data validation

## API Integration
- **Base URL**: Configured via environment variables
- **HTTP Client**: Dio with interceptors for authentication
- **Error Handling**: Centralized error processing
- **File Upload**: SAS URL-based file uploads to cloud storage

## Platform-Specific Configurations
- **Web**: Primary target with web-optimized routing
- **Mobile**: iOS and Android support with platform-specific plugins
- **Desktop**: Windows, macOS, and Linux support

## Environment Configuration
```dart
// Environment variables
API_BASE_URL=https://api.doormer.com
GOOGLE_CLIENT_ID=your-google-client-id
```

## Testing Strategy
- **Unit Tests**: Use cases and business logic
- **BLoC Tests**: State management testing with `bloc_test`
- **Integration Tests**: API and repository testing

## Security Considerations
- **Token Storage**: Secure storage using `flutter_secure_storage`
- **Authentication**: JWT-based with refresh token rotation
- **File Uploads**: Secure SAS URL-based uploads
- **HTTPS**: All API communication over HTTPS

## AI Coding Assistant Guidelines

### When Working with This Project:

1. **Follow Clean Architecture**: Keep domain, data, and presentation layers separate
2. **Use Repository Pattern**: Always go through repositories for data access
3. **BLoC for State Management**: Use events and states for UI logic
4. **Dependency Injection**: Register new services in appropriate modules
5. **Entity-Model Separation**: Keep domain entities pure, use models for serialization
6. **Error Handling**: Use the established error handling patterns
7. **Naming Conventions**: Follow established patterns for files and classes

### Common Operations:

#### Adding a New Feature:
1. Create feature directory with standard structure
2. Define entities in `/domain/entity/`
3. Create repository interface in `/domain/repository/`
4. Implement data models in `/data/model/`
5. Create data sources in `/data/datasource/`
6. Implement repository in `/data/repository/`
7. Define use cases in `/domain/usecase/`
8. Create BLoC in `/presentation/bloc/`
9. Build UI in `/presentation/pages/` and `/presentation/widget/`
10. Register dependencies in `/di/` module
11. Add routes in router configuration

#### Adding a New API Endpoint:
1. Add method to appropriate data source
2. Update repository implementation
3. Create or update use case
4. Update BLoC events/states if needed

#### Adding New UI Components:
1. Create in appropriate `/presentation/widget/` directory
2. Use established theming from `/core/theme/`
3. Follow responsive design patterns with ScreenUtil

### File Naming Conventions:
- **Pages**: `*_page.dart` (e.g., `login_page.dart`)
- **BLoCs**: `*_bloc.dart`, `*_event.dart`, `*_state.dart`
- **Models**: `*_model.dart` (e.g., `user_model.dart`)
- **Entities**: Simple names (e.g., `user.dart`, `candidate_details.dart`)
- **Repositories**: `*_repository.dart` for interfaces, `*_repository_impl.dart` for implementations
- **Use Cases**: `*_usecase.dart`
- **Data Sources**: `*_datasource.dart` or `*_remote_datasource.dart`/`*_local_datasource.dart`