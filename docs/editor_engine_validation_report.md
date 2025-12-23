# Отчёт валидации EditorEngine

Дата: 2025-12-?? (сгенерирован в ходе ревью репозитория)

## 1. Область проверки и источники

**Цель:** провести валидацию выполненных задач по фиче EditorEngine и их соответствие PRD/Workplan, используя:
- `DOCS/Workplan.md` (фаза 10: EE0–EE7)
- `DOCS/PRD/PRD_EditorEngine.md`
- `DOCS/TASKS_ARCHIVE/*` (архив задач EE0–EE6)
- исходный код в `Sources/EditorEngine/*` и `Package.swift`

## 2. Проверка выполнения задач Workplan (Phase 10)

| Task | Статус в Workplan | Фактические артефакты (код/доки) | Итог проверки |
|------|--------------------|----------------------------------|---------------|
| **EE0: Module Foundation** | ✅ | `Package.swift` (продукт и таргет EditorEngine), `Sources/EditorEngine/EditorEngine.swift` | ✅ **Выполнено**, но **trait-gating не найден** (см. замечания) |
| **EE1: Project Indexing** | ✅ | `Sources/EditorEngine/ProjectIndexer.swift`, `ProjectIndex.swift`, `GlobMatcher.swift` | ✅ **Выполнено** |
| **EE2: Parsing with Link Spans** | ✅ | `Sources/EditorEngine/EditorParser.swift`, `LinkSpan.swift`, `ParsedFile.swift` | ✅ **Выполнено** |
| **EE3: Link Resolution** | ✅ | `Sources/EditorEngine/EditorResolver.swift`, `ResolvedTarget.swift` | ✅ **Выполнено** |
| **EE4: Editor Compilation** | ✅ | `Sources/EditorEngine/EditorCompiler.swift`, `CompileOptions.swift`, `CompileResult.swift` | ✅ **Выполнено**, но зависит от `CLI` (см. замечания) |
| **EE5: Diagnostics Mapping** | ✅ | `Sources/EditorEngine/Diagnostics.swift`, `DiagnosticMapper.swift` | ✅ **Выполнено** |
| **EE6: Documentation & Testing** | ✅ | `DOCS/EDITOR_ENGINE.md` | ✅ **Выполнено** |
| **EE7: SpecificationCore Decision Refactor** | ✅ | Набор DecisionSpec файлов: `LinkDecisionSpecs.swift`, `DirectoryDecisionSpecs.swift`, `FileTypeDecisionSpecs.swift`, `CompilePolicyDecisionSpecs.swift`, `OutputPathDecisionSpecs.swift`, `ResolutionDecisionSpecs.swift` | ✅ **Выполнено в коде**, **но отсутствует** отдельный архивный отчёт `DOCS/TASKS_ARCHIVE/EE7-summary.md` |

**Архив задач:**
- Найдены отчёты `EE0-summary.md` … `EE6-summary.md` в `DOCS/TASKS_ARCHIVE/`.
- **Не найден** архивный summary-файл для EE7.

## 3. Проверка соответствия PRD (FR-1…FR-7)

| PRD Requirement | Проверка по коду | Итог |
|----------------|------------------|------|
| **FR-1:** Parse Hypercode + link spans | `EditorParser.parse(...)` извлекает `LinkSpan` из токенов (`Sources/EditorEngine/EditorParser.swift`) | ✅ Соответствует |
| **FR-2:** Resolve file refs идентично CLI | `EditorResolver` использует правила `.md/.hc`, проверку traversal, root order (workspace → source dir → cwd) | ✅ В целом соответствует |
| **FR-3:** Programmatic compile | `EditorCompiler.compile(...)` вызывает `CompilerDriver` | ✅ Соответствует |
| **FR-4:** Structured diagnostics | `DiagnosticMapper.map(...)` и `Diagnostics.swift` определяют структуру | ✅ Соответствует (минимально) |
| **FR-5:** Disable unless `Editor` trait enabled | **В `Package.swift` отсутствует trait-gating**; EditorEngine всегда доступен как продукт | ⚠️ **Не соответствует** |
| **FR-6:** Deterministic indexing + ignore rules | `ProjectIndexer` сортирует, `.hyperpromptignore`, дефолтные ignore dirs | ✅ Соответствует |
| **FR-7:** Offsets for editors | `LinkSpan` хранит UTF-8 byte offsets + 1-based line/column | ✅ Соответствует |

## 4. Нефункциональные требования PRD (ключевые)

- **Детерминизм**: операции индексирования/парсинга/компиляции детерминированы (сортировка, статические правила) — ✅.
- **Стабильность**: парсер использует recovery (`parseWithRecovery`), возвращает `ParsedFile` с diagnostics — ✅ для синтаксических ошибок; **IO ошибки при `parse(filePath:)` кидаются как throw** — ⚠️ потенциальное несоответствие правилу «all errors surfaced as diagnostics».
- **Изоляция от UI**: в `EditorEngine` нет UI/LLM зависимостей — ✅.
- **Trait-gating**: отсутствует, см. выше — ❌.

## 5. Замечания и расхождения

1. **Trait-gating отсутствует**
   - PRD явно требует, чтобы EditorEngine был отключён без `--traits Editor`.
   - В `Package.swift` нет объявления traits, и продукт/таргет EditorEngine доступны всегда.
   - `DOCS/EDITOR_ENGINE.md` утверждает, что trait-gating есть, но **код не подтверждает это**.

2. **EditorEngine зависит от CLI**
   - `Package.swift` включает `CLI` в зависимости `EditorEngine`.
   - `EditorCompiler` импортирует `CLI` и использует `CompilerDriver`.
   - В PRD (Phase 0.2) указано: **EditorEngine target должен быть изолирован и не зависеть от CLI**.

3. **Нет архивного отчёта EE7**
   - В `DOCS/TASKS_ARCHIVE` отсутствует `EE7-summary.md`.
   - Несмотря на наличие DecisionSpec-файлов (вероятно, реализация EE7), формальная документация задачи отсутствует.

4. **Ошибки чтения файла при парсинге**
   - `EditorParser.parse(filePath:)` кидает `CompilerError` при проблемах чтения.
   - PRD требует, чтобы ошибки были диагностиками (включая IO). Здесь API часть ошибок возвращает через `throws`.

## 6. Итоговый вывод

- Большая часть задач EE0–EE6 реализована и подтверждается исходным кодом.
- Функциональные требования PRD в целом закрыты, **кроме trait-gating** и **изолированности от CLI**.
- Документация (`DOCS/EDITOR_ENGINE.md`) описывает trait-gating, но фактическая конфигурация его не содержит.
- По EE7 реализация DecisionSpec-паттернов присутствует в коде, но **нет архивного отчёта** в `DOCS/TASKS_ARCHIVE`.

## 7. Рекомендации (без изменений кода)

1. Зафиксировать несоответствие по trait-gating (Package.swift) и обновить план/PRD-статус.
2. Зафиксировать несоответствие по зависимости от CLI (EditorEngine ← CLI).
3. Добавить архивный отчёт EE7 в `DOCS/TASKS_ARCHIVE` (если задача действительно завершена).
4. Уточнить API поведения `EditorParser.parse(filePath:)` и следование правилу «all errors surfaced as diagnostics».

