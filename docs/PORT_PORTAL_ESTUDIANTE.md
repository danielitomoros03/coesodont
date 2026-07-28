# Portar el Portal del Estudiante desde FAU a ODONT

> **Origen:** `COES-FAU/coesfau` (rama `redesign-portal-estudiante`, serie de 9 commits desde `4f641ad` hasta `62bd8b5`).
> **Destino:** este repo (ODONT, coesodont).
> **Levantado el:** 2026-07-27. Aún **no portado** — este documento describe la propuesta y lo que costaría traerla.

## Qué es

Un rediseño completo de `/student_session/dashboard`: la vista del estudiante deja de ser una página
con el layout administrativo `logged` y pasa a ser un **portal de una sola página** con seis secciones
navegables por anclas, layout propio y hoja de estilos propia.

El concepto visual original de FAU se llama **"lámina de taller"**: imita una lámina de arquitectura
—cajetín de identificación arriba, papel de cal y concreto claro, líneas como cotas de plano,
tipografía técnica—, con guiños a la Facultad de Arquitectura (policromía de la Ciudad Universitaria,
guarda de colores del mural, textos de pie con Villanueva/UNESCO). **Toda esa capa es la que ODONT
debe reinterpretar** (ver §Adaptación) — a diferencia de FHE, aquí ya tenemos un punto de partida
propio: `design/propuesta-ui-estudiante.html`, la maqueta que ya hicimos con la paleta morada de marca
(`#330066`) y estilo de navbar propio. Esa maqueta debe ser la referencia visual para portar el SCSS,
no la lámina de taller de FAU.

## Sistema visual (tokens en `:root`, versión FAU original)

| Grupo | Tokens | Racional en FAU |
|---|---|---|
| Superficies | `--papel #F7F7F3`, `--papel-plano #FDFDFB`, `--papel-alto #FFF`, `--papel-hueco #EFEFE9` | "cal y concreto claro" |
| Tinta | `--tinta #1B2A44` + 3 pesos (`--tinta-2/3/4`) | jerarquía tipográfica en cuatro niveles |
| Líneas | `--linea`, `--linea-suave`, `--linea-fuerte` (alfas de la tinta) | "cotas del plano" |
| Marca | `--cobalto #1F5FA9` + 4 variantes | tomado del logo de FAU → **en ODONT: morado `#330066`** |
| Estados académicos | `--aprobado #1E7A4A`, `--alerta #A25E0A`, `--reprobado #B3372E`, `--retirado #5D6B84`, cada uno con variante `-tx` y `-velo` | semántica de calificaciones — se conserva igual |
| Policromía CU | `--mural-rojo #C63B2F`, `--mural-amarillo #E3A012` | solo en la guarda superior y el pie — **descartar o reinterpretar** en ODONT |
| Tipografía | `--f-sans: Archivo`, `--f-mono: IBM Plex Mono` | Google Fonts, cargadas en el layout — revisar contra lo ya usado en `propuesta-ui-estudiante.html` |
| Ritmo | `--radio 6px`, `--radio-s 4px`, `--ancho 1148px` | reusable tal cual |

Base: `font-size: 14.5px`, `line-height: 1.55`, antialiasing y `optimizeLegibility`.

## Anatomía de la página

```
.guarda                 franja de policromía (FAU: homenaje a la CU — en ODONT: reinterpretar o quitar)
header.cabecera         "cajetín de la lámina": logo tesela + marca + píldora de período
                        + avatar/iniciales + cerrar sesión
nav.nav-portal          6 anclas: Resumen · Inscripción · Período en curso ·
                        Historial · Documentos · Mis datos   (scrollspy marca aria-current)
main.lienzo             las seis secciones
footer.pie              sello institucional + línea Villanueva/UNESCO (FAU) → institucional ODONT/UCV
```

El SCSS está organizado en los mismos bloques comentados: `GUARDA`, `CABECERA`, `LIENZO`,
`EXPEDIENTE`, `INSCRIPCIÓN`, `PERÍODO EN CURSO`, `HISTORIAL`, `DOCUMENTOS`, `PERFIL`, `PIE`,
`RESPONSIVE`.

## Las seis secciones

1. **`#resumen` — Expediente** (`_expediente.html.haml`, 78 líneas)
   Tarjeta-cajetín con número de expediente (`EXP · {school.code}-{grade.id}`), nombre, C.I.
   formateada, escuela, y una `%dl` de specs (plan, ingreso, admisión). Chips de permanencia
   con tono semántico. A la derecha, la **celosía del pensum**: una rejilla de teselas —una por
   asignatura— coloreadas por estado (aprobada / en curso / por cursar), con leyenda y
   `aria-label` descriptivo. Incluye medidor de créditos y KPIs.

2. **`#inscripcion` — Inscripción** (`_inscripcion.html.haml`, 148 líneas, la más compleja)
   Descrita en el SCSS como *"el momento de mayor tensión del semestre"*. Renderiza un estado
   distinto según dónde esté el estudiante: sin proceso abierto · cita horaria pendiente ·
   preinscrito (con aviso y modal de reporte de pago si la escuela lo exige) · confirmado
   (con enlace a la constancia). Muestra bloqueos por permanencia. **El modal de inscripción
   existente se dejó intacto** — el portal lo envuelve, no lo reemplaza.

3. **`#periodo` — Período en curso** (`_periodo_actual.html.haml`, 46 líneas)
   Asignaturas inscritas + **horario semanal en rejilla CSS** generado desde los `Schedule`
   de las secciones (helper `horario_semanal`, que calcula filas/columnas y el rango de horas).

4. **`#historial` — Historial académico** (`_historial.html.haml`, 92 líneas)
   Acordeón por período con las calificaciones, más un **sparkline SVG del PPS**
   (promedio ponderado por período, escala 0–20) dibujado por un controller Stimulus sin
   librerías externas. Marca los reintentos ("2.ª inscripción") vía `intentos_por_registro`.
   **Se carga con Turbo Frame `loading: :lazy`** contra `student_session#historial`: es la
   sección más pesada y la menos urgente para el primer pintado.

5. **`#documentos` — Documentos** (`_documentos.html.haml`, 54 líneas)
   Constancia de inscripción, constancia de estudio y kardex, cada una con su estado
   "no disponible" explicado cuando no aplica.

6. **`#perfil` — Mis datos** (`_perfil.html.haml`, 52 líneas)
   Perfil etiquetado y aviso de correo temporal. El commit `d2ecb7c` de FAU **eliminó la
   exposición de `user.password` en la vista** (`app/views/users/_personal_data.html.haml`).
   **Confirmado: ODONT arrastra el mismo problema** — `app/views/users/_personal_data.html.haml:14`
   tiene `%td.string_type= user.password` en texto plano. Portar ese fix es obligatorio, no opcional.

## Archivos a portar

| Archivo | Líneas (FAU) | Nota |
|---|---|---|
| `app/assets/stylesheets/student_portal.scss` | 654 | cargado **solo** por el layout del portal, encima de `application.css`; reescribir tokens con la paleta morada ya validada en `design/propuesta-ui-estudiante.html` |
| `app/views/layouts/student_portal.html.haml` | 74 | |
| `app/views/student_session/_expediente.html.haml` | 78 | |
| `app/views/student_session/_inscripcion.html.haml` | 148 | |
| `app/views/student_session/_periodo_actual.html.haml` | 46 | |
| `app/views/student_session/_historial.html.haml` | 92 | |
| `app/views/student_session/_documentos.html.haml` | 54 | |
| `app/views/student_session/_perfil.html.haml` | 52 | incluye el fix de `user.password` |
| `app/views/student_session/dashboard.html.haml` | 29 | ODONT hoy tiene una versión de 8 líneas (`_personal_data` + `_students/show`, ver redirects de ocultamiento abajo) — queda reemplazada, no fusionada |
| `app/views/student_session/historial.html.haml` | 2 | destino del Turbo Frame, `render layout: false` |
| `app/views/shared/_logo_tesela.html.haml` | 14 | **específico de FAU** — reemplazar por identidad ODONT (ver Adaptación) |
| `app/helpers/student_portal_helper.rb` | 143 | incluye `tono_permanencia` y `celosia_teselas` — ambos necesitan ajuste (ver Adaptación) |
| `app/javascript/controllers/scrollspy_controller.js` | 24 | IntersectionObserver → `aria-current`, portable tal cual |
| `app/javascript/controllers/sparkline_controller.js` | 85 | SVG a mano, sin dependencias, portable tal cual |
| `app/controllers/student_session_controller.rb` | +79 | ODONT hoy tiene 23 líneas — hay que fusionar con los redirects de ocultamiento de datos existentes (ver Backend) |
| `config/routes.rb` | +1 | `get 'student_session/historial'` |

Total estimado: ~1.600 líneas nuevas/modificadas.

## Backend

`StudentSessionController#dashboard` pasa a precargar, con `includes` para evitar N+1:

```ruby
@grades  = @student.grades.includes(:study_plan, :school, :admission_type)
@grade   = @grades.find_by(id: params[:grade_id]) || @grades.first   # soporta multi-carrera
@proceso_activo     = @grade.school&.active_process
@inscripcion_actual = @proceso_activo && @grade.enroll_academic_processes
                        .of_academic_process(@proceso_activo.id).first
@records_en_curso   = @inscripcion_actual.academic_records.no_retirados
                        .includes(:subject, section: [:schedules, { teacher: :user }])
```

`#historial` es una acción aparte (`render layout: false`) que arma `@historial` y `@serie_pps`
para el sparkline. El dashboard soporta **varias carreras**: si `@grades.size > 1` aparece un
selector que recarga con `?grade_id=`.

**Importante para ODONT:** el `StudentSessionController#dashboard` actual (23 líneas) ya tiene la
lógica de **"ocultamiento temporal de datos personales"** (redirects si `empty_any_image?`,
`empty_personal_info?`, `empty_info?` del estudiante, o dirección faltante/incompleta). Esos
redirects **deben conservarse tal cual al fusionar** con la versión del portal — FAU los mantuvo
igual en su propia migración, así que el patrón de merge ya está probado.

## Adaptación necesaria para ODONT

**Lo que hay que reinterpretar** (identidad FAU, no reutilizable tal cual):
- `--cobalto` (logo de FAU) → morado de marca `#330066`, ya validado en `design/propuesta-ui-estudiante.html`. Este es el trabajo de adaptación de color más grande del port; conviene hacerlo primero, en el commit de fundaciones.
- `.guarda` (policromía CU) y `_logo_tesela.html.haml` son metáforas arquitectónicas puras — no tienen equivalente natural en Odontología. Opciones: quitar la guarda de colores y usar solo la barra de marca morada, o diseñar un ícono/guarda propio con motivo odontológico. Definir antes de portar el SCSS (bloque `GUARDA`).
- La **celosía del pensum** (rejilla de teselas por asignatura) es utilidad pura, no metáfora — se conserva tal cual, solo cambia la paleta de estado (ya definida arriba).
- Textos del pie y cabecera: "Facultad de Arquitectura y Urbanismo", Villanueva, UNESCO → reemplazar por "Facultad de Odontología, Universidad Central de Venezuela" y quitar las referencias patrimoniales que no aplican.

**Dependencias de modelo — verificado contra este repo el 2026-07-27:**

| Método usado por el portal | ¿Existe en ODONT? |
|---|---|
| `Grade#subjects_approved_ids` | ✅ `app/models/grade.rb:466` |
| `School#active_process`, `School#enroll_process` | ✅ `app/models/school.rb:25-26` |
| `School#enable_enroll_payment_report?` | ✅ |
| `EnrollAcademicProcess.sort_by_period`, `.of_academic_process` | ✅ |
| `AcademicRecord.no_retirados` | ✅ |
| `Grade#current_permanence_status`, `#weighted_average` | ✅ |
| `Section#classroom` | ✅ (columna `classroom :string`) |
| `Subject#obligatoria?` | ✅ **ODONT ya tiene `enum modality: [:obligatoria, :optativa, :electiva]`** en `Subject` — a diferencia de FHE, no hace falta reescribir `celosia_teselas`, se porta tal cual. |

El único gap real no es de modelo sino de **valores del enum de permanencia**. El helper
`tono_permanencia` de FAU mapea:

```ruby
when 'regular', 'egresado', 'egresado_doble_titulo' then :aprobado
when 'nuevo', 'reincorporado', 'intercambio' then :curso
when 'articulo3', 'por_calificar' then :alerta
when 'articulo6', 'articulo7', 'desertor', 'retiro_definitivo', 'expulsado_por_articulo7' then :reprobado
else :neutro
```

Los valores `por_calificar`, `retiro_definitivo` y `expulsado_por_articulo7` **no existen** en el
enum de ODONT. `Grade#current_permanence_status` en este repo es:

```ruby
enum current_permanence_status: [:nuevo, :regular, :reincorporado, :articulo3, :articulo6,
  :articulo7, :intercambio, :desertor, :egresado, :egresado_doble_titulo,
  :permiso_para_no_cursar, :via_de_gracia]
```

Hay que reescribir el `case` contra esta lista real, agregando explícitamente `via_de_gracia` y
`permiso_para_no_cursar` (ninguno de los dos aparece en la versión de FAU):

```ruby
when 'regular', 'egresado', 'egresado_doble_titulo', 'via_de_gracia' then :aprobado
when 'nuevo', 'reincorporado', 'intercambio' then :curso
when 'articulo3' then :alerta
when 'articulo6', 'articulo7', 'desertor', 'permiso_para_no_cursar' then :reprobado
else :neutro
```
(Tono exacto de `permiso_para_no_cursar` y `via_de_gracia` a confirmar con el usuario antes de codificar — es una decisión de negocio, no técnica.)

## Orden sugerido

La serie de FAU ya viene troceada en commits coherentes y conviene respetarlo:
fundaciones (SCSS con paleta morada + layout + helper + Stimulus) → expediente → inscripción →
período en curso → historial → documentos → perfil (con el fix de `user.password`) → Turbo Frame
lazy del historial → pulido visual.

Cada paso deja la app funcionando, así que se puede portar por partes y verificar en pantalla.
