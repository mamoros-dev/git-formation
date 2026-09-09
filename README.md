# Chuleta de Git — Curso completo

## Módulo 1 — Fundamentos

**Configuración inicial**
```bash
git config --global user.name "Tu Nombre"
git config --global user.email "tu-email@ejemplo.com"
git config --global init.defaultBranch main
git config --global core.editor "nano"   # o el editor que prefieras
git config --global pull.rebase true     # pull siempre con rebase por defecto
```

**Las 3 zonas de Git**

| Zona | Qué contiene | Comando para avanzar |
|---|---|---|
| Working directory | Cambios sin trackear | `git add` |
| Staging (index) | Lo que entrará en el próximo commit | `git commit` |
| Repository | Historial ya confirmado | — |

**Staging interactivo**
```bash
git add -p archivo.tf
```
- `y` → stage este hunk · `n` → sáltalo · `s` → dividir en trozos más pequeños (si hay líneas de contexto sin modificar entre medio) · `e` → editar el hunk manualmente (cuando `s` no es suficiente) · `q` → salir

**Conventional Commits**
```
<tipo>(<scope opcional>): <descripción corta en imperativo>

[cuerpo opcional]

[BREAKING CHANGE: descripción]   ← footer, separado por línea en blanco
```

| Tipo | Cuándo se usa |
|---|---|
| `feat` | Nueva funcionalidad (bump MINOR) |
| `fix` | Corrección de bug (bump PATCH) |
| `docs` | Documentación |
| `chore` | Mantenimiento, dependencias, configuración |
| `refactor` | Reestructurar código sin cambiar comportamiento externo |
| `test` | Añadir/corregir tests |
| `ci` | Cambios en pipelines |
| `perf` | Mejora de rendimiento |
| `style` | Formato, sin cambio de lógica |
| `build` | Sistema de build o dependencias externas |

Breaking change → `tipo(scope)!: descripción` + footer `BREAKING CHANGE: ...`
Se puede escribir en un solo commit con dos `-m`:
```bash
git commit -m "feat(api)!: remove deprecated endpoint" -m "BREAKING CHANGE: los clientes deben migrar a /v2"
```

---

## Módulo 2 — Ramas y flujos

```bash
git switch -c nombre-rama     # crea y cambia a una rama (sustituye a checkout -b)
git switch nombre-rama        # cambia de rama
```

**Merge**
- **Fast-forward**: la rama destino no tiene commits propios → Git solo adelanta el puntero
- **3-way**: ambas ramas divergieron → crea un commit de merge con 2 padres (se ve como "diamante" en `git log --graph`)

**Conflictos de merge**
```
<<<<<<< HEAD
versión de tu rama actual
=======
versión de la rama que fusionas
>>>>>>> otra-rama
```
Edita a mano, elimina las marcas, `git add archivo` → `git status` debe decir *"All conflicts fixed"* → `git commit` (sin `-m`, deja el mensaje autogenerado).

**Rebase**
```bash
git rebase main          # reescribe tus commits sobre main (historial lineal)
git rebase -i HEAD~n     # rebase interactivo: pick / squash / reword / drop
```
🔴 **Regla de oro**: nunca rebasees una rama ya compartida/pusheada que otros hayan descargado — solo ramas personales.

**`HEAD~n`**: n commits hacia atrás desde HEAD (`HEAD~3` = 3 commits antes; `rebase -i HEAD~3` deja editables los 3 commits entre ese punto y HEAD).

**Modelos de flujo**
- **GitHub Flow**: una sola rama larga (`main`), toda feature nace y vuelve ahí vía PR, ideal con CI/CD continuo
- **Git Flow**: `main` + `develop` + ramas `feature/*`, `release/*`, `hotfix/*` — para releases planificadas

---

## Módulo 3 — Remoto y colaboración

```bash
git fetch              # descarga referencias del remoto, NO mezcla nada
git pull --rebase      # fetch + rebase (historial lineal, evita diamantes)
git push -u origin rama   # primera vez que subes una rama (vincula el upstream)
git push                  # las siguientes veces, sin -u
```

**Anatomía de una PR profesional**
```markdown
## What / Qué hace este cambio
## Why / Por qué (contexto, ticket, problema que resuelve)
## How to test / Cómo probarlo (comando + output esperado)
## Checklist
- [ ] tests / documentación / migración de estado
```
- Una PR se actualiza sola con cada `push` a la misma rama — nunca abrir una nueva
- Comentarios de review: `[blocking]` (debe cambiar) vs `[nit]` (sugerencia opcional) — responde siempre con la acción tomada, nunca dejes un comentario sin respuesta

**Tags y SemVer**
```bash
git tag -a v1.0.0 -m "mensaje del release"   # annotated (recomendado)
git push origin v1.0.0                        # los tags no se suben con push normal
git show v1.0.0
```
SemVer → `MAJOR.MINOR.PATCH`: MAJOR = breaking change, MINOR = `feat`, PATCH = `fix`

---

## Módulo 4 — Herramientas avanzadas

```bash
git stash push -m "nombre descriptivo"   # guarda cambios sin confirmar
git stash list
git stash pop     # aplica y BORRA el stash
git stash apply   # aplica y lo CONSERVA
```

| Comando | Deshace | Nivel | ¿Reescribe historial? |
|---|---|---|---|
| `git restore <archivo>` | Cambios sin confirmar | Archivo | No |
| `git reset --soft/--mixed/--hard HEAD~n` | Mueve el puntero de rama | Rama completa | Sí — solo si NO está pusheado |
| `git revert <hash>` | Crea commit nuevo que deshace otro | Rama completa | No — seguro para commits ya compartidos |

```bash
git cherry-pick <hash>          # trae un commit puntual de otra rama
git cherry-pick --continue      # tras resolver un conflicto
```

```bash
git bisect start
git bisect bad HEAD             # commit donde está roto
git bisect good <hash-antiguo>  # commit donde funcionaba bien
# ... Git te lleva al punto medio; marca good/bad hasta encontrar el culpable ...
git bisect reset                # sal del modo bisect al terminar
```

**`.gitignore` — seguridad**
```gitignore
# Terraform
*.tfstate
*.tfstate.*.backup
.terraform/
.terraform.lock.hcl
*.tfvars

# Credenciales
.env
*.pem
*.key
credentials.json
```
Si ya se subió un secreto: **rotar la credencial** siempre, y purgar el historial con `git filter-repo` o BFG (un simple `git rm` + commit no es suficiente).

---

## Módulo 5 — Nivel profesional

**Git Hooks con Husky + commitlint + lint-staged**
```bash
npm init -y
npm install --save-dev @commitlint/cli @commitlint/config-conventional husky lint-staged
npx husky init

# commitlint.config.js
cat > commitlint.config.js << 'EOF'
export default { extends: ['@commitlint/config-conventional'] };
EOF

# hook commit-msg → valida el mensaje del commit
cat > .husky/commit-msg << 'EOF'
npx --no -- commitlint --edit $1
EOF

# .lintstagedrc.json → valida/formatea solo archivos en staging
cat > .lintstagedrc.json << 'EOF'
{
  "*.tf": "terraform fmt -check"
}
EOF

# hook pre-commit → ejecuta lint-staged
cat > .husky/pre-commit << 'EOF'
npx lint-staged
EOF
```
- `.husky/` vive en el repo (se comparte con el equipo) — a diferencia de `.git/hooks/`, que es local
- `pre-commit` se ejecuta antes de pedir el mensaje; `commit-msg` se ejecuta después, para validarlo

**GitHub Actions**
```yaml
# .github/workflows/terraform-check.yml
name: Terraform Format Check

on:
  push:
    branches: [main]

jobs:
  check-format:
    runs-on: ubuntu-latest
    steps:
      - name: Checkout code
        uses: actions/checkout@v4
      - name: Setup Terraform
        uses: hashicorp/setup-terraform@v3
      - name: Check formatting
        run: terraform fmt -check -recursive
```
- No requiere repo público (funciona igual en privados; solo cambian los minutos gratis de ejecución)
- `uses:` = acción ya hecha por otros · `run:` = comando de terminal directo

**Diagnóstico avanzado**
```bash
git log --pretty=format:"%h | %an | %ar | %s" -5   # log personalizado
git log --author="Nombre" --oneline                 # filtrar por autor
git blame archivo.tf                                # quién tocó cada línea por última vez
git reflog                                           # red de seguridad: recupera casi cualquier "pérdida"
```

---

## Fuentes oficiales de referencia

- Plantillas `.gitignore`: https://github.com/github/gitignore
- Ignoring files (GitHub Docs): https://docs.github.com/en/get-started/git-basics/ignoring-files
- Conventional Commits (spec): https://www.conventionalcommits.org/en/v1.0.0/
- Semantic Versioning: https://semver.org/
- Husky: https://typicode.github.io/husky/
- commitlint: https://commitlint.js.org/
- lint-staged: https://github.com/okonet/lint-staged
- GitHub Actions: https://docs.github.com/en/actions
- Pro Git (libro oficial y gratuito): https://git-scm.com/book/en/v2