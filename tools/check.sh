#!/usr/bin/env bash
# Проверка прохождения этапов квеста «Хроники Гитландии».
#
# Использование:
#   tools/check.sh          — номер этапа определяется по имени текущей ветки
#   tools/check.sh <1-5>    — проверить конкретный этап
#   tools/check.sh final    — финальная проверка (тег v1.0.0)
#
# Переменные окружения:
#   BASE_REF  — с чем сравнивать ветку (по умолчанию origin/main)
#   GITHUB_HEAD_REF — имя ветки PR (выставляется GitHub Actions)

set -uo pipefail

cd "$(git rev-parse --show-toplevel)" || exit 2

BASE_REF="${BASE_REF:-origin/main}"
BRANCH="${GITHUB_HEAD_REF:-$(git rev-parse --abbrev-ref HEAD)}"
CC_RE='^(feat|fix|docs|style|refactor|test|chore)(\([a-z0-9-]+\))?!?: .+'

FAILS=0

ok()   { printf '  \033[32m✔\033[0m %s\n' "$1"; }
fail() { printf '  \033[31m✘\033[0m %s\n' "$1"; FAILS=$((FAILS + 1)); }

# check <описание> <команда...> — успех, если команда завершилась с кодом 0
check() {
    local desc=$1
    shift
    if "$@" >/dev/null 2>&1; then ok "$desc"; else fail "$desc"; fi
}

has()     { grep -qE -- "$2" "$1"; }
has_not() { [ -f "$1" ] && ! grep -qE -- "$2" "$1"; }
absent()  { [ ! -e "$1" ]; }

commit_count() { git rev-list --count --no-merges "$BASE..HEAD"; }

check_min_commits() {
    local n
    n=$(commit_count)
    if [ "$n" -ge "$1" ]; then ok "Коммитов в ветке: $n (нужно не меньше $1)"
    else fail "Коммитов в ветке: $n (нужно не меньше $1)"; fi
}

check_branch_name() {
    if [[ $BRANCH =~ ^quest/stage-$1-[a-z0-9-]+$ ]]; then ok "Имя ветки: $BRANCH"
    else fail "Имя ветки «$BRANCH» не соответствует шаблону quest/stage-$1-<описание>"; fi
}

check_commit_messages() {
    local subj bad=0
    while IFS= read -r subj; do
        if [[ ! $subj =~ $CC_RE ]]; then
            fail "Сообщение не по Conventional Commits: «$subj»"
            bad=1
        fi
    done < <(git log --no-merges --format=%s "$BASE..HEAD")
    [ "$bad" -eq 0 ] && ok "Сообщения коммитов по Conventional Commits"
}

check_no_merges() {
    local n
    n=$(git rev-list --count --merges "$BASE..HEAD")
    if [ "$n" -eq 0 ]; then ok "В ветке нет merge-коммитов"
    else fail "В ветке есть merge-коммиты ($n) — актуализируй ветку через rebase"; fi
}

check_no_conflict_markers() {
    check "Нет маркеров конфликта в world/" \
        bash -c '! grep -rqE "^(<<<<<<<|=======|>>>>>>>)" world inventory'
}

stage_1() {
    check "Опечатка в названии королевства исправлена" \
        has_not world/village/notice-board.md 'Гитландиа'
    check "Опечатка в глаголе исправлена" \
        has_not world/village/notice-board.md 'похител'
    check "Имя героя заполнено" has world/village/hero.md '^Имя: [^<[:space:]]'
    check "Класс героя — воин, маг или лучник" \
        has world/village/hero.md '^Класс: (воин|маг|лучник)[[:space:]]*$'
    check "Девиз заполнен" has world/village/hero.md '^Девиз: [^<[:space:]]'
    check_min_commits 2
}

stage_2() {
    check "Факел в инвентаре" has inventory/torch.md '^Предмет: факел'
    check "Проклятый гриб уничтожен" absent world/forest/cursed-mushroom.txt
    check "old_bridge.txt больше нет" absent world/forest/old_bridge.txt
    check "git распознаёт переименование old_bridge.txt → bridge.md" \
        bash -c "git diff -M --name-status '$BASE' HEAD \
            | grep -qE '^R[0-9]+[[:space:]]+world/forest/old_bridge.txt[[:space:]]+world/forest/bridge.md$'"
    check "Тролль доволен паролем" has world/forest/bridge.md '^Пароль: git log[[:space:]]*$'
    check_min_commits 3
}

stage_3() {
    case $BRANCH in
        */stage-3-fire)
            check "Огненная руна на месте" has world/mountains/rune-gate.md '^RUNE: огонь$'
            ;;
        */stage-3-ice)
            check "Руны объединены" has world/mountains/rune-gate.md '^RUNE: огонь\+лёд$'
            check "Ветка основана на актуальном $BASE_REF" \
                git merge-base --is-ancestor "$BASE_REF" HEAD
            check_no_merges
            ;;
        *)
            fail "На этапе 3 ветка должна называться quest/stage-3-fire или quest/stage-3-ice"
            ;;
    esac
    check_no_conflict_markers
    check_min_commits 1
}

stage_4() {
    check "Все строфы дописаны" has_not world/castle/scroll.md '___'
    check "Три непустые строфы" \
        bash -c "[ \$(grep -cE '^Строфа [123]: [^_[:space:]]' world/castle/scroll.md) -eq 3 ]"
    local n
    n=$(commit_count)
    if [ "$n" -eq 1 ]; then ok "В ветке ровно один коммит"
    else fail "В ветке $n коммитов, а стража примет ровно один (git rebase -i)"; fi
}

stage_5() {
    check "Ледяное копьё в книге заклинаний" has world/dragon-lair/spells.md '^- Ледяное копьё$'
    check "Огненного шара в книге нет" has_not world/dragon-lair/spells.md 'Огненный шар'
    check "Коммит перенесён через cherry-pick -x" \
        bash -c "git log --format=%B '$BASE..HEAD' | grep -q 'cherry picked from commit'"
    check_no_conflict_markers
}

final() {
    check "Тег v1.0.0 существует" git rev-parse -q --verify refs/tags/v1.0.0
    check "Тег v1.0.0 аннотированный" \
        bash -c '[ "$(git cat-file -t v1.0.0)" = tag ]'
    check "Тег v1.0.0 стоит на коммите из $BASE_REF" \
        git merge-base --is-ancestor v1.0.0 "$BASE_REF"
    check "Тег v1.0.0 запушен на origin" \
        git ls-remote --exit-code --tags origin refs/tags/v1.0.0
}

stage=${1:-}
if [ -z "$stage" ]; then
    if [[ $BRANCH =~ ^quest/stage-([1-5])- ]]; then
        stage=${BASH_REMATCH[1]}
    else
        echo "Ветка «$BRANCH» не относится к квесту — проверять нечего."
        echo "Укажи этап явно: tools/check.sh <1-5|final>"
        exit 0
    fi
fi

if ! git rev-parse -q --verify "$BASE_REF" >/dev/null; then
    echo "Не найден $BASE_REF. Выполни git fetch origin." >&2
    exit 2
fi
BASE=$(git merge-base "$BASE_REF" HEAD)

case $stage in
    [1-5])
        echo "Этап $stage — ветка $BRANCH"
        check_branch_name "$stage"
        check_commit_messages
        "stage_$stage"
        ;;
    final)
        echo "Финал"
        final
        ;;
    *)
        echo "Неизвестный этап: $stage" >&2
        exit 2
        ;;
esac

echo
if [ "$FAILS" -eq 0 ]; then
    if [ "$stage" = final ]; then
        echo "🏆 Главный Коммит возвращён. Гитландия спасена!"
    else
        echo "Этап пройден! Можно пушить и открывать Pull Request."
    fi
else
    echo "Не выполнено условий: $FAILS"
    exit 1
fi
