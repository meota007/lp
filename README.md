# LP — Monorepo das Landing Pages

Repositorio central com as 3 LPs copiadas dos repositorios originais.

## Estrutura

```
lp/
├── feridas-emocionais/      <- copiado de lp-feridas-emocionais
│   ├── index.html
│   └── assets/
├── refem-das-emocoes/       <- copiado de lp-refem-das-emocoes
│   ├── index.html
│   ├── index-v1.html
│   └── assets/
├── ebook-crianca-interior/  <- copiado de lp-ebook-crianca-interior
│   ├── index.html
│   └── assets/
├── atualizar.sh
├── index.html           <- home com links para as 3 LPs
└── README.md
```

## Origem

- `feridas-emocionais`: https://github.com/meota007/lp-feridas-emocionais
- `refem-das-emocoes`: https://github.com/meota007/lp-refem-das-emocoes
- `ebook-crianca-interior`: https://github.com/meota007/lp-ebook-crianca-interior

Copia feita em 2026-11-21. Arquivos `.git` dos repos de origem foram excluidos — apenas os arquivos das paginas foram copiados.

---

## Prompt inicial (criacao)

Usado para criar este repo:

```
Preciso que vc crie um repo no meu git chamado lp e depois copie os arquivos dos seguintes repositórios para o repo lp.

https://github.com/meota007/lp-feridas-emocionais
https://github.com/meota007/lp-refem-das-emocoes
https://github.com/meota007/lp-ebook-crianca-interior

O repo lp precisa ficar organizado separando os repo copiaos em pastas

feridas-emocionais
refem-das-emocoes
ebook-crianca-interior
```

## Prompt de atualizacao (reuso)

Use este prompt quando quiser sincronizar o `lp` com o estado atual dos 3 repos de origem:

```
Atualize o repo meota007/lp com o conteudo atual dos repositorios:

- https://github.com/meota007/lp-feridas-emocionais -> pasta feridas-emocionais/
- https://github.com/meota007/lp-refem-das-emocoes -> pasta refem-das-emocoes/
- https://github.com/meota007/lp-ebook-crianca-interior -> pasta ebook-crianca-interior/

Regras:
1. Nao apague o README.md, o index.html da raiz nem o atualizar.sh.
2. Copie todos os arquivos de cada repo de origem para a pasta correspondente, excluindo a pasta .git.
3. Use --delete / limpeza para que arquivos removidos na origem saiam do lp tambem.
4. Commit com mensagem "Sincroniza LPs com repos de origem em <data>" e push para main.
```

## Prompt quando o repo lp ja existe (sempre clonar antes de atualizar)

Objetivo: garantir que voce parte sempre da versao mais atual do `lp`. Apaga clone antigo (se houver), clona do zero e so depois sincroniza como no reuso.

```
O repo meota007/lp ja existe no GitHub. Antes de atualizar, clone do zero para garantir a versao mais atual:

1. Apague qualquer clone antigo do lp nesta maquina (se existir) e clone novamente:
git clone git@github.com:meota007/lp.git
cd lp
(ou: gh repo clone meota007/lp lp)

2. Com o clone novo em maos, atualize com o conteudo atual dos repositorios:
- https://github.com/meota007/lp-feridas-emocionais -> pasta feridas-emocionais/
- https://github.com/meota007/lp-refem-das-emocoes -> pasta refem-das-emocoes/
- https://github.com/meota007/lp-ebook-crianca-interior -> pasta ebook-crianca-interior/

3. Regras:
- Nao apague o README.md, o index.html da raiz nem o atualizar.sh.
- Exclua a pasta .git das origens na copia.
- Espelhe as pastas (arquivo removido na origem sai do lp tambem).
4. Depois rode: git add -A, commit "Sincroniza LPs com repos de origem em <data>" e push para main.
5. Se nao houver mudanca (git diff --cached --quiet), nao commite e avise "lp ja esta sincronizado".
```

## Script via SSH para atualizar (atualizar.sh)

Script bash que roda em qualquer servidor Linux com acesso SSH ao GitHub (`git@github.com`). Ele clona (ou atualiza) os 4 repos via SSH, sincroniza as pastas e faz commit + push.

Uso:

```bash
chmod +x atualizar.sh
./atualizar.sh
```

Conteudo do script esta no arquivo `atualizar.sh` na raiz deste repo. Copia abaixo para referencia:

```bash
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
```
