# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

COESODONT is a student management and academic process control system for the Faculty of Dentistry (Facultad de Odontología) at the Central University of Venezuela (UCV). It manages student enrollment, academic records, grades, schedules, and academic workflows.

- **COES** = Control de Estudios (Control of Studies)
- **ODONT** = Odontología (Dentistry)

## Tech Stack

- Ruby 3.1.2, Rails 7.0.4, PostgreSQL
- Views: HAML templates, Bootstrap 5.2.3
- Frontend: Stimulus.js, Hotwire/Turbo, jQuery
- JS bundling: Webpack 5 (`yarn build`), CSS: Sass (`yarn build:css`)
- Admin: Rails Admin 3.0 (heavily customized, mounted at `/admin`)
- Auth: Devise (login key is `ci` — cédula de identidad, not email)
- Authorization: CanCanCan with role-based access (`app/models/ability.rb`)
- Background jobs: Delayed Job (ActiveRecord backend)
- File storage: Active Storage (local dev, DigitalOcean Spaces in production)
- Audit trail: PaperTrail on all major models
- PDF: wicked_pdf / wkhtmltopdf
- Excel export: caxlsx, spreadsheet, xlsxtream
- Default locale: Spanish (`es`), timezone: `Caracas`

## Development Commands

```bash
bin/dev                    # Start Rails server + JS/CSS watchers (Procfile.dev)
bin/rails server -p 3000   # Rails server only
yarn build                 # Build JS with webpack
yarn build:css             # Compile SCSS
bin/rails db:prepare       # Create and migrate database
bin/rails db:migrate       # Run pending migrations
bin/rails db:seed          # Seed data
rails test                 # Run test suite (Minitest, parallel)
rails test test/models/user_test.rb          # Run a single test file
rails test test/models/user_test.rb:42       # Run a single test at line
rubocop                    # Lint Ruby (config: .rubocop.yml)
rake jobs:work             # Start Delayed Job worker
```

## Architecture

### Authentication & Authorization

- Devise authenticates by `ci` (Venezuelan ID number), not email. `:confirmable` is **not** enabled — no email verification.
- `User` is its own table; `Admin`, `Student`, `Teacher` are **separate tables, each using `user_id` as primary key** (1:1 with users, joined by `user_id`). Not STI.
- A user can hold multiple roles simultaneously; active role is stored in `session[:rol]`.
- Admin sub-roles: `desarrollador` (full access), `jefe_control_estudio`, `asistente`.
- **PARE** (Procesos de Acceso Restringido): asistentes reciben permisos granulares vía `Authorizable` × `Authorized` (can_create, can_read, can_update, can_delete, can_import, can_export). Sistema en producción.
- **Toda regla de permisos vive en `app/models/ability.rb` (CanCanCan).** No agregar helpers `can_X?` paralelos en Admin/Student/Teacher; usar `can`/`cannot` en Ability.

#### Gotchas de usuarios
- Password por defecto al crear usuario = su CI (`User#before_validation`).
- Si el email queda vacío, se genera `temp{ci}@mailinator.com` (`User#false_email?` lo detecta).
- `User#updated_password` se prende cuando el usuario cambia su clave por primera vez.

### Domain Model (key relationships)

```
Faculty → School → Area → Subject → Course → Section → AcademicRecord
                 → StudyPlan
                 → AdmissionType

AcademicProcess → Period → EnrollAcademicProcess → Grade
                                                 → AcademicRecord

User → Admin / Student / Teacher (role-based)
Student → Grade → AcademicRecord → Qualification
Teacher → Section (via SectionTeacher)
```

### Key Controllers

- `PagesController` — home page, multi-role selection (`pages#multirols`)
- `StudentSessionController` / `TeacherSessionController` — role-specific dashboards
- `AcademicProcessesController` — manage semesters, mass confirmation, section cloning
- `EnrollAcademicProcessesController` — enrollment workflow (reserve, enroll, retire)
- `SectionsController` — section management, grade qualification, bulk operations
- `ImporterController` — CSV/XLSX data import for entities, students, teachers, subjects, records
- `ExportController` / `ExportCsvController` — grade history, academic record exports
- `DownloaderController` — PDF/document downloads

### Rails Admin Customization

Rails Admin is mounted at `/admin` with extensive customization in `config/initializers/rails_admin.rb`:
- Parent controller is `EnhancedController` (incluye `ActionController::Live`, setea `paper_trail` con `ip` y `user_agent`).
- `MainController#history_show` está sobreescrito (vía `prepend`) para que la pestaña history de **Section** muestre versions de Section + AcademicRecord + Qualification, no solo Section.
- Custom actions: `programation`, `enrollment_day`, `personal_data`, `structure`. Custom action subclasses en `lib/rails_admin/config/actions/`.
- Modelos excluidos de show/edit/delete según política (ver el bloque `config.actions`).

### Bitácora forense de Section

`app/models/section/bitacora_query.rb` y `bitacora_proxy.rb` (clases anidadas en `Section`) generan la pestaña history de Sección. Soportan tabs `general`/`students`, filtro por CI de estudiante, y consolidan eventos de Section/AcademicRecord/Qualification. Las versions de PaperTrail tienen columnas extra `ip` y `user_agent` (no estándar) para trazabilidad.

### Custom Validators

En `app/models/*Validator.rb` (cargados por nombre desde `same_period_validator` en `rails_admin.rb`):
- `SamePeriodValidator` — `AcademicRecord.section.period` debe coincidir con `enroll_academic_process.period`.
- `SameSchoolValidator` — sección y enroll deben pertenecer a la misma escuela, salvo que el curso esté ofertado como PCI (`offer_as_pci`).
- `SameSubjectInPeriodValidator` — no inscribir la misma asignatura dos veces en el mismo periodo.
- `ApprovedAndEnrollingValidator` — no re-inscribir asignatura ya aprobada **si** el periodo es el de inscripción activa (sí permitido para periodos históricos / backloading).
- `NestedDependencyValidator` — `SubjectLink` no puede crear ciclos de prelación.
- `UniqEnrollmentDayValidator` — no dos `EnrollmentDay` el mismo día.

### Configuración dinámica

- `GeneralSetup` (tabla clave/valor) expone flags globales vía métodos de clase. Claves conocidas: `ENABLED_POST_QUALIFICACION`, `SEND_WELLCOME_MAILER_ON_CREATE_USER` (valor `"SI"` activa).
- Cada `School` tiene flags propios que cambian el comportamiento de inscripción: `enable_subject_retreat`, `enable_change_course`, `enable_dependents`, `enable_by_level`, `enable_enroll_payment_report`.

### Input Cleaning

Models normalize input data: CI numbers strip non-numeric characters (`V-`, `-`, `.`), names are titleized, emails downcased, phone numbers cleaned. See `before_validation` callbacks in User/Student/Teacher models.

## Environment Variables

Required in `.env`:
- `PROVIDER_EMAIL_SERVER`, `PROVIDER_EMAIL_PORT`, `PROVIDER_EMAIL_ADDRESS`, `PROVIDER_EMAIL_USERNAME`, `PROVIDER_EMAIL_PASSWORD` — SMTP config
- `STORAGE_ENDPOINT`, `STORAGE_ACCESS_KEY_ID`, `STORAGE_SECRET_ACCESS_KEY`, `STORAGE_BUCKET`, `STORAGE_REGION` — S3-compatible storage (production)

## RuboCop

Max line length: 120. Many style cops disabled (see `.rubocop.yml`). Excludes `bin/`, `db/`, `config/`, `test/`, `node_modules/`.

## Production

- Despliegue: `git push` al remoto Dokku — auto-deploy, sin pasos manuales.
- Puma web server, Delayed Job worker, migrations on release (ver `Procfile`).
- Database via `DATABASE_URL` env var.
- Assets precompiled, static files servidos por reverse proxy (Nginx vía Dokku).
- Server: Ubuntu 20.04 con Dokku + Fail2Ban (jails sshd/nginx/recidive). No correr `apt upgrade` global en el servidor.

## Convenciones del proyecto

- **Tests**: la estructura `test/` existe pero no hay suite activa. No agregar tests al código nuevo salvo petición explícita.
- **Comentarios**: estilo lean. Solo agregar comentarios cuando el WHY no es obvio (workaround, regla regulatoria, decisión contraintuitiva). Aprovechar al editar para limpiar comentarios legacy / código comentado en la zona tocada.
- **Vistas**: HAML es el formato preferido (hay migración en curso desde ERB).
