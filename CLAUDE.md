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

- Devise authenticates by `ci` (Venezuelan ID number), not email
- Three user types share a single `users` table with STI-like role fields: `Admin`, `Student`, `Teacher`
- A user can hold multiple roles simultaneously; active role is stored in `session[:rol]`
- Admin sub-roles: `desarrollador` (developer/full access), `jefe_control_estudio`, `asistente`
- Granular permissions via `Authorized` model (can_create, can_read, can_update, can_delete, can_import, can_export) scoped to Faculty/School
- All authorization logic lives in `app/models/ability.rb`

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
- `ImporlerController` — CSV/XLSX data import for entities, students, teachers, subjects, records
- `ExportController` / `ExportCsvController` — grade history, academic record exports
- `DownloaderController` — PDF/document downloads

### Rails Admin Customization

Rails Admin is mounted at `/admin` with extensive customization in `config/initializers/rails_admin.rb`. Custom actions include dashboard, programation, enrollment_day, and organization_chart. Several models are excluded from the standard admin interface (SectionTeacher, Profile, Address, etc.).

### Input Cleaning

Models normalize input data: CI numbers strip non-numeric characters (`V-`, `-`, `.`), names are titleized, emails downcased, phone numbers cleaned. See `before_validation` callbacks in User/Student/Teacher models.

## Environment Variables

Required in `.env`:
- `PROVIDER_EMAIL_SERVER`, `PROVIDER_EMAIL_PORT`, `PROVIDER_EMAIL_ADDRESS`, `PROVIDER_EMAIL_USERNAME`, `PROVIDER_EMAIL_PASSWORD` — SMTP config
- `STORAGE_ENDPOINT`, `STORAGE_ACCESS_KEY_ID`, `STORAGE_SECRET_ACCESS_KEY`, `STORAGE_BUCKET`, `STORAGE_REGION` — S3-compatible storage (production)

## RuboCop

Max line length: 120. Many style cops disabled (see `.rubocop.yml`). Excludes `bin/`, `db/`, `config/`, `test/`, `node_modules/`.

## Production

- Puma web server, Delayed Job worker, migrations on release (see `Procfile`)
- Database via `DATABASE_URL` env var
- Assets precompiled, static files served by reverse proxy
