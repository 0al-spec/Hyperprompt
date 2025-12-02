# PLAN — Создание детального плана выполнения задачи

## Цель

Преобразовать краткую задачу из `next.md` в полноценный PRD (Product Requirements Document) с детальным планом выполнения, применяя правила из `DOCS/RULES/01_PRD_PROMPT.md`.

## Входные данные

- **Current Task:** `/home/user/Hyperprompt/DOCS/INPROGRESS/next.md` — текущая задача (ID и название)
- **PRD Rules:** `/home/user/Hyperprompt/DOCS/RULES/01_PRD_PROMPT.md` — правила создания PRD
- **Workplan:** `/home/user/Hyperprompt/DOCS/Workplan.md` — контекст задачи из общего плана

## Алгоритм создания плана

### Шаг 1: Извлечь информацию о задаче

1. Прочитать `DOCS/INPROGRESS/next.md`
2. Извлечь ID задачи (например, `A1`, `A2`, `B1`)
3. Извлечь название задачи (например, `Project Initialization`, `Core Types Implementation`)

### Шаг 2: Собрать контекст из Workplan

1. Найти задачу в `DOCS/Workplan.md` по ID
2. Извлечь полную информацию:
   - Приоритет (`[P0]`, `[P1]`, `[P2]`)
   - Фазу и трек
   - Оценку времени
   - Зависимости
   - Описание задачи
   - Список подзадач (если есть)
   - Критерии приемки (если есть)

### Шаг 3: Применить правила PRD

Прочитать `DOCS/RULES/01_PRD_PROMPT.md` и применить все правила для создания детального плана:

1. **Определить scope и intent**
   - Переформулировать цель задачи в точных терминах
   - Определить deliverables и критерии успеха
   - Отметить ограничения, предположения, зависимости

2. **Декомпозировать в иерархический TODO план**
   - Разбить на атомарные, проверяемые подзадачи
   - Для каждой подзадачи определить: вход, процесс, выход
   - Группировать по логическим категориям
   - Явно указать зависимости и возможности параллелизации

3. **Обогатить метаданными**
   - Приоритет (High / Medium / Low)
   - Оценка усилий (время или сложность)
   - Требуемые инструменты, фреймворки, API, датасеты
   - Критерии приемки и методы верификации

4. **Создать PRD секции**
   - Описание фичи и обоснование
   - Функциональные требования
   - Нефункциональные требования (производительность, масштабируемость, безопасность)
   - User interaction flows (если применимо)
   - Edge cases и сценарии отказа

5. **Применить правила качества**
   - Избегать неопределенных формулировок
   - Каждый шаг должен быть выполнимым без внешней интерпретации
   - Поддерживать консистентность терминологии

### Шаг 4: Сформировать PRD файл

Создать файл `/home/user/Hyperprompt/DOCS/INPROGRESS/{TASK_ID}.md` со следующей структурой:

```markdown
# {TASK_ID}: {TASK_NAME}

**Priority:** {PRIORITY}
**Phase:** {PHASE_NUMBER} — {PHASE_NAME}
**Track:** {TRACK_ID} (Track Name)
**Estimated Time:** {HOURS} hours
**Dependencies:** {DEPENDENCIES_LIST}
**Status:** Planning Complete

---

## 1. Scope & Intent

### Objective
{Precise, unambiguous restatement of the task objective}

### Deliverables
- {Deliverable 1}
- {Deliverable 2}

### Success Criteria
- {Criterion 1}
- {Criterion 2}

### Constraints
- {Constraint 1}
- {Constraint 2}

### Assumptions
- {Assumption 1}

### External Dependencies
- {Dependency 1}

---

## 2. Hierarchical TODO Plan

### Phase 2.1: {Phase Name}
**Priority:** High | Medium | Low
**Estimated:** {hours}h
**Dependencies:** None | {task_ids}

- [ ] **Task 2.1.1:** {Task description}
  - **Input:** {What is needed to start}
  - **Process:** {What to do}
  - **Output:** {Expected result}
  - **Acceptance:** {How to verify}
  - **Effort:** {time estimate}

- [ ] **Task 2.1.2:** {Task description}
  - **Input:** {What is needed to start}
  - **Process:** {What to do}
  - **Output:** {Expected result}
  - **Acceptance:** {How to verify}
  - **Effort:** {time estimate}

### Phase 2.2: {Phase Name}
{...}

**Parallelization Opportunities:**
- Tasks 2.1.1 and 2.1.2 can run in parallel
- Phase 2.2 can start after Task 2.1.1 completes

---

## 3. Execution Metadata

| Task ID | Priority | Effort | Tools/Frameworks | Verification Method |
|---------|----------|--------|------------------|---------------------|
| 2.1.1   | High     | 2h     | Swift, XCTest    | Unit tests pass     |
| 2.1.2   | Medium   | 1h     | Git              | Files committed     |

---

## 4. Requirements

### 4.1 Functional Requirements

**FR1:** {Requirement description}
- **Details:** {Implementation details}
- **Acceptance:** {How to verify}

**FR2:** {Requirement description}
- **Details:** {Implementation details}
- **Acceptance:** {How to verify}

### 4.2 Non-Functional Requirements

**NFR1 — Performance:**
- {Performance requirement}

**NFR2 — Scalability:**
- {Scalability requirement}

**NFR3 — Security:**
- {Security requirement}

**NFR4 — Compatibility:**
- {Compatibility requirement}

---

## 5. Interaction Flows

### Flow 5.1: {Flow name}
```
1. {Step 1}
2. {Step 2}
3. {Step 3}
```

---

## 6. Edge Cases & Failure Scenarios

### Case 6.1: {Edge case name}
**Scenario:** {Description}
**Expected Behavior:** {How to handle}
**Mitigation:** {Prevention strategy}

### Case 6.2: {Failure scenario}
**Scenario:** {Description}
**Expected Behavior:** {How to handle}
**Recovery:** {Recovery strategy}

---

## 7. Verification Plan

### 7.1 Unit Tests
- [ ] {Test description}
- [ ] {Test description}

### 7.2 Integration Tests
- [ ] {Test description}
- [ ] {Test description}

### 7.3 Manual Verification
- [ ] {Verification step}
- [ ] {Verification step}

---

## 8. Definition of Done

Task is considered complete when:
- [ ] All TODO items checked off
- [ ] All functional requirements met
- [ ] All non-functional requirements satisfied
- [ ] All tests passing
- [ ] Code reviewed (if applicable)
- [ ] Documentation updated
- [ ] No known blockers remain

---

## 9. References

- **Workplan:** `/home/user/Hyperprompt/DOCS/Workplan.md` (Phase {N}, Section {TASK_ID})
- **PRD Authoring Rules:** `/home/user/Hyperprompt/DOCS/RULES/01_PRD_PROMPT.md`
- **Related Tasks:** {List of related task IDs}
- **Critical Path:** {Position on critical path, if applicable}

---

**Document Version:** 1.0
**Created:** {date}
**Status:** Ready for Execution
```

### Шаг 5: Обновить next.md (опционально)

Можно добавить ссылку на созданный PRD файл в `next.md`:

```markdown
# {TASK_ID} — {TASK_NAME}

**PRD:** `/home/user/Hyperprompt/DOCS/INPROGRESS/{TASK_ID}.md`
```

## Выходные данные

1. **PRD файл:** `/home/user/Hyperprompt/DOCS/INPROGRESS/{TASK_ID}.md`
2. **Отчет в консоль:**
   ```
   ✅ PRD created for task: A2 — Core Types Implementation
   📄 Location: /home/user/Hyperprompt/DOCS/INPROGRESS/A2.md
   📊 Structure:
      - 8 hierarchical phases
      - 23 atomic tasks
      - 12 acceptance criteria
      - 5 edge cases documented
   ⏱️  Total estimated effort: 4 hours
   🚀 Status: Ready for execution
   ```

## Исключения и граничные случаи

### Случай 1: next.md пуст или отсутствует
```
⚠️  No current task found in next.md
   Action: Run SELECT command first to choose a task
```

### Случай 2: Задача не найдена в Workplan
```
⚠️  Task {TASK_ID} not found in Workplan.md
   Action: Verify task ID is correct and exists in Workplan
```

### Случай 3: PRD файл уже существует
```
⚠️  PRD file already exists: DOCS/INPROGRESS/{TASK_ID}.md
   Options:
   - Use --overwrite flag to replace existing PRD
   - Use --append flag to add to existing PRD
   - Use different filename
```

### Случай 4: Недостаточно контекста в Workplan
```
⚠️  Insufficient context in Workplan for task {TASK_ID}
   Action: PRD created with basic structure, manual enrichment needed
   Note: Review and expand sections marked with [TODO]
```

## Контрольные вопросы

Перед выполнением команды убедитесь:

- [ ] Задача выбрана через SELECT и находится в `next.md`?
- [ ] У вас есть достаточно контекста о задаче из Workplan?
- [ ] Правила PRD в `01_PRD_PROMPT.md` актуальны?
- [ ] Готовы ли вы к детальному планированию задачи?

---

## Интеграция с рабочим процессом

### Типичный workflow:

1. **SELECT** → Выбрать следующую задачу из Workplan
2. **PLAN** → Создать детальный PRD для задачи
3. **EXECUTE** → Выполнить задачи из PRD
4. **VERIFY** → Проверить Definition of Done
5. **COMPLETE** → Пометить задачу как выполненную

### Пример использования:

```bash
# 1. Выбрать задачу
$ SELECT
✅ Selected: A2 — Core Types Implementation

# 2. Создать детальный план
$ PLAN
✅ PRD created: DOCS/INPROGRESS/A2.md
📊 23 atomic tasks identified

# 3. Начать выполнение
$ cat DOCS/INPROGRESS/A2.md
# Read the detailed plan and start executing...
```

---

**Версия:** 1.0.0
**Дата:** 2025-12-02
**Статус:** Active
