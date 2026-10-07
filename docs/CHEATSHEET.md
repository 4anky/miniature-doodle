# Шпаргалка героя

## Ветки

```bash
git switch main && git pull --ff-only       # обновить main
git switch -c quest/stage-1-village          # создать ветку и перейти на неё
git branch -vv                               # список веток и их upstream
git branch -d quest/stage-1-village          # удалить влитую ветку локально
git push origin --delete quest/stage-1-village  # удалить ветку на origin
git fetch --prune                            # забыть удалённые ветки, которых больше нет
```

## Коммиты

```bash
git status                     # что изменилось
git diff                       # изменения, ещё не добавленные в индекс
git diff --staged              # изменения в индексе
git add <файл>                 # добавить файл в индекс
git add -p                     # добавить изменения по кускам
git commit -m "feat(x): ..."   # закоммитить
git commit --amend             # исправить последний коммит (сообщение или содержимое)
git log --oneline --graph --all
```

## Файлы

```bash
git rm <файл>                  # удалить файл и сразу добавить удаление в индекс
git mv <старое> <новое>        # переименовать с сохранением истории
git log --follow -- <файл>     # история файла с учётом переименований
git restore <файл>             # отменить незакоммиченные изменения в файле
```

## Push и PR

```bash
git push -u origin HEAD                       # первый пуш ветки
git push --force-with-lease                   # пуш после rebase/amend
gh pr create --base main --fill               # создать PR (GitHub CLI)
gh pr checks                                  # статус проверок
gh pr merge --rebase --delete-branch          # влить PR
```

## Rebase и конфликты

```bash
git fetch origin
git rebase origin/main         # переставить свои коммиты поверх свежего main
# ...конфликт: правим файлы, убираем маркеры <<<<<<< ======= >>>>>>>
git add <файл>
git rebase --continue          # или git rebase --abort, чтобы всё отменить
git rebase -i origin/main      # интерактивно: squash / fixup / reword / drop
```

## Stash

```bash
git stash push -m "описание"   # спрятать незакоммиченные изменения
git stash list
git stash pop                  # вернуть последние спрятанные изменения
```

## Cherry-pick и теги

```bash
git log --oneline experiment/spells
git cherry-pick -x <sha>                       # перенести коммит, указав источник
git tag -a v1.0.0 -m "Гитландия спасена"       # аннотированный тег
git push origin v1.0.0
git show v1.0.0
```
