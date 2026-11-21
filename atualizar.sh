#!/bin/bash
set -e
# Sincroniza meota007/lp com os 3 repos de origem via SSH.
# Requisito: chave SSH cadastrada no GitHub com acesso aos 4 repos.

BASE="$HOME/lp-sync"
mkdir -p "$BASE"
cd "$BASE"

sync_repo() {
  local repo="$1"
  local dir="$2"
  if [ -d "$dir/.git" ]; then
    echo "==> Atualizando $dir"
    git -C "$dir" pull --rebase
  else
    echo "==> Clonando $repo"
    rm -rf "$dir"
    git clone "$repo" "$dir"
  fi
}

sync_repo "git@github.com:meota007/lp.git" "lp"
sync_repo "git@github.com:meota007/lp-feridas-emocionais.git" "src-feridas"
sync_repo "git@github.com:meota007/lp-refem-das-emocoes.git" "src-refem"
sync_repo "git@github.com:meota007/lp-ebook-crianca-interior.git" "src-ebook"

# Garante branch main no lp
git -C lp rev-parse --verify main >/dev/null 2>&1 || git -C lp checkout -b main
git -C lp checkout main

# Sincroniza cada pasta (espelha origem, excluindo .git)
for par in "src-feridas:feridas-emocionais" "src-refem:refem-das-emocoes" "src-ebook:ebook-crianca-interior"; do
  src="${par%%:*}"
  dst="lp/${par##*:}"
  echo "==> Sincronizando $src -> $dst"
  mkdir -p "$dst"
  if command -v rsync >/dev/null 2>&1; then
    rsync -a --delete --exclude='.git' "$src/" "$dst/"
  else
    # Fallback sem rsync: limpa destino e copia tudo (preserva README.md e atualizar.sh na raiz, pois so toca nas subpastas)
    rm -rf "$dst"
    mkdir -p "$dst"
    cp -a "$src/." "$dst/"
    rm -rf "$dst/.git"
  fi
done

cd lp
git add -A
if git diff --cached --quiet; then
  echo "Nada para atualizar. lp ja esta sincronizado."
else
  DATA=$(date +%Y-%m-%d)
  git commit -m "Sincroniza LPs com repos de origem em $DATA"
  git push origin main
  echo "Push concluido."
fi
