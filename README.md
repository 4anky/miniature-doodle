# miniature-doodle — «Хроники Гитландии»

Тренировочный репозиторий для отработки промышленного git workflow в формате текстового квеста.

Королевство **Гитландия** в беде: дракон похитил Главный Коммит, и только герой, владеющий
ветками, ребейзами и pull request'ами, может его вернуть. Каждый этап квеста — это отдельная
задача, которую нужно выполнить **строго по правилам командной разработки**:

1. создать feature-ветку от актуального `main`;
2. внести изменения в файлы мира (`world/`);
3. закоммитить их с правильным сообщением;
4. запушить ветку на `origin`;
5. открыть Pull Request в `main`, дождаться зелёной проверки CI и смёржить.

## Карта приключения

| Этап | Локация                      | Ветка(и)                                        | Навыки                                              |
|------|------------------------------|-------------------------------------------------|-----------------------------------------------------|
| 1    | Деревня (`world/village`)    | `quest/stage-1-village`                         | branch, add, commit, push, PR                       |
| 2    | Лес (`world/forest`)         | `quest/stage-2-forest`                          | несколько коммитов, `git rm`, `git mv`              |
| 3    | Горы (`world/mountains`)     | `quest/stage-3-fire`, `quest/stage-3-ice`       | параллельные ветки, `rebase`, разрешение конфликта, `push --force-with-lease` |
| 4    | Замок (`world/castle`)       | `quest/stage-4-castle`                          | `stash`, `commit --amend`, `rebase -i` (squash)     |
| 5    | Логово дракона (`world/dragon-lair`) | `experiment/spells`, `quest/stage-5-dragon` | `cherry-pick -x`, аннотированный тег, релиз    |

Задания лежат в папке [`quests/`](quests/). Начинай с [`quests/stage-1.md`](quests/stage-1.md).

## Структура

```
.
├── world/            # мир игры — здесь ты вносишь изменения
│   ├── village/
│   ├── forest/
│   ├── mountains/
│   ├── castle/
│   └── dragon-lair/
├── inventory/        # инвентарь героя
├── quests/           # описания этапов
├── docs/             # правила workflow и шпаргалка
├── tools/check.sh    # проверка прохождения этапа (её же запускает CI)
└── .github/          # шаблон PR и workflow проверки
```

## Правила игры

Все правила командной работы описаны в [`docs/GIT_WORKFLOW.md`](docs/GIT_WORKFLOW.md), шпаргалка
по командам — в [`docs/CHEATSHEET.md`](docs/CHEATSHEET.md). Коротко:

- **Никаких коммитов напрямую в `main`.** Только через Pull Request.
- Имя ветки: `quest/stage-<N>-<описание>`.
- Сообщения коммитов — по [Conventional Commits](https://www.conventionalcommits.org/ru/):
  `feat(village): записать героя в книгу`.
- Перед пушем запусти локальную проверку:

  ```bash
  tools/check.sh        # номер этапа определяется по имени ветки
  tools/check.sh 2      # или укажи его явно
  ```

## Подготовка (один раз, для владельца репозитория)

Чтобы тренировка была «как на проде», включи в GitHub:

1. **Settings → Branches → Add branch ruleset** для `main`:
   - *Require a pull request before merging*;
   - *Require status checks to pass* → выбери проверку `quest-check`;
   - *Block force pushes*.
2. **Settings → Actions → General** — убедись, что Actions разрешены.
3. **Settings → General → Pull Requests** — оставь включёнными *Allow merge commits*,
   *Allow squash merging* и *Allow rebase merging*: на разных этапах пригодятся разные стратегии.

## Как начать заново

Квест можно пройти повторно: создай ветку от первого коммита с игрой
(`git log --oneline -- quests/`) или просто откати файлы из `world/` и `inventory/` к исходному
состоянию отдельным PR — это тоже хорошая тренировка (`git restore --source=<commit> -- world/`).
