# SELECT — Выбор следующей задачи для выполнения

## Цель

Автоматический выбор следующей оптимальной задачи из плана работ (`DOCS/Workplan.md`) на основе приоритетов, зависимостей и текущего прогресса.

## Входные данные

- **Workplan:** `/home/user/Hyperprompt/DOCS/Workplan.md` — основной план работ с иерархией фаз и задач
- **Current Task:** `/home/user/Hyperprompt/DOCS/INPROGRESS/next.md` — текущая задача в процессе выполнения

## Алгоритм выбора

### Шаг 1: Определить статус текущей задачи

1. Прочитать `DOCS/INPROGRESS/next.md`
2. Определить ID текущей задачи (например, `A1`, `A2`, `B1`, и т.д.)
3. Проверить в `DOCS/Workplan.md`, помечена ли задача как выполненная `[x]`

### Шаг 2: Найти кандидатов для следующей задачи

Сканировать `DOCS/Workplan.md` и отобрать задачи, которые удовлетворяют **всем** условиям:

#### Условие 0: Задача не выполнена
```markdown
- [ ] ❌ НЕ выполнена (чекбокс пустой)
- [x] ✅ Выполнена (исключить)
```

#### Условие 1: Зависимости удовлетворены

Для каждой задачи проверить поле **Dependencies:**
- Если `Dependencies: None` → ✅ готова к выполнению
- Если `Dependencies: A1` → проверить, что задача A1 помечена `[x]` в Workplan
- Если `Dependencies: A1, A2` → проверить, что **все** зависимости выполнены

#### Условие 2: Приоритет

Задачи имеют три уровня приоритета:
- **[P0] Critical** — критически важные, блокируют весь проект
- **[P1] High** — важные для core функциональности
- **[P2] Medium** — желательные, могут быть отложены

**Правило:** Среди кандидатов выбирать задачу с **наивысшим приоритетом** (P0 > P1 > P2).

#### Условие 3: Критический путь

Если несколько задач имеют одинаковый приоритет, предпочитать задачи на **критическом пути**:
```
A1 → A2 → A4 → B4 → C2 → D2 → E1 → Release
```

Задачи на критическом пути имеют пометку в комментариях или описаны в секции `## 📊 Critical Path Analysis`.

#### Условие 4: Последовательность в плане

Если остались равноценные кандидаты, выбрать задачу, которая **ближе всего** к последней выполненной в линейном порядке Workplan.

### Шаг 3: Сформировать next.md

После выбора задачи создать детальный файл `/home/user/Hyperprompt/DOCS/INPROGRESS/next.md` со следующей структурой:

```markdown
# Next Task: {TASK_ID} — {TASK_NAME}

**Priority:** {PRIORITY_LEVEL}
**Phase:** {PHASE_NUMBER} — {PHASE_NAME}
**Track:** {TRACK_ID} (Track Name)
**Estimated Time:** {HOURS} hours
**Dependencies:** {DEPENDENCIES_LIST}
**Blocks:** {BLOCKED_TASKS_LIST}

---

## Description

{Детальное описание задачи и её роли в проекте}

---

## Tasks Checklist

- [ ] {Subtask 1}
  - [ ] {Sub-subtask 1.1}
  - [ ] {Sub-subtask 1.2}
- [ ] {Subtask 2}
- [ ] {Subtask 3}

---

## Acceptance Criteria

✅ {Criterion 1}
✅ {Criterion 2}
✅ {Criterion 3}

---

## Next Task After Completion

**{NEXT_TASK_ID}: {NEXT_TASK_NAME} [{PRIORITY}]**
- Dependencies: {THIS_TASK_ID}
- Estimated: {HOURS} hours
- {Brief description}

---

## References

- **Workplan:** `/home/user/Hyperprompt/DOCS/Workplan.md` (Phase {N}, Section {TASK_ID})
- **PRD:** Relevant PRD sections
- **Critical Path:** {Position on critical path}
```

### Шаг 4: Обновить Workplan.md

Пометить выбранную задачу как **в процессе выполнения**:

**Было:**
```markdown
### A2: Core Types Implementation **[P0]**
**Dependencies:** A1
```

**Стало:**
```markdown
### A2: Core Types Implementation **[P0]** **INPROGRESS**
**Dependencies:** A1 ✅
```

## Выходные данные

1. **Обновленный файл:** `/home/user/Hyperprompt/DOCS/INPROGRESS/next.md`
2. **Обновленный Workplan:** Задача помечена маркером `**INPROGRESS**`
3. **Отчет в консоль:**
   ```
   ✅ Selected next task: A2 — Core Types Implementation [P0]
   📍 Phase: 1 — Foundation & Core Types
   ⏱️  Estimated: 4 hours
   🔗 Dependencies: A1 ✅
   📄 Details: /home/user/Hyperprompt/DOCS/INPROGRESS/next.md
   ```

## Исключения и граничные случаи

### Случай 1: Нет доступных задач
Если все задачи либо выполнены, либо заблокированы зависимостями:
```
⚠️  No available tasks found.
   Reason: All tasks are either completed or blocked by dependencies.
   Action: Review Workplan.md for potential circular dependencies.
```

### Случай 2: Несколько задач с P0
Если найдено несколько задач с приоритетом [P0], выбрать первую на **критическом пути**.

### Случай 3: Параллельные треки
Workplan содержит два независимых трека (A: Core Compiler, B: Specifications). Если задачи из разных треков имеют одинаковый приоритет, предпочесть **Track A** (критический путь).

### Случай 4: Текущая задача не завершена
Если в `next.md` есть задача, но она не помечена `[x]` в Workplan:
```
⚠️  Current task A1 is still in progress.
   Action: Complete current task before selecting next.
   Use: COMPLETE command to mark task as done.
```

## Связанные команды

- **COMPLETE** — пометить текущую задачу как выполненную
- **STATUS** — показать общий прогресс по Workplan
- **DEPENDS** — показать граф зависимостей для задачи
- **CRITICAL** — показать задачи на критическом пути

## Примеры использования

### Пример 1: Выбор первой задачи
```bash
$ SELECT
✅ Selected next task: A1 — Project Initialization [P0]
📍 Phase: 1 — Foundation & Core Types
⏱️  Estimated: 2 hours
🔗 Dependencies: None (entry point)
📄 Details: /home/user/Hyperprompt/DOCS/INPROGRESS/next.md
```

### Пример 2: Выбор после завершения A1
```bash
$ SELECT
✅ Selected next task: A2 — Core Types Implementation [P0]
📍 Phase: 1 — Foundation & Core Types
⏱️  Estimated: 4 hours
🔗 Dependencies: A1 ✅
📄 Details: /home/user/Hyperprompt/DOCS/INPROGRESS/next.md
```

### Пример 3: Параллельная работа
```bash
$ SELECT --track=B
✅ Selected next task: B1 — HypercodeGrammar Core Spec [P1]
📍 Phase: 3 — Specifications (Track B)
⏱️  Estimated: 8 hours
🔗 Dependencies: A2 ✅
💡 Can be executed in parallel with Track A tasks
📄 Details: /home/user/Hyperprompt/DOCS/INPROGRESS/next.md
```

## Техническая реализация

Команда может быть реализована как:
1. **Shell-скрипт** с парсингом Markdown
2. **Python-скрипт** с использованием библиотеки `mistune` или `markdown-it-py`
3. **LLM-агент** с доступом к файловой системе

### Псевдокод

```python
def select_next_task():
    workplan = read_file("DOCS/Workplan.md")
    current_task = read_file("DOCS/INPROGRESS/next.md")

    # Parse current task ID
    current_id = extract_task_id(current_task)

    # Check if current task is completed
    if not is_completed(workplan, current_id):
        return error("Current task not completed")

    # Parse all tasks from workplan
    tasks = parse_tasks(workplan)

    # Filter candidates
    candidates = []
    for task in tasks:
        if not task.is_completed and all_dependencies_met(task, workplan):
            candidates.append(task)

    if not candidates:
        return error("No available tasks")

    # Sort by priority, critical path, position
    candidates.sort(key=lambda t: (
        -priority_score(t.priority),  # P0=3, P1=2, P2=1
        -on_critical_path(t),          # 1 if on critical path, 0 otherwise
        task_position(t)               # Linear position in workplan
    ))

    # Select best candidate
    next_task = candidates[0]

    # Generate next.md
    generate_next_md(next_task)

    # Update workplan with INPROGRESS marker
    update_workplan(workplan, next_task, marker="**INPROGRESS**")

    return next_task
```

## Контрольные вопросы

Перед выполнением команды убедитесь:

- [ ] Текущая задача в `next.md` действительно завершена?
- [ ] Workplan актуален и содержит все зависимости?
- [ ] Критический путь учтен при выборе?
- [ ] Если есть параллельные треки, выбран правильный трек?

---

**Версия:** 1.0.0
**Дата:** 2025-12-02
**Статус:** Active
