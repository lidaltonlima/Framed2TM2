# Arquitetura do Motor de Cálculo Estrutural (Fortran) — Pórtico Espacial 3D

## 0. Resumo executivo

| Decisão | Recomendação |
|---|---|
| Paradigma no Fortran | Fortran moderno (2008/2018): `type`, `extends`, `abstract`, `procedure(...)`, `class(...)` |
| Arquitetura interna | 3 camadas: **Modelagem** → **Solução** → **Resultados**, mais uma camada transversal de **I/O/API** |
| Conexão com front-end | Motor **isolado do Python** — comunica só por **JSON** (entrada e saída), sem acoplamento a GUI |
| Formato de integração v1 | Executável CLI (`motor.exe entrada.json saida.json`) chamado via `subprocess` no Python |
| Formato de integração v2 | Biblioteca compartilhada (`.dll/.so`) com fachada `iso_c_binding`, chamada via `ctypes`/`cffi` |
| Não-linearidade (tração/compressão) | Iterativo tipo "birth-death element" (remoção/reativação de rigidez) |
| Libs externas | LAPACK/BLAS, json-fortran, gerenciadas via `fpm` (Fortran Package Manager) |

A ideia central: **o motor Fortran deve funcionar 100% sozinho, via linha de comando, sem Electron/Python/React**. Isso facilita testes, validação com casos analíticos, versionamento independente e até reuso futuro (ex: rodar em nuvem, batch, CI).

---

## 1. Estrutura básica do motor (camadas)

```
┌─────────────────────────────────────────────────────────────┐
│  CAMADA 4 — API / I/O                                        │
│  Fachada C (iso_c_binding) + leitura/escrita JSON             │
│  mod_json_io.f90, api_c.f90                                   │
└─────────────────────────────────────────────────────────────┘
                    ▲                        │
                    │ recebe modelo          │ devolve resultados
                    │                        ▼
┌─────────────────────────────────────────────────────────────┐
│  CAMADA 1 — MODELAGEM (pré-processamento)                     │
│  No, Material, Secao, Elemento(s), Apoio, Cargas, Modelo       │
└─────────────────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│  CAMADA 2 — SOLUÇÃO (processamento)                            │
│  Numeração de GDL → Montagem de [K]/[M] → Condições de         │
│  contorno → Solver linear/modal/não-linear                     │
└─────────────────────────────────────────────────────────────┘
                    │
                    ▼
┌─────────────────────────────────────────────────────────────┐
│  CAMADA 3 — RESULTADOS (pós-processamento)                     │
│  Deslocamentos, reações, esforços internos, modos de vibração  │
└─────────────────────────────────────────────────────────────┘
```

Regra de ouro: **camadas inferiores nunca conhecem as superiores**. `Modelo` não sabe que existe JSON; o solver não sabe que existe Electron. Isso é o que garante que o motor seja testável isoladamente.

### 1.1 Estrutura de diretórios sugerida

```
motor_calculo/
├── fpm.toml
├── src/
│   ├── core/
│   │   ├── mod_precisao.f90        ! kind dp, tolerâncias numéricas
│   │   ├── mod_no.f90
│   │   ├── mod_material.f90
│   │   ├── mod_secao.f90
│   │   ├── mod_elemento_base.f90   ! tipo abstrato
│   │   ├── mod_elemento_euler.f90
│   │   ├── mod_elemento_timoshenko.f90
│   │   ├── mod_elemento_trelica.f90
│   │   ├── mod_apoio.f90
│   │   ├── mod_carga.f90
│   │   ├── mod_caso_carga.f90
│   │   └── mod_modelo.f90          ! agregador "Estrutura"
│   ├── solver/
│   │   ├── mod_numeracao_gdl.f90
│   │   ├── mod_montagem.f90
│   │   ├── mod_solver_estatico.f90
│   │   ├── mod_solver_modal.f90
│   │   └── mod_solver_nao_linear.f90
│   ├── resultados/
│   │   └── mod_resultado.f90
│   ├── io/
│   │   └── mod_json_io.f90         ! usa a lib json-fortran
│   ├── api/
│   │   └── api_c.f90               ! fachada bind(C)
│   └── main.f90                    ! driver CLI para testes
├── test/
│   ├── casos_analiticos/           ! entrada.json + saida_esperada.json
│   └── test_*.f90
└── external/  (ou dependências via fpm.toml)
```

---

## 2. Como conectar com o front-end (Python + Electron + React)

### 2.1 Princípio: motor "batch", não motor "por chamada de método"

Expor cada método de cada classe individualmente para o Python (via f2py/f90wrap) é tentador, mas para software de engenharia estrutural **não compensa**: o fluxo real de uso é "monta o modelo inteiro → calcula → lê resultado inteiro". Não há necessidade de granularidade fina cruzando a fronteira de linguagem.

**Recomendação:** o motor expõe **uma função de entrada** que recebe a descrição completa do modelo (JSON) e devolve a descrição completa dos resultados (JSON). Toda a riqueza de classes/herança fica **dentro** do Fortran — o Python nunca precisa saber que existe `ElementoTimoshenko extends ElementoBase`.

Vantagens dessa escolha:
- Você testa o motor sozinho, direto no terminal, sem precisar do Electron rodando.
- Trocar Python por outra linguagem no futuro não exige tocar no Fortran.
- Evita a fragilidade de `f2py`/`f90wrap` com tipos derivados polimórficos (funciona, mas é instável entre versões de compilador e do próprio wrapper).

### 2.2 Comparação das opções de integração

| Opção | Prós | Contras | Quando usar |
|---|---|---|---|
| **f2py / f90wrap** | Chamada direta de subrotinas Fortran a partir do Python | Lida mal com `type, abstract`/herança/polimorfismo; frágil entre versões de gfortran/ifort | Só se o motor fosse simples, procedural |
| **Executável CLI + JSON em arquivo** | Simplíssimo, fácil de debugar, testável via terminal, sem gerenciamento de memória cruzando linguagens | Overhead de I/O em disco e de criar processo a cada cálculo (aceitável: cálculo estrutural leva segundos, não milissegundos) | **Recomendado para começar (v1)** |
| **Biblioteca compartilhada + `iso_c_binding` + `ctypes`/`cffi`** | Fica residente em memória, chamada rápida, sem spawn de processo | Precisa gerenciar strings C e ponteiros manualmente; build multiplataforma (Win/Mac/Linux) mais trabalhoso | Evolução (v2) quando performance/interatividade importar |
| **stdin/stdout (pipe) em vez de arquivo** | Evita I/O em disco, mantém simplicidade do CLI | Um pouco mais delicado para JSON grande | Alternativa intermediária entre v1 e v2 |

### 2.3 Fluxo de dados recomendado

```
┌──────────────┐   IPC Electron   ┌───────────────────┐   subprocess/   ┌─────────────────────┐
│   React UI    │ <──────────────> │  Python (backend)   │ <────ctypes───> │  Motor Fortran        │
│  (Electron)   │                  │  - monta o JSON      │    JSON in/out  │  (exe ou .dll/.so)    │
│  modela a      │                  │  - valida dados      │                 │  - modelagem interna  │
│  estrutura     │                  │  - persiste projeto  │                 │  - solver              │
│  visualmente   │                  │  - trata erros do    │                 │  - devolve resultados │
│                │                  │    motor              │                 │                        │
└──────────────┘                  └───────────────────┘                 └─────────────────────┘
```

O Python é a camada de **orquestração**: valida o que veio do React, monta o JSON no schema que o motor espera, chama o motor, recebe o JSON de resultado, e devolve ao React já formatado (ou salva no banco/arquivo do projeto).

### 2.4 Esboço do schema JSON de entrada

```json
{
  "nos": [
    {"id": 1, "x": 0.0, "y": 0.0, "z": 0.0},
    {"id": 2, "x": 0.0, "y": 0.0, "z": 3.0}
  ],
  "materiais": [
    {"id": 1, "E": 2.1e11, "G": 8.077e10, "rho": 7850.0}
  ],
  "secoes": [
    {"id": 1, "A": 1.0e-2, "Iy": 8.33e-6, "Iz": 8.33e-6, "J": 1.4e-5, "Asy": 8.3e-3, "Asz": 8.3e-3}
  ],
  "elementos": [
    {
      "id": 1, "no_i": 1, "no_j": 2, "material": 1, "secao": 1,
      "tipo": "euler_bernoulli",
      "beta_graus": 0.0,
      "liberacoes_i": [false,false,false,false,false,false],
      "liberacoes_j": [false,false,false,false,false,false]
    }
  ],
  "apoios": [
    {"no": 1, "restricao": [true,true,true,true,true,true], "inclinado": false}
  ],
  "casos_carga": [
    {
      "id": 1, "nome": "Permanente",
      "cargas_nodais": [{"no": 2, "Fz": -10000.0}],
      "cargas_elemento": [
        {"elemento": 1, "tipo": "distribuida_uniforme", "qz_global": -500.0}
      ]
    }
  ],
  "analise": {"tipo": "estatica_linear"}
}
```

E a saída, espelhando a estrutura (deslocamentos/reações por nó, esforços por elemento em N estações, frequências/modos se for modal). Manter os dois schemas simétricos e versionados (`"schema_version": 1`) facilita evoluir sem quebrar o front-end.

---

## 3. Organização orientada a objetos (classes, atributos, métodos)

Fortran moderno permite OOP de verdade: `type` (classe), `type, abstract` (classe abstrata), `extends` (herança), `procedure(interface), deferred` (método virtual puro), `class(Base)` (variável polimórfica com despacho dinâmico). Vou seguir esse modelo.

Duas observações práticas antes de começar:

1. **Encapsulamento em Fortran** é opcional e por tipo: você pode declarar `private` dentro do `type` e expor só métodos públicos (getters/setters), como C++/Java. Para um motor numérico, isso costuma atrapalhar mais do que ajudar (acesso direto aos campos durante a montagem de matrizes é mais rápido de escrever e ler). Sugestão pragmática: **campos públicos dentro do motor, encapsulamento reforçado só na fronteira da API** (camada 4).

2. **Array polimórfico heterogêneo** (ex: uma lista de elementos misturando `ElementoEulerBernoulli` e `ElementoTimoshenko`) não é `class(Base), allocatable :: v(:)` puro — isso exige tipo dinâmico único por array. O padrão correto é um **wrapper com ponteiro**, mostrado na seção 3.5.

### 3.1 Módulo de precisão (base de tudo)

```fortran
module mod_precisao
    use, intrinsic :: iso_fortran_env, only: real64
    implicit none
    integer, parameter :: dp = real64
    real(dp), parameter :: TOL_ZERO = 1.0e-10_dp   ! tolerância numérica geral
    real(dp), parameter :: PI = 3.14159265358979323846_dp
end module mod_precisao
```

### 3.2 `No` (nó)

**Atributos:** identificação, coordenadas, numeração de GDL global, resultados.
**Métodos:** essencialmente utilitários (a física fica no `Elemento` e no `Modelo`).

```fortran
module mod_no
    use mod_precisao
    implicit none

    type :: No
        integer  :: id
        real(dp) :: x, y, z
        integer  :: gdl_global(6) = 0     ! numeração global; 0 = ainda não numerado
        ! resultados (preenchidos pelo pós-processamento)
        real(dp) :: deslocamento(6) = 0.0_dp   ! ux,uy,uz,rx,ry,rz
        real(dp) :: reacao(6)       = 0.0_dp
    contains
        procedure :: distancia => no_distancia
    end type No

contains

    pure function no_distancia(this, outro) result(d)
        class(No), intent(in) :: this
        type(No),  intent(in) :: outro
        real(dp) :: d
        d = sqrt((outro%x - this%x)**2 + (outro%y - this%y)**2 + (outro%z - this%z)**2)
    end function no_distancia

end module mod_no
```

### 3.3 `Material` e `Secao`

```fortran
type :: Material
    integer :: id
    character(len=50) :: nome = ''
    real(dp) :: E        ! módulo de elasticidade
    real(dp) :: G        ! módulo de cisalhamento (ou calculado de E, nu)
    real(dp) :: nu = 0.0_dp
    real(dp) :: rho = 0.0_dp    ! densidade (para massa/dinâmica)
    real(dp) :: alpha_termico = 0.0_dp
end type Material

type :: Secao
    integer :: id
    character(len=50) :: nome = ''
    real(dp) :: A          ! área
    real(dp) :: Iy, Iz     ! momentos de inércia à flexão
    real(dp) :: J          ! constante de torção
    real(dp) :: Asy = 0.0_dp, Asz = 0.0_dp   ! áreas efetivas ao cisalhamento (Timoshenko)
contains
    procedure :: is_valida => secao_validar   ! checa A>0, I>0 etc, evita elemento degenerado
end type Secao
```

### 3.4 `Elemento` — hierarquia abstrata (o coração do motor)

Aqui entra o polimorfismo: `ElementoBase` define **o que todo elemento deve saber fazer**; cada subtipo define **como**.

```fortran
module mod_elemento_base
    use mod_precisao
    use mod_no
    use mod_material
    use mod_secao
    use mod_carga
    implicit none

    type, abstract :: ElementoBase
        integer :: id
        type(No), pointer :: no_i => null()
        type(No), pointer :: no_j => null()
        type(Material), pointer :: material => null()
        type(Secao),    pointer :: secao    => null()
        real(dp) :: beta = 0.0_dp              ! rotação do eixo local (graus) — "rotação de elementos"
        logical  :: liberacao(12) = .false.    ! true = GDL liberado (rótula), ordem: nó_i(6)+nó_j(6)
        type(CargaDistribuida),     allocatable :: cargas_dist(:)
        type(CargaPontualElemento), allocatable :: cargas_pont(:)
        logical  :: somente_tracao     = .false.  ! elemento tipo cabo
        logical  :: somente_compressao = .false.  ! elemento tipo escora
        logical  :: ativo = .true.                ! usado na iteração não-linear (birth-death)
    contains
        ! --- métodos virtuais puros: cada subtipo formula do seu jeito ---
        procedure(interface_matriz12), deferred :: rigidez_local
        procedure(interface_matriz12), deferred :: massa_local

        ! --- métodos comuns (implementados uma vez, herdados por todos) ---
        procedure :: comprimento          => elem_comprimento
        procedure :: matriz_rotacao       => elem_matriz_rotacao
        procedure :: rigidez_global       => elem_rigidez_global        ! aplica T^t K T
        procedure :: condensar_liberacoes => elem_condensar_liberacoes  ! trata rótulas
        procedure :: cargas_equivalentes  => elem_cargas_equivalentes   ! fixed-end forces
        procedure :: esforcos_internos    => elem_esforcos_internos     ! N,Vy,Vz,T,My,Mz(x)
    end type ElementoBase

    abstract interface
        pure function interface_matriz12(this) result(k)
            import :: ElementoBase, dp
            class(ElementoBase), intent(in) :: this
            real(dp) :: k(12,12)
        end function interface_matriz12
    end interface

contains

    pure function elem_comprimento(this) result(L)
        class(ElementoBase), intent(in) :: this
        real(dp) :: L
        L = this%no_i%distancia(this%no_j)
    end function elem_comprimento

    function elem_matriz_rotacao(this) result(T)
        ! Monta a matriz de rotação 12x12 (local->global) a partir dos
        ! cossenos diretores (no_j - no_i) e do ângulo beta em torno do eixo local x.
        class(ElementoBase), intent(in) :: this
        real(dp) :: T(12,12)
        real(dp) :: L, cx, cy, cz
        L = this%comprimento()
        cx = (this%no_j%x - this%no_i%x) / L
        cy = (this%no_j%y - this%no_i%y) / L
        cz = (this%no_j%z - this%no_i%z) / L
        ! ... monta bloco 3x3 de cossenos diretores + correção do beta,
        !     replica em 4 blocos na diagonal de T (translação e rotação, nó i e j)
        T = 0.0_dp
        ! (implementação completa fica para quando formos codar de fato)
    end function elem_matriz_rotacao

    function elem_rigidez_global(this) result(kg)
        class(ElementoBase), intent(in) :: this
        real(dp) :: kg(12,12), kl(12,12), T(12,12)
        kl = this%rigidez_local()
        kl = this%condensar_liberacoes(kl)   ! aplica rótulas ANTES de rotacionar
        T  = this%matriz_rotacao()
        kg = matmul(transpose(T), matmul(kl, T))
    end function elem_rigidez_global

end module mod_elemento_base
```

**Subtipos concretos** — só implementam a física específica:

```fortran
module mod_elemento_euler
    use mod_elemento_base
    implicit none
    type, extends(ElementoBase) :: ElementoEulerBernoulli
    contains
        procedure :: rigidez_local => rigidez_local_euler
        procedure :: massa_local   => massa_local_euler
    end type
contains
    pure function rigidez_local_euler(this) result(k)
        class(ElementoEulerBernoulli), intent(in) :: this
        real(dp) :: k(12,12)
        ! formulação clássica 12x12 de pórtico espacial (EA/L, 12EI/L^3, GJ/L, ...)
        k = 0.0_dp
    end function
    pure function massa_local_euler(this) result(m)
        class(ElementoEulerBernoulli), intent(in) :: this
        real(dp) :: m(12,12)
        m = 0.0_dp   ! matriz de massa consistente (ou concentrada)
    end function
end module

module mod_elemento_timoshenko
    use mod_elemento_base
    implicit none
    type, extends(ElementoBase) :: ElementoTimoshenko
    contains
        procedure :: rigidez_local => rigidez_local_timo
        procedure :: massa_local   => massa_local_timo
    end type
contains
    pure function rigidez_local_timo(this) result(k)
        class(ElementoTimoshenko), intent(in) :: this
        real(dp) :: k(12,12), phi_y, phi_z, L, E, G
        L = this%comprimento(); E = this%material%E; G = this%material%G
        phi_y = 12.0_dp*E*this%secao%Iz / (G*this%secao%Asy*L**2)   ! fator de correção ao cisalhamento
        phi_z = 12.0_dp*E*this%secao%Iy / (G*this%secao%Asz*L**2)
        k = 0.0_dp   ! mesma estrutura do Euler, termos de flexão corrigidos por (1+phi)
    end function
    pure function massa_local_timo(this) result(m)
        class(ElementoTimoshenko), intent(in) :: this
        real(dp) :: m(12,12)
        m = 0.0_dp
    end function
end module

module mod_elemento_trelica
    use mod_elemento_base
    implicit none
    ! elemento só axial — usado puro ou como base p/ "somente tração/compressão"
    type, extends(ElementoBase) :: ElementoTrelica
    contains
        procedure :: rigidez_local => rigidez_local_trelica
        procedure :: massa_local   => massa_local_trelica
    end type
contains
    pure function rigidez_local_trelica(this) result(k)
        class(ElementoTrelica), intent(in) :: this
        real(dp) :: k(12,12), EA_L
        EA_L = this%material%E * this%secao%A / this%comprimento()
        k = 0.0_dp
        k(1,1) = EA_L; k(7,7) = EA_L; k(1,7) = -EA_L; k(7,1) = -EA_L
    end function
    pure function massa_local_trelica(this) result(m)
        class(ElementoTrelica), intent(in) :: this
        real(dp) :: m(12,12)
        m = 0.0_dp
    end function
end module
```

> **Liberações (rótulas):** trate como **condensação estática** dentro de `condensar_liberacoes` — para cada GDL liberado, elimina-se a linha/coluna correspondente da matriz local antes de rotacionar (técnica padrão, funciona para qualquer combinação dos 12 GDL liberados, incluindo casos parciais como liberar só `Mz` numa ponta).
>
> **Elemento só tração/compressão:** não é uma 4ª formulação de rigidez — é um **estado** (`somente_tracao`/`somente_compressao` + `ativo`) sobre um `ElementoTrelica` (ou até um pórtico), resolvido iterativamente pelo solver não-linear (seção 4.3).

### 3.5 Coleção heterogênea de elementos (o "pulo do gato" em Fortran)

```fortran
module mod_elemento_ptr
    use mod_elemento_base
    implicit none
    type :: ElementoPtr
        class(ElementoBase), pointer :: p => null()
    end type
end module
```

No `Modelo`, a lista fica `type(ElementoPtr), allocatable :: elementos(:)`. Cada posição aponta para o subtipo concreto real (`ElementoEulerBernoulli`, `ElementoTimoshenko`, etc.), e o despacho dinâmico (`this%p%rigidez_local()`) chama automaticamente a implementação certa.

*Nota de performance:* esse padrão (array de ponteiros polimórficos) é elegante e extensível, mas tem indireção/overhead de cache. Para modelos muito grandes (dezenas de milhares de elementos), uma alternativa mais "HPC-friendly" é um tipo único com um campo `tipo_formulacao` e `select case` interno. Comece com polimorfismo (mais limpo, mais fácil de estender); só migre se o profiling mostrar que é gargalo — dificilmente será, matrizes 12x12 são pequenas.

### 3.6 `Apoio`

```fortran
type :: Apoio
    integer :: id
    type(No), pointer :: no => null()
    logical  :: restricao(6) = .false.       ! true = restringido naquela direção local do apoio
    real(dp) :: rigidez_mola(6) = 0.0_dp      ! apoio elástico (usado se restricao=false e rigidez>0)
    logical  :: inclinado = .false.
    real(dp) :: angulo_x = 0.0_dp, angulo_y = 0.0_dp, angulo_z = 0.0_dp  ! define o sistema local do apoio
    logical  :: somente_tracao     = .false.  ! ex: apoio que só "puxa" (cabo de ancoragem)
    logical  :: somente_compressao = .false.  ! ex: solo, não resiste a arrancamento
    logical  :: ativo = .true.
contains
    procedure :: matriz_rotacao => apoio_matriz_rotacao   ! usada quando inclinado=.true.
end type Apoio
```

Apoio inclinado: gira o sistema de restrições localmente (rotaciona a linha/coluna correspondente de `[K]` e do vetor de forças para o sistema do apoio, aplica a condição de contorno lá, depois volta). Apoio elástico: soma `rigidez_mola` na diagonal em vez de eliminar o GDL. Apoio só tração/compressão: mesmo tratamento iterativo do elemento (seção 4.3).

### 3.7 Cargas

```fortran
type :: CargaNodal
    integer :: no_id
    real(dp) :: Fx=0,Fy=0,Fz=0,Mx=0,My=0,Mz=0
end type

type, abstract :: CargaElemento
    integer :: elemento_id
end type

type, extends(CargaElemento) :: CargaDistribuida
    real(dp) :: qi(3) = 0.0_dp, qj(3) = 0.0_dp   ! valor inicial/final (trapezoidal); uniforme = qi=qj
    logical  :: sistema_global = .true.           ! ou local ao elemento
end type

type, extends(CargaElemento) :: CargaPontualElemento
    real(dp) :: posicao        ! distância a partir do nó i, 0 <= posicao <= L
    real(dp) :: valor(3) = 0.0_dp
    logical  :: sistema_global = .true.
end type
```

### 3.8 Caso de carga / combinação

```fortran
type :: CasoDeCarga
    integer :: id
    character(len=50) :: nome
    character(len=20) :: categoria = 'PERMANENTE'   ! PERMANENTE, ACIDENTAL, VENTO...
    type(CargaNodal), allocatable :: cargas_nodais(:)
    integer, allocatable :: indices_cargas_elemento(:)  ! referência às cargas do elemento
end type

type :: CombinacaoDeCarga
    integer :: id
    character(len=50) :: nome
    integer,  allocatable :: casos(:)
    real(dp), allocatable :: fatores(:)
end type
```

### 3.9 `Modelo` — o agregador (orquestra tudo)

```fortran
type :: Modelo
    type(No),           allocatable :: nos(:)
    type(ElementoPtr),   allocatable :: elementos(:)
    type(Material),      allocatable :: materiais(:)
    type(Secao),         allocatable :: secoes(:)
    type(Apoio),         allocatable :: apoios(:)
    type(CasoDeCarga),   allocatable :: casos_carga(:)
    integer :: n_gdl_livre = 0
contains
    procedure :: numerar_gdl           => modelo_numerar_gdl
    procedure :: montar_rigidez_global => modelo_montar_K
    procedure :: montar_massa_global   => modelo_montar_M
    procedure :: montar_vetor_cargas   => modelo_montar_F
    procedure :: validar               => modelo_validar   ! checa hipostaticidade, elementos duplicados etc.
end type Modelo
```

### 3.10 Configuração de análise + Solver

Separar "o que é a estrutura" (`Modelo`) de "como analisá-la" (`ConfiguracaoAnalise`) evita misturar dado de domínio com parâmetro de execução:

```fortran
type :: ConfiguracaoAnalise
    character(len=20) :: tipo = 'ESTATICA_LINEAR'  ! ESTATICA_LINEAR, MODAL, NAO_LINEAR
    integer  :: caso_carga_id = 1
    integer  :: n_modos = 10
    real(dp) :: tolerancia = 1.0e-6_dp
    integer  :: max_iteracoes = 50
end type
```

Os solvers em si podem ser módulos com subrotinas livres (Fortran já dá namespacing por módulo — criar uma "classe Solver" sem estado não agrega muito):

```fortran
! mod_solver_estatico.f90
function resolver_estatico(modelo, config) result(resultado)
    type(Modelo), intent(inout) :: modelo
    type(ConfiguracaoAnalise), intent(in) :: config
    type(ResultadoAnalise) :: resultado
    ! 1. numerar_gdl  2. montar K global  3. montar F  4. aplicar condições
    ! 5. resolver K*u=F (LAPACK)  6. calcular reações  7. esforços internos por elemento
end function
```

### 3.11 Resultados

```fortran
type :: ResultadoElemento
    real(dp), allocatable :: posicoes(:)                      ! estações ao longo de L
    real(dp), allocatable :: N(:), Vy(:), Vz(:), T(:), My(:), Mz(:)
end type

type :: ResultadoModal
    real(dp), allocatable :: frequencias_hz(:)
    real(dp), allocatable :: modos(:,:)              ! (n_gdl x n_modos)
    real(dp), allocatable :: massa_participante(:,:) ! por direção x,y,z,rx,ry,rz
end type

type :: ResultadoAnalise
    character(len=20) :: tipo
    logical  :: convergiu = .true.
    character(len=200) :: mensagem = ''
    type(ResultadoElemento), allocatable :: por_elemento(:)
    type(ResultadoModal) :: modal
end type
```

---

## 4. Estratégia do solver (a "física" por trás da camada 2)

### 4.1 Estática linear
1. Numerar GDL livres (pular restritos), opcionalmente reduzir banda (Cuthill-McKee reverso) para modelos grandes.
2. Montar `[K]` global somando `elem%rigidez_global()` de cada elemento ativo.
3. Montar `{F}` = cargas nodais diretas + cargas equivalentes (`cargas_equivalentes()`) de cada elemento, com sinal invertido.
4. Aplicar condições de contorno: apoio rígido remove GDL; elástico soma na diagonal; inclinado rotaciona antes de aplicar.
5. Resolver `[K]{u}={F}` — para pórticos, `[K]` é simétrica, positiva-definida (se a estrutura for estável) e em banda estreita: **LAPACK `DPBSV`** (banda) é uma ótima escolha; para modelos maiores, considerar solver esparso.
6. Reações = `K_completa * u - F` nos GDL restritos.
7. Esforços internos: volta ao sistema local do elemento, soma efeito das cargas distribuídas ao longo de `x` para gerar os diagramas N/Vy/Vz/T/My/Mz.

### 4.2 Dinâmica (modal)
Montar `[M]` global (consistente ou concentrada) e resolver o problema de autovalor generalizado `[K]{φ} = ω²[M]{φ}` — **LAPACK `DSYGV`**. Frequências = `ω/(2π)`. Isso já habilita expansões futuras (espectro de resposta, histórico no tempo) sem redesenhar o `Modelo`.

### 4.3 Não-linearidade tração/compressão (elementos e apoios)
Técnica clássica "birth-death element", iterativa:
1. Resolve linear com todos os elementos/apoios candidatos **ativos**.
2. Verifica o esforço axial resultante em cada elemento/apoio `somente_tracao`/`somente_compressao`.
3. Se violar a hipótese (ex: compressão num elemento só-tração), marca `ativo = .false.` (remove a contribuição de rigidez) e resolve de novo.
4. Repete até nenhum elemento mudar de estado (convergência) ou `max_iteracoes` — se não convergir, reportar no `ResultadoAnalise%mensagem` (pode indicar instabilidade real da estrutura, não só falta de convergência numérica).

### 4.4 Validação e detecção de instabilidade (hipostaticidade)

Isso é crítico em software estrutural: uma matriz `[K]` singular ou mal-condicionada geralmente significa **mecanismo** (estrutura hipostática) — não um bug do solver. `modelo_validar()` deve rodar **antes** de montar `[K]`, checando: nós órfãos (sem elemento), elementos de comprimento zero, seção/material inválidos. E o solver estático deve checar o pivô durante a fatoração — se algum pivô for ~0, reportar erro claro tipo *"Estrutura instável — GDL sem rigidez no nó X"* em vez de deixar `NaN` vazar para o resultado.

---

## 5. Tratamento de erros

Fortran não tem exceções. Padrão recomendado: toda função pública devolve (ou recebe por argumento) um status:

```fortran
type :: StatusExecucao
    logical :: sucesso = .true.
    character(len=200) :: mensagem = ''
end type
```

A camada de API (`api_c.f90`) traduz isso para o campo `"erro"` no JSON de saída, e o Python decide como exibir ao usuário no React — sem nunca deixar o Fortran travar o processo (`error stop`) por um dado de entrada ruim.

---

## 6. Bibliotecas e ferramentas

- **LAPACK/BLAS** — álgebra linear e autovalores (essencial, não reinvente).
- **json-fortran** — parsing/serialização JSON no lado Fortran.
- **fpm (Fortran Package Manager)** — build + gerência de dependências (`fpm.toml` referencia LAPACK e json-fortran); gera tanto o executável CLI quanto (com ajustes) a biblioteca compartilhada.
- Testes: `fpm test`, com uma pasta `test/casos_analiticos/` contendo pares `entrada.json` / `saida_esperada.json` — viga engastada-livre com carga na ponta, pórtico simples, etc. — comparando contra solução fechada ou contra Ftool/SAP2000. Para software estrutural isso não é opcional: é o que garante confiabilidade dos resultados.

---

## 7. Roadmap incremental sugerido

| Fase | Escopo |
|---|---|
| **v0 — MVP** | Pórtico 3D estático, só Euler-Bernoulli, sem liberações, apoios engastado/rotulado simples, cargas nodais + distribuída uniforme, saída de deslocamentos/reações/esforços |
| **v1** | Liberações de extremidade (condensação estática), apoios inclinados, apoios elásticos, cargas trapezoidais e pontuais no elemento |
| **v2** | Timoshenko, elemento de treliça pura |
| **v3** | Elementos/apoios só tração/compressão (solver não-linear iterativo) |
| **v4** | Análise dinâmica modal; depois (se necessário) espectro de resposta / histórico no tempo |

Cada fase fecha com validação contra caso analítico conhecido antes de avançar — evita acumular erro de formulação que só aparece lá na frente, quando já está tudo emaranhado.

---

## 8. Resumo da resposta às suas 3 perguntas

1. **Estrutura básica:** 3 camadas (Modelagem → Solução → Resultados) + 1 camada de API/I/O, motor 100% desacoplado de front-end, testável via CLI.
2. **Conexão com front-end:** motor recebe/devolve JSON; comece com executável + `subprocess` (simples, robusto), evolua para `.dll/.so` + `iso_c_binding` + `ctypes` se precisar de mais performance/interatividade.
3. **Classes:** hierarquia `ElementoBase` (abstrato) → `ElementoEulerBernoulli` / `ElementoTimoshenko` / `ElementoTrelica`, mais `No`, `Material`, `Secao`, `Apoio`, `CargaNodal`/`CargaDistribuida`/`CargaPontualElemento`, `CasoDeCarga`, e o agregador `Modelo` — com `ConfiguracaoAnalise` e solvers separados por responsabilidade.
