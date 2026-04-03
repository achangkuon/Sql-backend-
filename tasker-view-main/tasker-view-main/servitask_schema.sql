-- ============================================================================
-- SERVI TASK — ESQUEMA COMPLETO DE BASE DE DATOS (Supabase / PostgreSQL)
-- ============================================================================
-- Plataforma de intermediación de servicios del hogar en Ecuador.
-- Roles: client, tasker, admin
-- Arquitectura: Escrow de pagos, Happiness Pledge, matching algorítmico,
--               verificación biométrica, calendario de disponibilidad.
-- ============================================================================

-- ═══════════════════════════════════════════════════════════════════════════
-- 0. EXTENSIONES Y TIPOS ENUMERADOS
-- ═══════════════════════════════════════════════════════════════════════════

CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "postgis";          -- geolocalización
CREATE EXTENSION IF NOT EXISTS "pg_trgm";          -- búsqueda fuzzy

-- Roles de usuario
CREATE TYPE user_role AS ENUM ('client', 'tasker', 'admin');

-- Estados de verificación de identidad
CREATE TYPE verification_status AS ENUM (
  'pending',        -- documentos enviados, en revisión
  'verified',       -- verificado completamente
  'rejected',       -- rechazado (documentos inválidos)
  'suspended'       -- suspendido por incumplimiento
);

-- Estados del ciclo de vida de una tarea/solicitud
CREATE TYPE task_status AS ENUM (
  'draft',          -- borrador del cliente
  'published',      -- publicada, buscando tasker
  'matched',        -- tasker asignado, pendiente de confirmar
  'confirmed',      -- ambas partes confirmaron
  'in_progress',    -- tasker trabajando
  'pending_review', -- trabajo terminado, pendiente de aprobación
  'completed',      -- cliente aprobó, pago liberado
  'cancelled',      -- cancelada antes de iniciar
  'disputed'        -- en disputa
);

-- Estados de la postulación del tasker a una tarea
CREATE TYPE application_status AS ENUM (
  'pending',        -- tasker se postuló, esperando respuesta
  'accepted',       -- cliente aceptó al tasker
  'rejected',       -- cliente rechazó al tasker
  'withdrawn',      -- tasker retiró su postulación
  'expired'         -- expiró sin respuesta
);

-- Estados del pago (sistema escrow)
CREATE TYPE payment_status AS ENUM (
  'pending',        -- pre-autorización solicitada
  'held',           -- fondos retenidos en escrow
  'released',       -- liberado al tasker
  'refunded',       -- devuelto al cliente
  'partially_refunded',
  'failed',         -- fallo en procesamiento
  'disputed'        -- en disputa
);

-- Método de pago
CREATE TYPE payment_method AS ENUM (
  'credit_card',
  'debit_card',
  'bank_transfer',
  'mobile_wallet',  -- ej. billeteras móviles Ecuador
  'platform_credit' -- saldo promocional
);

-- Tipo de notificación
CREATE TYPE notification_type AS ENUM (
  'task_new_request',
  'task_accepted',
  'task_rejected',
  'task_started',
  'task_completed',
  'task_cancelled',
  'payment_held',
  'payment_released',
  'payment_refunded',
  'review_received',
  'chat_message',
  'dispute_opened',
  'dispute_resolved',
  'document_verified',
  'document_rejected',
  'tier_upgrade',
  'promotion',
  'system'
);

-- Tipo de documento de verificación
CREATE TYPE document_type AS ENUM (
  'cedula_front',
  'cedula_back',
  'selfie_biometric',
  'criminal_record',    -- antecedentes penales
  'professional_cert',  -- certificación profesional
  'insurance_policy',   -- póliza de seguros
  'tool_inspection'     -- inspección de herramientas
);

-- Estado de claims del Happiness Pledge
CREATE TYPE claim_status AS ENUM (
  'submitted',
  'under_review',
  'approved',
  'denied',
  'paid_out'
);

-- Tipo de claim
CREATE TYPE claim_type AS ENUM (
  'property_damage',    -- daño a la propiedad
  'bodily_injury',      -- lesión corporal
  'theft'               -- robo
);

-- Nivel de dificultad de la tarea
CREATE TYPE task_size AS ENUM (
  'small',      -- < 2 horas
  'medium',     -- 2-5 horas
  'large',      -- 5-8 horas
  'project'     -- > 1 día (construcción, remodelación)
);

-- Tipo de bloque de disponibilidad
CREATE TYPE availability_type AS ENUM (
  'available',     -- disponible para recibir tareas
  'busy',          -- ocupado (tarea en curso)
  'personal',      -- bloqueo personal
  'synced'         -- sincronizado de Google Calendar
);

-- Tier del tasker
CREATE TYPE tasker_tier AS ENUM (
  'new',        -- recién ingresado
  'standard',   -- primeras tareas completadas
  'pro',        -- buen desempeño sostenido
  'platinum'    -- élite
);

-- Estado de la disputa
CREATE TYPE dispute_status AS ENUM (
  'opened',
  'investigating',
  'resolved_favor_client',
  'resolved_favor_tasker',
  'resolved_partial',
  'escalated',
  'closed'
);


-- ═══════════════════════════════════════════════════════════════════════════
-- 1. PERFILES Y AUTENTICACIÓN
-- ═══════════════════════════════════════════════════════════════════════════
-- Extiende auth.users de Supabase. Cada usuario puede ser client, tasker o ambos.

CREATE TABLE public.profiles (
  id              UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  role            user_role        NOT NULL DEFAULT 'client',
  full_name       TEXT             NOT NULL,
  email           TEXT             UNIQUE NOT NULL,
  phone           TEXT,
  phone_verified  BOOLEAN          DEFAULT FALSE,
  avatar_url      TEXT,
  date_of_birth   DATE,
  province        TEXT,            -- provincia de residencia
  city            TEXT,
  address_line    TEXT,
  latitude        DOUBLE PRECISION,
  longitude       DOUBLE PRECISION,
  locale          TEXT             DEFAULT 'es-EC',
  is_active       BOOLEAN          DEFAULT TRUE,
  is_online       BOOLEAN          DEFAULT FALSE,
  last_seen_at    TIMESTAMPTZ,
  created_at      TIMESTAMPTZ      DEFAULT NOW(),
  updated_at      TIMESTAMPTZ      DEFAULT NOW()
);

COMMENT ON TABLE public.profiles IS
  'Perfil base de todos los usuarios (clientes, taskers, admins). Extiende auth.users de Supabase.';


-- ═══════════════════════════════════════════════════════════════════════════
-- 2. PERFIL EXTENDIDO DEL TASKER
-- ═══════════════════════════════════════════════════════════════════════════
-- Información adicional exclusiva para taskers: verificación, tier, métricas.

CREATE TABLE public.tasker_profiles (
  id                    UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id               UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,

  -- Verificación (KYC)
  verification_status   verification_status DEFAULT 'pending',
  verified_at           TIMESTAMPTZ,
  background_check_date DATE,              -- última verificación de antecedentes
  background_check_ok   BOOLEAN DEFAULT FALSE,
  psychometric_test_ok  BOOLEAN DEFAULT FALSE,

  -- Datos profesionales
  bio                   TEXT,              -- descripción profesional
  years_experience      INT DEFAULT 0,
  service_radius_km     NUMERIC(5,1) DEFAULT 10.0,  -- radio de cobertura
  base_hourly_rate      NUMERIC(10,2),     -- tarifa base por hora (USD)
  has_own_tools         BOOLEAN DEFAULT TRUE,
  has_vehicle           BOOLEAN DEFAULT FALSE,

  -- Tier y métricas (reflejado en pantalla "Mi Negocio")
  tier                  tasker_tier DEFAULT 'new',
  total_tasks_completed INT         DEFAULT 0,
  total_earnings        NUMERIC(12,2) DEFAULT 0.00,
  average_rating        NUMERIC(3,2) DEFAULT 0.00,
  response_rate         NUMERIC(5,2) DEFAULT 0.00,  -- % de solicitudes aceptadas
  acceptance_rate       NUMERIC(5,2) DEFAULT 0.00,  -- % tarea completada vs asignada
  punctuality_rate      NUMERIC(5,2) DEFAULT 0.00,  -- % de llegadas a tiempo

  -- Sincronización externa
  google_calendar_token TEXT,       -- token para sincronizar calendario
  google_calendar_email TEXT,

  -- Configuración de preferencias
  accepts_emergency     BOOLEAN DEFAULT FALSE,  -- acepta tareas urgentes (<2h)
  min_task_price        NUMERIC(10,2),          -- precio mínimo que acepta

  created_at            TIMESTAMPTZ DEFAULT NOW(),
  updated_at            TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.tasker_profiles IS
  'Extensión del perfil para Taskers: verificación biométrica, tier, métricas de rendimiento, configuración de servicios.';

CREATE INDEX idx_tasker_profiles_user_id ON public.tasker_profiles(user_id);
CREATE INDEX idx_tasker_profiles_tier ON public.tasker_profiles(tier);
CREATE INDEX idx_tasker_profiles_verification ON public.tasker_profiles(verification_status);
CREATE INDEX idx_tasker_profiles_rating ON public.tasker_profiles(average_rating DESC);


-- ═══════════════════════════════════════════════════════════════════════════
-- 3. DOCUMENTOS DE VERIFICACIÓN
-- ═══════════════════════════════════════════════════════════════════════════
-- Almacena las referencias a los documentos subidos (cédula, selfie, antecedentes).

CREATE TABLE public.verification_documents (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  document_type   document_type NOT NULL,
  file_url        TEXT NOT NULL,          -- URL en Supabase Storage
  status          verification_status DEFAULT 'pending',
  reviewed_by     UUID REFERENCES public.profiles(id),  -- admin que revisó
  reviewed_at     TIMESTAMPTZ,
  rejection_reason TEXT,
  expires_at      DATE,                   -- para documentos con fecha de vencimiento
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.verification_documents IS
  'Documentos de identidad y verificación subidos por los usuarios (cédula, selfie biométrica, antecedentes penales, certificaciones).';

CREATE INDEX idx_verification_docs_user ON public.verification_documents(user_id);


-- ═══════════════════════════════════════════════════════════════════════════
-- 4. CATEGORÍAS Y SUBCATEGORÍAS DE SERVICIOS
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE public.categories (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  name        TEXT NOT NULL UNIQUE,      -- ej. 'Reparaciones', 'Limpieza'
  slug        TEXT NOT NULL UNIQUE,      -- ej. 'reparaciones', 'limpieza'
  description TEXT,
  icon_url    TEXT,                       -- ícono de la categoría
  image_url   TEXT,                       -- imagen principal
  sort_order  INT DEFAULT 0,
  is_active   BOOLEAN DEFAULT TRUE,
  is_mvp      BOOLEAN DEFAULT FALSE,     -- ¿incluida en el MVP?
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.categories IS
  'Categorías principales de servicio: Reparaciones, Limpieza, Clases, Construcción, Exteriores, Tecnología, Automotriz.';

CREATE TABLE public.subcategories (
  id            UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  category_id   UUID NOT NULL REFERENCES public.categories(id) ON DELETE CASCADE,
  name          TEXT NOT NULL,            -- ej. 'Plomería', 'Electricidad'
  slug          TEXT NOT NULL,
  description   TEXT,
  icon_url      TEXT,
  image_url     TEXT,
  base_price    NUMERIC(10,2),            -- precio base de referencia (USD)
  estimated_duration_minutes INT,         -- duración estimada promedio
  sort_order    INT DEFAULT 0,
  is_active     BOOLEAN DEFAULT TRUE,
  created_at    TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(category_id, slug)
);

COMMENT ON TABLE public.subcategories IS
  'Subcategorías dentro de cada categoría principal (ej. dentro de Reparaciones: Plomería, Electricidad, Handyman, etc.).';

CREATE INDEX idx_subcategories_category ON public.subcategories(category_id);


-- ═══════════════════════════════════════════════════════════════════════════
-- 5. HABILIDADES DEL TASKER (Relación Tasker ↔ Subcategoría)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE public.tasker_skills (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tasker_id       UUID NOT NULL REFERENCES public.tasker_profiles(id) ON DELETE CASCADE,
  subcategory_id  UUID NOT NULL REFERENCES public.subcategories(id) ON DELETE CASCADE,
  custom_hourly_rate NUMERIC(10,2),  -- tarifa personalizada para esta habilidad
  years_experience   INT DEFAULT 0,
  is_verified     BOOLEAN DEFAULT FALSE,  -- verificación de competencia
  created_at      TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(tasker_id, subcategory_id)
);

COMMENT ON TABLE public.tasker_skills IS
  'Vincula a cada Tasker con las subcategorías de servicio que ofrece. Permite tarifas personalizadas por habilidad.';

CREATE INDEX idx_tasker_skills_tasker ON public.tasker_skills(tasker_id);
CREATE INDEX idx_tasker_skills_subcategory ON public.tasker_skills(subcategory_id);


-- ═══════════════════════════════════════════════════════════════════════════
-- 6. DIRECCIONES GUARDADAS (Cliente)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE public.saved_addresses (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  label       TEXT NOT NULL DEFAULT 'Casa',  -- 'Casa', 'Oficina', 'Otro'
  address_line TEXT NOT NULL,
  city        TEXT,
  province    TEXT,
  reference   TEXT,                -- referencia adicional (ej. "edificio azul, piso 3")
  latitude    DOUBLE PRECISION NOT NULL,
  longitude   DOUBLE PRECISION NOT NULL,
  is_default  BOOLEAN DEFAULT FALSE,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.saved_addresses IS
  'Direcciones guardadas por el cliente para agilizar la solicitud de servicios.';

CREATE INDEX idx_saved_addresses_user ON public.saved_addresses(user_id);


-- ═══════════════════════════════════════════════════════════════════════════
-- 7. TAREAS / SOLICITUDES DE SERVICIO  (Núcleo transaccional)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE public.tasks (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id         UUID NOT NULL REFERENCES public.profiles(id),
  assigned_tasker_id UUID REFERENCES public.profiles(id),  -- NULL hasta asignación

  -- Categorización
  category_id       UUID NOT NULL REFERENCES public.categories(id),
  subcategory_id    UUID NOT NULL REFERENCES public.subcategories(id),

  -- Descripción de la tarea
  title             TEXT NOT NULL,
  description       TEXT NOT NULL,
  photos            TEXT[],            -- array de URLs de fotos adjuntas
  task_size         task_size DEFAULT 'medium',
  tools_required    TEXT[],            -- herramientas necesarias (ej. 'escalera', 'brochas')

  -- Ubicación
  address_id        UUID REFERENCES public.saved_addresses(id),
  address_line      TEXT NOT NULL,
  city              TEXT,
  latitude          DOUBLE PRECISION NOT NULL,
  longitude         DOUBLE PRECISION NOT NULL,

  -- Programación
  preferred_date    DATE,
  preferred_time    TIME,
  is_flexible_date  BOOLEAN DEFAULT FALSE,
  is_emergency      BOOLEAN DEFAULT FALSE,  -- solicitud urgente (<2h)
  estimated_duration_hours NUMERIC(4,1),

  -- Precios
  client_min_budget NUMERIC(10,2),     -- presupuesto mínimo del cliente
  client_max_budget NUMERIC(10,2),     -- presupuesto máximo del cliente
  agreed_price      NUMERIC(10,2),     -- precio final acordado
  platform_fee      NUMERIC(10,2),     -- comisión de la plataforma (Trust Fee ~15%)
  total_price       NUMERIC(10,2),     -- precio total = agreed + platform_fee

  -- Estado
  status            task_status DEFAULT 'draft',
  published_at      TIMESTAMPTZ,
  confirmed_at      TIMESTAMPTZ,
  started_at        TIMESTAMPTZ,
  completed_at      TIMESTAMPTZ,
  cancelled_at      TIMESTAMPTZ,
  cancellation_reason TEXT,

  -- Fotos de evidencia (antes/después)
  photos_before     TEXT[],
  photos_after      TEXT[],

  -- Metadata
  response_deadline TIMESTAMPTZ,       -- deadline para que tasker responda
  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.tasks IS
  'Tabla central: cada fila es una solicitud de servicio creada por un cliente. Contiene toda la información del ciclo de vida de la tarea.';

CREATE INDEX idx_tasks_client ON public.tasks(client_id);
CREATE INDEX idx_tasks_tasker ON public.tasks(assigned_tasker_id);
CREATE INDEX idx_tasks_status ON public.tasks(status);
CREATE INDEX idx_tasks_category ON public.tasks(category_id);
CREATE INDEX idx_tasks_subcategory ON public.tasks(subcategory_id);
CREATE INDEX idx_tasks_created ON public.tasks(created_at DESC);
CREATE INDEX idx_tasks_location ON public.tasks USING gist (
  ST_SetSRID(ST_MakePoint(longitude, latitude), 4326)
);


-- ═══════════════════════════════════════════════════════════════════════════
-- 8. POSTULACIONES / APLICACIONES DE TASKERS A TAREAS
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE public.task_applications (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id         UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  tasker_id       UUID NOT NULL REFERENCES public.profiles(id),
  proposed_price  NUMERIC(10,2),     -- precio propuesto por el tasker
  message         TEXT,              -- mensaje introductorio
  estimated_hours NUMERIC(4,1),
  status          application_status DEFAULT 'pending',
  responded_at    TIMESTAMPTZ,       -- cuándo el cliente respondió
  expires_at      TIMESTAMPTZ,       -- deadline de respuesta (45 min según UI)
  created_at      TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(task_id, tasker_id)
);

COMMENT ON TABLE public.task_applications IS
  'Postulaciones de Taskers a tareas publicadas. El cliente elige entre los postulantes o el sistema hace matching algorítmico.';

CREATE INDEX idx_applications_task ON public.task_applications(task_id);
CREATE INDEX idx_applications_tasker ON public.task_applications(tasker_id);
CREATE INDEX idx_applications_status ON public.task_applications(status);


-- ═══════════════════════════════════════════════════════════════════════════
-- 9. SISTEMA DE PAGOS Y ESCROW
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE public.payments (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id           UUID NOT NULL REFERENCES public.tasks(id),
  client_id         UUID NOT NULL REFERENCES public.profiles(id),
  tasker_id         UUID NOT NULL REFERENCES public.profiles(id),

  -- Montos
  subtotal          NUMERIC(10,2) NOT NULL,   -- mano de obra + materiales
  platform_fee      NUMERIC(10,2) NOT NULL,   -- comisión plataforma (Trust Fee)
  tip_amount        NUMERIC(10,2) DEFAULT 0,  -- propina
  total_amount      NUMERIC(10,2) NOT NULL,   -- total cobrado al cliente
  tasker_payout     NUMERIC(10,2) NOT NULL,   -- monto neto para el tasker

  -- Estado del escrow
  status            payment_status DEFAULT 'pending',
  payment_method    payment_method,

  -- Referencias de pasarela (Kushki, Paymentez, etc.)
  gateway_provider  TEXT,                     -- ej. 'kushki', 'paymentez'
  gateway_tx_id     TEXT,                     -- ID de transacción en pasarela
  gateway_response  JSONB,                    -- respuesta completa de la pasarela

  -- Escrow timestamps
  held_at           TIMESTAMPTZ,              -- fondos retenidos
  released_at       TIMESTAMPTZ,              -- fondos liberados al tasker
  refunded_at       TIMESTAMPTZ,
  refund_reason     TEXT,

  created_at        TIMESTAMPTZ DEFAULT NOW(),
  updated_at        TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.payments IS
  'Sistema Escrow: retiene los fondos del cliente hasta confirmación mutua de finalización. Integra pasarelas de pago regionales (Kushki, Paymentez).';

CREATE INDEX idx_payments_task ON public.payments(task_id);
CREATE INDEX idx_payments_client ON public.payments(client_id);
CREATE INDEX idx_payments_tasker ON public.payments(tasker_id);
CREATE INDEX idx_payments_status ON public.payments(status);


-- ═══════════════════════════════════════════════════════════════════════════
-- 10. MÉTODOS DE PAGO GUARDADOS (Cliente)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE public.payment_methods (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  method_type     payment_method NOT NULL,
  label           TEXT,                   -- ej. "Visa terminada en 4242"
  card_last_four  CHAR(4),
  card_brand      TEXT,                   -- 'visa', 'mastercard'
  gateway_token   TEXT,                   -- token tokenizado de la pasarela
  is_default      BOOLEAN DEFAULT FALSE,
  is_active       BOOLEAN DEFAULT TRUE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.payment_methods IS
  'Métodos de pago tokenizados del cliente. No se almacenan datos sensibles, solo tokens de la pasarela.';

CREATE INDEX idx_payment_methods_user ON public.payment_methods(user_id);


-- ═══════════════════════════════════════════════════════════════════════════
-- 11. DATOS BANCARIOS DEL TASKER (Para recibir pagos)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE public.tasker_bank_accounts (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tasker_id       UUID NOT NULL REFERENCES public.tasker_profiles(id) ON DELETE CASCADE,
  bank_name       TEXT NOT NULL,
  account_type    TEXT NOT NULL,           -- 'ahorro', 'corriente'
  account_number  TEXT NOT NULL,           -- encriptado en producción
  account_holder  TEXT NOT NULL,
  id_number       TEXT NOT NULL,           -- cédula del titular
  is_default      BOOLEAN DEFAULT TRUE,
  is_verified     BOOLEAN DEFAULT FALSE,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.tasker_bank_accounts IS
  'Cuentas bancarias del Tasker para recibir los desembolsos de pagos liberados del escrow.';

CREATE INDEX idx_tasker_bank_tasker ON public.tasker_bank_accounts(tasker_id);


-- ═══════════════════════════════════════════════════════════════════════════
-- 12. RESEÑAS Y CALIFICACIONES (Bidireccional)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE public.reviews (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id         UUID NOT NULL REFERENCES public.tasks(id),
  reviewer_id     UUID NOT NULL REFERENCES public.profiles(id),  -- quien califica
  reviewee_id     UUID NOT NULL REFERENCES public.profiles(id),  -- quien recibe
  rating          SMALLINT NOT NULL CHECK (rating BETWEEN 1 AND 5),
  comment         TEXT,
  is_public       BOOLEAN DEFAULT TRUE,

  -- Dimensiones detalladas (solo para review de client → tasker)
  rating_quality     SMALLINT CHECK (rating_quality BETWEEN 1 AND 5),
  rating_punctuality SMALLINT CHECK (rating_punctuality BETWEEN 1 AND 5),
  rating_communication SMALLINT CHECK (rating_communication BETWEEN 1 AND 5),
  rating_value       SMALLINT CHECK (rating_value BETWEEN 1 AND 5),

  created_at      TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(task_id, reviewer_id)  -- una sola reseña por usuario por tarea
);

COMMENT ON TABLE public.reviews IS
  'Sistema de calificación bidireccional: el cliente califica al tasker y viceversa. Incluye dimensiones detalladas para taskers.';

CREATE INDEX idx_reviews_task ON public.reviews(task_id);
CREATE INDEX idx_reviews_reviewee ON public.reviews(reviewee_id);
CREATE INDEX idx_reviews_reviewer ON public.reviews(reviewer_id);


-- ═══════════════════════════════════════════════════════════════════════════
-- 13. MENSAJERÍA / CHAT
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE public.conversations (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id     UUID NOT NULL REFERENCES public.tasks(id) ON DELETE CASCADE,
  client_id   UUID NOT NULL REFERENCES public.profiles(id),
  tasker_id   UUID NOT NULL REFERENCES public.profiles(id),
  is_active   BOOLEAN DEFAULT TRUE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(task_id)
);

COMMENT ON TABLE public.conversations IS
  'Conversación de chat vinculada a cada tarea. Un chat por tarea entre cliente y tasker.';

CREATE TABLE public.messages (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  conversation_id UUID NOT NULL REFERENCES public.conversations(id) ON DELETE CASCADE,
  sender_id       UUID NOT NULL REFERENCES public.profiles(id),
  content         TEXT,
  image_url       TEXT,            -- foto adjunta
  is_system       BOOLEAN DEFAULT FALSE,  -- mensaje automático del sistema
  is_read         BOOLEAN DEFAULT FALSE,
  read_at         TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.messages IS
  'Mensajes individuales dentro de una conversación de chat. Soporta texto, imágenes y mensajes del sistema.';

CREATE INDEX idx_messages_conversation ON public.messages(conversation_id, created_at DESC);
CREATE INDEX idx_messages_sender ON public.messages(sender_id);


-- ═══════════════════════════════════════════════════════════════════════════
-- 14. NOTIFICACIONES
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE public.notifications (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  type            notification_type NOT NULL,
  title           TEXT NOT NULL,
  body            TEXT,
  data            JSONB,            -- payload adicional (task_id, etc.)
  is_read         BOOLEAN DEFAULT FALSE,
  read_at         TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.notifications IS
  'Notificaciones push y en-app para todos los usuarios. El campo data contiene metadata para deep linking.';

CREATE INDEX idx_notifications_user ON public.notifications(user_id, created_at DESC);
CREATE INDEX idx_notifications_unread ON public.notifications(user_id) WHERE is_read = FALSE;


-- ═══════════════════════════════════════════════════════════════════════════
-- 15. CALENDARIO Y DISPONIBILIDAD DEL TASKER
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE public.availability_blocks (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tasker_id       UUID NOT NULL REFERENCES public.tasker_profiles(id) ON DELETE CASCADE,
  block_type      availability_type NOT NULL DEFAULT 'available',
  title           TEXT,             -- ej. "Bloque Mañana", "Cita Médica"
  start_time      TIMESTAMPTZ NOT NULL,
  end_time        TIMESTAMPTZ NOT NULL,
  is_recurring    BOOLEAN DEFAULT FALSE,
  recurrence_rule TEXT,             -- iCal RRULE para bloques recurrentes
  external_id     TEXT,             -- ID de Google Calendar si está sincronizado
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW(),

  CONSTRAINT valid_time_range CHECK (end_time > start_time)
);

COMMENT ON TABLE public.availability_blocks IS
  'Bloques de disponibilidad del Tasker. Se sincronizan con Google Calendar. Refleja la pantalla de Calendario de la app.';

CREATE INDEX idx_availability_tasker ON public.availability_blocks(tasker_id, start_time);


-- ═══════════════════════════════════════════════════════════════════════════
-- 16. DISPUTAS Y RESOLUCIÓN DE CONFLICTOS
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE public.disputes (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id         UUID NOT NULL REFERENCES public.tasks(id),
  opened_by       UUID NOT NULL REFERENCES public.profiles(id),
  assigned_admin  UUID REFERENCES public.profiles(id),  -- admin que gestiona

  reason          TEXT NOT NULL,
  description     TEXT NOT NULL,
  evidence_urls   TEXT[],           -- fotos/capturas de pantalla como evidencia
  status          dispute_status DEFAULT 'opened',

  resolution_notes TEXT,
  refund_amount   NUMERIC(10,2),    -- monto devuelto (si aplica)

  opened_at       TIMESTAMPTZ DEFAULT NOW(),
  resolved_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.disputes IS
  'Sistema de resolución de disputas entre clientes y taskers. Gestionado por el equipo de soporte/admin.';

CREATE INDEX idx_disputes_task ON public.disputes(task_id);
CREATE INDEX idx_disputes_status ON public.disputes(status);


-- ═══════════════════════════════════════════════════════════════════════════
-- 17. HAPPINESS PLEDGE — RECLAMACIONES DE GARANTÍA
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE public.happiness_pledge_claims (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id         UUID NOT NULL REFERENCES public.tasks(id),
  claimant_id     UUID NOT NULL REFERENCES public.profiles(id),  -- quien reclama
  claim_type      claim_type NOT NULL,
  description     TEXT NOT NULL,
  evidence_urls   TEXT[],
  estimated_damage NUMERIC(10,2),       -- monto estimado del daño
  approved_amount  NUMERIC(10,2),       -- monto aprobado (máx $10,000)
  status          claim_status DEFAULT 'submitted',
  reviewed_by     UUID REFERENCES public.profiles(id),
  review_notes    TEXT,

  -- Verificación de elegibilidad: la tarea DEBE haber sido pagada por la plataforma
  payment_id      UUID REFERENCES public.payments(id),

  submitted_at    TIMESTAMPTZ DEFAULT NOW(),
  resolved_at     TIMESTAMPTZ,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.happiness_pledge_claims IS
  'Reclamaciones bajo la póliza Happiness Pledge. Cubre daños a propiedad, lesiones y robos hasta $10,000 USD. Solo aplica si la tarea fue pagada a través de la plataforma (anti-desintermediación).';

CREATE INDEX idx_hpc_task ON public.happiness_pledge_claims(task_id);
CREATE INDEX idx_hpc_status ON public.happiness_pledge_claims(status);


-- ═══════════════════════════════════════════════════════════════════════════
-- 18. FAVORITOS (Cliente → Tasker)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE public.favorites (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  client_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  tasker_id   UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  created_at  TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(client_id, tasker_id)
);

COMMENT ON TABLE public.favorites IS
  'Taskers marcados como favoritos por el cliente para contratación directa recurrente.';


-- ═══════════════════════════════════════════════════════════════════════════
-- 19. PROGRAMA DE REFERIDOS
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE public.referrals (
  id                UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  referrer_id       UUID NOT NULL REFERENCES public.profiles(id),
  referred_id       UUID REFERENCES public.profiles(id),  -- NULL hasta que se registre
  referral_code     TEXT NOT NULL UNIQUE,
  referral_type     TEXT NOT NULL DEFAULT 'user',  -- 'user' o 'tasker'
  reward_amount     NUMERIC(10,2) DEFAULT 5.00,    -- saldo promocional
  is_redeemed       BOOLEAN DEFAULT FALSE,
  redeemed_at       TIMESTAMPTZ,
  created_at        TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.referrals IS
  'Programa de referidos: incentiva el registro de nuevos usuarios y taskers con saldo promocional.';

CREATE INDEX idx_referrals_referrer ON public.referrals(referrer_id);
CREATE INDEX idx_referrals_code ON public.referrals(referral_code);


-- ═══════════════════════════════════════════════════════════════════════════
-- 20. CRÉDITOS / SALDO PROMOCIONAL
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE public.wallet (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  balance     NUMERIC(10,2) DEFAULT 0.00,
  updated_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE public.wallet_transactions (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  wallet_id   UUID NOT NULL REFERENCES public.wallet(id) ON DELETE CASCADE,
  amount      NUMERIC(10,2) NOT NULL,       -- positivo = crédito, negativo = débito
  description TEXT NOT NULL,                 -- ej. "Bono de referido", "Pago de tarea #123"
  reference_type TEXT,                       -- 'referral', 'task_payment', 'promotion', 'refund'
  reference_id UUID,                         -- ID del referido, tarea, etc.
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.wallet IS
  'Saldo de crédito promocional del usuario (referidos, compensaciones, promociones).';


-- ═══════════════════════════════════════════════════════════════════════════
-- 21. HISTORIAL DE BÚSQUEDAS (para IA y recomendaciones)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE public.search_history (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id     UUID NOT NULL REFERENCES public.profiles(id) ON DELETE CASCADE,
  query       TEXT NOT NULL,
  category_id UUID REFERENCES public.categories(id),
  subcategory_id UUID REFERENCES public.subcategories(id),
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.search_history IS
  'Historial de búsquedas del cliente. Alimenta el search bar con IA y las recomendaciones personalizadas.';

CREATE INDEX idx_search_history_user ON public.search_history(user_id, created_at DESC);


-- ═══════════════════════════════════════════════════════════════════════════
-- 22. CONFIGURACIÓN DE NOTIFICACIONES
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE public.notification_preferences (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  user_id         UUID NOT NULL UNIQUE REFERENCES public.profiles(id) ON DELETE CASCADE,
  push_enabled    BOOLEAN DEFAULT TRUE,
  sms_enabled     BOOLEAN DEFAULT FALSE,
  email_enabled   BOOLEAN DEFAULT TRUE,
  push_token      TEXT,               -- FCM token para push notifications
  quiet_hours_start TIME,             -- inicio de horas silenciosas
  quiet_hours_end   TIME,             -- fin de horas silenciosas
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  updated_at      TIMESTAMPTZ DEFAULT NOW()
);


-- ═══════════════════════════════════════════════════════════════════════════
-- 23. REPORTES DE SEGURIDAD (Botón de pánico)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE public.safety_reports (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  task_id         UUID REFERENCES public.tasks(id),
  reporter_id     UUID NOT NULL REFERENCES public.profiles(id),
  reported_user_id UUID REFERENCES public.profiles(id),
  report_type     TEXT NOT NULL,       -- 'safety_concern', 'harassment', 'fraud', 'emergency'
  description     TEXT NOT NULL,
  evidence_urls   TEXT[],
  latitude        DOUBLE PRECISION,
  longitude       DOUBLE PRECISION,
  is_emergency    BOOLEAN DEFAULT FALSE,
  status          TEXT DEFAULT 'open', -- 'open', 'investigating', 'resolved', 'dismissed'
  assigned_admin  UUID REFERENCES public.profiles(id),
  resolution_notes TEXT,
  created_at      TIMESTAMPTZ DEFAULT NOW(),
  resolved_at     TIMESTAMPTZ
);

COMMENT ON TABLE public.safety_reports IS
  'Reportes de seguridad y botón de pánico. Permite reportar incidentes durante o después de una tarea.';

CREATE INDEX idx_safety_reports_task ON public.safety_reports(task_id);
CREATE INDEX idx_safety_reports_status ON public.safety_reports(status);


-- ═══════════════════════════════════════════════════════════════════════════
-- 24. LOG DE AUDITORÍA (Para el Admin Panel)
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE public.audit_log (
  id          UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  actor_id    UUID REFERENCES public.profiles(id),
  action      TEXT NOT NULL,          -- ej. 'task.created', 'payment.released', 'user.suspended'
  entity_type TEXT NOT NULL,          -- ej. 'task', 'payment', 'profile'
  entity_id   UUID,
  metadata    JSONB,                  -- detalles adicionales
  ip_address  INET,
  created_at  TIMESTAMPTZ DEFAULT NOW()
);

COMMENT ON TABLE public.audit_log IS
  'Log inmutable de todas las acciones críticas del sistema. Esencial para el panel de administración y resolución de disputas.';

CREATE INDEX idx_audit_log_actor ON public.audit_log(actor_id, created_at DESC);
CREATE INDEX idx_audit_log_entity ON public.audit_log(entity_type, entity_id);


-- ═══════════════════════════════════════════════════════════════════════════
-- 25. MÉTRICAS AGREGADAS DEL TASKER (Vista materializada para "Mi Negocio")
-- ═══════════════════════════════════════════════════════════════════════════

CREATE TABLE public.tasker_earnings_summary (
  id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  tasker_id       UUID NOT NULL REFERENCES public.tasker_profiles(id) ON DELETE CASCADE,
  period_type     TEXT NOT NULL,       -- 'weekly', 'monthly'
  period_start    DATE NOT NULL,
  period_end      DATE NOT NULL,

  -- Métricas financieras (reflejadas en pantalla "Mi Negocio")
  subtotal_services NUMERIC(12,2) DEFAULT 0,
  platform_fee_total NUMERIC(12,2) DEFAULT 0,
  tips_total        NUMERIC(12,2) DEFAULT 0,
  net_payout        NUMERIC(12,2) DEFAULT 0,

  -- Métricas operativas
  tasks_completed   INT DEFAULT 0,
  tasks_cancelled   INT DEFAULT 0,
  average_rating    NUMERIC(3,2) DEFAULT 0,

  created_at      TIMESTAMPTZ DEFAULT NOW(),

  UNIQUE(tasker_id, period_type, period_start)
);

COMMENT ON TABLE public.tasker_earnings_summary IS
  'Resumen de ganancias del Tasker por periodo (semanal/mensual). Alimenta la pantalla "Mi Negocio" con el desglose financiero.';

CREATE INDEX idx_earnings_tasker ON public.tasker_earnings_summary(tasker_id, period_start DESC);


-- ═══════════════════════════════════════════════════════════════════════════
-- 26. DATOS SEMILLA — CATEGORÍAS Y SUBCATEGORÍAS
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO public.categories (name, slug, sort_order, is_active, is_mvp) VALUES
  ('Reparaciones',   'reparaciones',   1, TRUE, TRUE),
  ('Limpieza',       'limpieza',       2, TRUE, TRUE),
  ('Clases',         'clases',         3, TRUE, FALSE),
  ('Tecnología',     'tecnologia',     4, TRUE, FALSE),
  ('Construcción',   'construccion',   5, TRUE, FALSE),
  ('Exteriores',     'exteriores',     6, TRUE, FALSE),
  ('Automotriz',     'automotriz',     7, TRUE, FALSE),
  ('Otros',          'otros',          8, TRUE, FALSE);

-- Subcategorías: Reparaciones
INSERT INTO public.subcategories (category_id, name, slug, sort_order) VALUES
  ((SELECT id FROM public.categories WHERE slug = 'reparaciones'), 'Handyman',          'handyman',          1),
  ((SELECT id FROM public.categories WHERE slug = 'reparaciones'), 'Plomería',          'plomeria',          2),
  ((SELECT id FROM public.categories WHERE slug = 'reparaciones'), 'Electricidad',      'electricidad',      3),
  ((SELECT id FROM public.categories WHERE slug = 'reparaciones'), 'Electrodomésticos', 'electrodomesticos', 4),
  ((SELECT id FROM public.categories WHERE slug = 'reparaciones'), 'Mecánica',          'mecanica',          5),
  ((SELECT id FROM public.categories WHERE slug = 'reparaciones'), 'Otros',             'reparaciones-otros',6);

-- Subcategorías: Limpieza
INSERT INTO public.subcategories (category_id, name, slug, sort_order) VALUES
  ((SELECT id FROM public.categories WHERE slug = 'limpieza'), 'Residencial',       'residencial',       1),
  ((SELECT id FROM public.categories WHERE slug = 'limpieza'), 'Oficinas y Locales', 'oficinas-locales', 2),
  ((SELECT id FROM public.categories WHERE slug = 'limpieza'), 'Deep Cleaning',     'deep-cleaning',     3),
  ((SELECT id FROM public.categories WHERE slug = 'limpieza'), 'Car Wash',          'car-wash',          4),
  ((SELECT id FROM public.categories WHERE slug = 'limpieza'), 'Piscinas',          'piscinas',          5),
  ((SELECT id FROM public.categories WHERE slug = 'limpieza'), 'Otros',             'limpieza-otros',    6);

-- Subcategorías: Clases / Educación
INSERT INTO public.subcategories (category_id, name, slug, sort_order) VALUES
  ((SELECT id FROM public.categories WHERE slug = 'clases'), 'Inglés',       'ingles',       1),
  ((SELECT id FROM public.categories WHERE slug = 'clases'), 'Matemática',   'matematica',   2),
  ((SELECT id FROM public.categories WHERE slug = 'clases'), 'Física',       'fisica',       3),
  ((SELECT id FROM public.categories WHERE slug = 'clases'), 'Química',      'quimica',      4),
  ((SELECT id FROM public.categories WHERE slug = 'clases'), 'Idiomas',      'idiomas',      5),
  ((SELECT id FROM public.categories WHERE slug = 'clases'), 'Otros',        'clases-otros', 6);

-- Subcategorías: Tecnología
INSERT INTO public.subcategories (category_id, name, slug, sort_order) VALUES
  ((SELECT id FROM public.categories WHERE slug = 'tecnologia'), 'Soporte Técnico PC', 'soporte-pc',  1),
  ((SELECT id FROM public.categories WHERE slug = 'tecnologia'), 'Redes e Internet',   'redes',       2),
  ((SELECT id FROM public.categories WHERE slug = 'tecnologia'), 'Instalación Smart Home', 'smart-home', 3),
  ((SELECT id FROM public.categories WHERE slug = 'tecnologia'), 'Otros',              'tech-otros',  4);

-- Subcategorías: Construcción
INSERT INTO public.subcategories (category_id, name, slug, sort_order) VALUES
  ((SELECT id FROM public.categories WHERE slug = 'construccion'), 'Montaje / Ensamblaje Ligero',   'montaje-ligero',   1),
  ((SELECT id FROM public.categories WHERE slug = 'construccion'), 'Montaje / Ensamblaje General',  'montaje-general',  2),
  ((SELECT id FROM public.categories WHERE slug = 'construccion'), 'Pintura',                       'pintura',          3),
  ((SELECT id FROM public.categories WHERE slug = 'construccion'), 'Albañilería',                   'albanileria',      4),
  ((SELECT id FROM public.categories WHERE slug = 'construccion'), 'Drywall',                       'drywall',          5),
  ((SELECT id FROM public.categories WHERE slug = 'construccion'), 'Otros',                         'construccion-otros',6);

-- Subcategorías: Exteriores
INSERT INTO public.subcategories (category_id, name, slug, sort_order) VALUES
  ((SELECT id FROM public.categories WHERE slug = 'exteriores'), 'Jardinería',     'jardineria',    1),
  ((SELECT id FROM public.categories WHERE slug = 'exteriores'), 'Riego y Drenaje', 'riego-drenaje', 2),
  ((SELECT id FROM public.categories WHERE slug = 'exteriores'), 'Otros',          'exteriores-otros', 3);

-- Subcategorías: Automotriz
INSERT INTO public.subcategories (category_id, name, slug, sort_order) VALUES
  ((SELECT id FROM public.categories WHERE slug = 'automotriz'), 'Mecánica General',      'mecanica-general',    1),
  ((SELECT id FROM public.categories WHERE slug = 'automotriz'), 'Electricidad Automotriz', 'electricidad-auto', 2),
  ((SELECT id FROM public.categories WHERE slug = 'automotriz'), 'Aire Acondicionado',    'ac-auto',             3),
  ((SELECT id FROM public.categories WHERE slug = 'automotriz'), 'Otros',                 'automotriz-otros',    4);


-- ═══════════════════════════════════════════════════════════════════════════
-- 27. ROW LEVEL SECURITY (RLS)
-- ═══════════════════════════════════════════════════════════════════════════
-- Habilitamos RLS en todas las tablas y definimos políticas por rol.

ALTER TABLE public.profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasker_profiles ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.verification_documents ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.categories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subcategories ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasker_skills ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.saved_addresses ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.task_applications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payments ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_methods ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasker_bank_accounts ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.reviews ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.conversations ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.messages ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notifications ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.availability_blocks ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.disputes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.happiness_pledge_claims ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.favorites ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.referrals ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.wallet_transactions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.search_history ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.notification_preferences ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.safety_reports ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.audit_log ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.tasker_earnings_summary ENABLE ROW LEVEL SECURITY;

-- ─── Función auxiliar: verificar si el usuario es admin ───
CREATE OR REPLACE FUNCTION public.is_admin()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'admin'
  );
$$ LANGUAGE SQL SECURITY DEFINER STABLE;

-- ─── Función auxiliar: verificar si el usuario es tasker ───
CREATE OR REPLACE FUNCTION public.is_tasker()
RETURNS BOOLEAN AS $$
  SELECT EXISTS (
    SELECT 1 FROM public.profiles
    WHERE id = auth.uid() AND role = 'tasker'
  );
$$ LANGUAGE SQL SECURITY DEFINER STABLE;


-- ═══════════════════════════════════════════════════════════════════════════
-- RLS POLICIES
-- ═══════════════════════════════════════════════════════════════════════════

-- ─── profiles ───
CREATE POLICY "Users can view all profiles"
  ON public.profiles FOR SELECT USING (TRUE);
CREATE POLICY "Users can update own profile"
  ON public.profiles FOR UPDATE USING (auth.uid() = id);
CREATE POLICY "Admins can update any profile"
  ON public.profiles FOR UPDATE USING (public.is_admin());

-- ─── tasker_profiles ───
CREATE POLICY "Anyone can view verified tasker profiles"
  ON public.tasker_profiles FOR SELECT USING (TRUE);
CREATE POLICY "Tasker can update own profile"
  ON public.tasker_profiles FOR UPDATE USING (auth.uid() = user_id);
CREATE POLICY "Tasker can insert own profile"
  ON public.tasker_profiles FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins full access to tasker profiles"
  ON public.tasker_profiles FOR ALL USING (public.is_admin());

-- ─── verification_documents ───
CREATE POLICY "Users can view own documents"
  ON public.verification_documents FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users can upload own documents"
  ON public.verification_documents FOR INSERT WITH CHECK (auth.uid() = user_id);
CREATE POLICY "Admins can view and update all documents"
  ON public.verification_documents FOR ALL USING (public.is_admin());

-- ─── categories & subcategories (público, solo lectura) ───
CREATE POLICY "Categories are public"
  ON public.categories FOR SELECT USING (TRUE);
CREATE POLICY "Subcategories are public"
  ON public.subcategories FOR SELECT USING (TRUE);
CREATE POLICY "Admins manage categories"
  ON public.categories FOR ALL USING (public.is_admin());
CREATE POLICY "Admins manage subcategories"
  ON public.subcategories FOR ALL USING (public.is_admin());

-- ─── tasker_skills ───
CREATE POLICY "Anyone can view tasker skills"
  ON public.tasker_skills FOR SELECT USING (TRUE);
CREATE POLICY "Tasker manages own skills"
  ON public.tasker_skills FOR ALL USING (
    auth.uid() = (SELECT user_id FROM public.tasker_profiles WHERE id = tasker_id)
  );

-- ─── saved_addresses ───
CREATE POLICY "Users manage own addresses"
  ON public.saved_addresses FOR ALL USING (auth.uid() = user_id);

-- ─── tasks ───
CREATE POLICY "Clients can view own tasks"
  ON public.tasks FOR SELECT USING (auth.uid() = client_id);
CREATE POLICY "Taskers can view assigned tasks"
  ON public.tasks FOR SELECT USING (auth.uid() = assigned_tasker_id);
CREATE POLICY "Taskers can view published tasks in their area"
  ON public.tasks FOR SELECT USING (status = 'published' AND public.is_tasker());
CREATE POLICY "Clients can create tasks"
  ON public.tasks FOR INSERT WITH CHECK (auth.uid() = client_id);
CREATE POLICY "Participants can update tasks"
  ON public.tasks FOR UPDATE USING (
    auth.uid() = client_id OR auth.uid() = assigned_tasker_id
  );
CREATE POLICY "Admins full access to tasks"
  ON public.tasks FOR ALL USING (public.is_admin());

-- ─── task_applications ───
CREATE POLICY "Taskers can view own applications"
  ON public.task_applications FOR SELECT USING (auth.uid() = tasker_id);
CREATE POLICY "Clients can view applications for their tasks"
  ON public.task_applications FOR SELECT USING (
    auth.uid() = (SELECT client_id FROM public.tasks WHERE id = task_id)
  );
CREATE POLICY "Taskers can create applications"
  ON public.task_applications FOR INSERT WITH CHECK (auth.uid() = tasker_id);
CREATE POLICY "Admins full access to applications"
  ON public.task_applications FOR ALL USING (public.is_admin());

-- ─── payments ───
CREATE POLICY "Clients can view own payments"
  ON public.payments FOR SELECT USING (auth.uid() = client_id);
CREATE POLICY "Taskers can view own payments"
  ON public.payments FOR SELECT USING (auth.uid() = tasker_id);
CREATE POLICY "Admins full access to payments"
  ON public.payments FOR ALL USING (public.is_admin());

-- ─── payment_methods ───
CREATE POLICY "Users manage own payment methods"
  ON public.payment_methods FOR ALL USING (auth.uid() = user_id);

-- ─── tasker_bank_accounts ───
CREATE POLICY "Taskers manage own bank accounts"
  ON public.tasker_bank_accounts FOR ALL USING (
    auth.uid() = (SELECT user_id FROM public.tasker_profiles WHERE id = tasker_id)
  );

-- ─── reviews ───
CREATE POLICY "Anyone can view public reviews"
  ON public.reviews FOR SELECT USING (is_public = TRUE);
CREATE POLICY "Participants can create reviews"
  ON public.reviews FOR INSERT WITH CHECK (auth.uid() = reviewer_id);
CREATE POLICY "Admins full access to reviews"
  ON public.reviews FOR ALL USING (public.is_admin());

-- ─── conversations & messages ───
CREATE POLICY "Participants can view conversations"
  ON public.conversations FOR SELECT USING (
    auth.uid() = client_id OR auth.uid() = tasker_id
  );
CREATE POLICY "Participants can view messages"
  ON public.messages FOR SELECT USING (
    auth.uid() IN (
      SELECT client_id FROM public.conversations WHERE id = conversation_id
      UNION
      SELECT tasker_id FROM public.conversations WHERE id = conversation_id
    )
  );
CREATE POLICY "Participants can send messages"
  ON public.messages FOR INSERT WITH CHECK (auth.uid() = sender_id);

-- ─── notifications ───
CREATE POLICY "Users view own notifications"
  ON public.notifications FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "Users update own notifications"
  ON public.notifications FOR UPDATE USING (auth.uid() = user_id);

-- ─── availability_blocks ───
CREATE POLICY "Anyone can view tasker availability"
  ON public.availability_blocks FOR SELECT USING (TRUE);
CREATE POLICY "Taskers manage own availability"
  ON public.availability_blocks FOR ALL USING (
    auth.uid() = (SELECT user_id FROM public.tasker_profiles WHERE id = tasker_id)
  );

-- ─── disputes ───
CREATE POLICY "Participants can view own disputes"
  ON public.disputes FOR SELECT USING (
    auth.uid() = opened_by OR auth.uid() = assigned_admin OR
    auth.uid() IN (SELECT client_id FROM public.tasks WHERE id = task_id) OR
    auth.uid() IN (SELECT assigned_tasker_id FROM public.tasks WHERE id = task_id)
  );
CREATE POLICY "Users can create disputes"
  ON public.disputes FOR INSERT WITH CHECK (auth.uid() = opened_by);
CREATE POLICY "Admins full access to disputes"
  ON public.disputes FOR ALL USING (public.is_admin());

-- ─── happiness_pledge_claims ───
CREATE POLICY "Claimants can view own claims"
  ON public.happiness_pledge_claims FOR SELECT USING (auth.uid() = claimant_id);
CREATE POLICY "Users can submit claims"
  ON public.happiness_pledge_claims FOR INSERT WITH CHECK (auth.uid() = claimant_id);
CREATE POLICY "Admins full access to claims"
  ON public.happiness_pledge_claims FOR ALL USING (public.is_admin());

-- ─── favorites ───
CREATE POLICY "Clients manage own favorites"
  ON public.favorites FOR ALL USING (auth.uid() = client_id);

-- ─── referrals ───
CREATE POLICY "Users view own referrals"
  ON public.referrals FOR SELECT USING (auth.uid() = referrer_id OR auth.uid() = referred_id);
CREATE POLICY "Users create referrals"
  ON public.referrals FOR INSERT WITH CHECK (auth.uid() = referrer_id);

-- ─── wallet ───
CREATE POLICY "Users view own wallet"
  ON public.wallet FOR SELECT USING (auth.uid() = user_id);
CREATE POLICY "wallet_transactions user access"
  ON public.wallet_transactions FOR SELECT USING (
    auth.uid() = (SELECT user_id FROM public.wallet WHERE id = wallet_id)
  );

-- ─── search_history ───
CREATE POLICY "Users manage own search history"
  ON public.search_history FOR ALL USING (auth.uid() = user_id);

-- ─── notification_preferences ───
CREATE POLICY "Users manage own notification preferences"
  ON public.notification_preferences FOR ALL USING (auth.uid() = user_id);

-- ─── safety_reports ───
CREATE POLICY "Users view own safety reports"
  ON public.safety_reports FOR SELECT USING (auth.uid() = reporter_id);
CREATE POLICY "Users create safety reports"
  ON public.safety_reports FOR INSERT WITH CHECK (auth.uid() = reporter_id);
CREATE POLICY "Admins full access to safety reports"
  ON public.safety_reports FOR ALL USING (public.is_admin());

-- ─── audit_log (solo admins) ───
CREATE POLICY "Admins can read audit log"
  ON public.audit_log FOR SELECT USING (public.is_admin());

-- ─── tasker_earnings_summary ───
CREATE POLICY "Taskers view own earnings"
  ON public.tasker_earnings_summary FOR SELECT USING (
    auth.uid() = (SELECT user_id FROM public.tasker_profiles WHERE id = tasker_id)
  );
CREATE POLICY "Admins view all earnings"
  ON public.tasker_earnings_summary FOR SELECT USING (public.is_admin());


-- ═══════════════════════════════════════════════════════════════════════════
-- 28. FUNCIONES Y TRIGGERS
-- ═══════════════════════════════════════════════════════════════════════════

-- Trigger: actualizar updated_at automáticamente
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

-- Aplicar trigger de updated_at a todas las tablas relevantes
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.tasker_profiles
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.verification_documents
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.tasks
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.payments
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.disputes
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.happiness_pledge_claims
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.availability_blocks
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();
CREATE TRIGGER set_updated_at BEFORE UPDATE ON public.notification_preferences
  FOR EACH ROW EXECUTE FUNCTION public.handle_updated_at();

-- Trigger: crear perfil automáticamente al registrar usuario en auth
CREATE OR REPLACE FUNCTION public.handle_new_user()
RETURNS TRIGGER AS $$
BEGIN
  INSERT INTO public.profiles (id, email, full_name, role)
  VALUES (
    NEW.id,
    NEW.email,
    COALESCE(NEW.raw_user_meta_data->>'full_name', 'Usuario'),
    COALESCE((NEW.raw_user_meta_data->>'role')::user_role, 'client')
  );

  -- Crear wallet para el nuevo usuario
  INSERT INTO public.wallet (user_id) VALUES (NEW.id);

  -- Crear preferencias de notificación por defecto
  INSERT INTO public.notification_preferences (user_id) VALUES (NEW.id);

  -- Si es tasker, crear perfil extendido
  IF (NEW.raw_user_meta_data->>'role') = 'tasker' THEN
    INSERT INTO public.tasker_profiles (user_id)
    VALUES (NEW.id);
  END IF;

  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW EXECUTE FUNCTION public.handle_new_user();

-- Trigger: actualizar métricas del tasker al completar una tarea
CREATE OR REPLACE FUNCTION public.update_tasker_metrics()
RETURNS TRIGGER AS $$
DECLARE
  v_tasker_profile_id UUID;
BEGIN
  IF NEW.status = 'completed' AND OLD.status != 'completed' THEN
    -- Obtener el tasker_profile
    SELECT id INTO v_tasker_profile_id
    FROM public.tasker_profiles
    WHERE user_id = NEW.assigned_tasker_id;

    IF v_tasker_profile_id IS NOT NULL THEN
      UPDATE public.tasker_profiles
      SET
        total_tasks_completed = total_tasks_completed + 1,
        total_earnings = total_earnings + COALESCE(NEW.agreed_price, 0),
        average_rating = (
          SELECT COALESCE(AVG(rating), 0)
          FROM public.reviews
          WHERE reviewee_id = NEW.assigned_tasker_id
        )
      WHERE id = v_tasker_profile_id;
    END IF;
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

CREATE TRIGGER on_task_completed
  AFTER UPDATE ON public.tasks
  FOR EACH ROW EXECUTE FUNCTION public.update_tasker_metrics();


-- ═══════════════════════════════════════════════════════════════════════════
-- 29. VISTAS ÚTILES
-- ═══════════════════════════════════════════════════════════════════════════

-- Vista: Taskers disponibles con sus habilidades y ubicación
CREATE OR REPLACE VIEW public.v_available_taskers AS
SELECT
  p.id AS user_id,
  p.full_name,
  p.avatar_url,
  p.latitude,
  p.longitude,
  tp.id AS tasker_profile_id,
  tp.tier,
  tp.average_rating,
  tp.total_tasks_completed,
  tp.base_hourly_rate,
  tp.service_radius_km,
  tp.verification_status,
  tp.accepts_emergency,
  ARRAY_AGG(DISTINCT sc.name) AS skills,
  ARRAY_AGG(DISTINCT c.name) AS categories
FROM public.profiles p
JOIN public.tasker_profiles tp ON tp.user_id = p.id
LEFT JOIN public.tasker_skills ts ON ts.tasker_id = tp.id
LEFT JOIN public.subcategories sc ON sc.id = ts.subcategory_id
LEFT JOIN public.categories c ON c.id = sc.category_id
WHERE p.is_active = TRUE
  AND p.is_online = TRUE
  AND tp.verification_status = 'verified'
GROUP BY p.id, p.full_name, p.avatar_url, p.latitude, p.longitude,
         tp.id, tp.tier, tp.average_rating, tp.total_tasks_completed,
         tp.base_hourly_rate, tp.service_radius_km, tp.verification_status,
         tp.accepts_emergency;

COMMENT ON VIEW public.v_available_taskers IS
  'Taskers verificados y en línea con sus habilidades agregadas. Usada para el matching algorítmico.';

-- Vista: Resumen de tareas para el panel admin
CREATE OR REPLACE VIEW public.v_admin_task_dashboard AS
SELECT
  t.id,
  t.title,
  t.status,
  t.created_at,
  t.agreed_price,
  t.total_price,
  t.is_emergency,
  c.name AS category,
  sc.name AS subcategory,
  client.full_name AS client_name,
  tasker.full_name AS tasker_name,
  pay.status AS payment_status
FROM public.tasks t
JOIN public.categories c ON c.id = t.category_id
JOIN public.subcategories sc ON sc.id = t.subcategory_id
JOIN public.profiles client ON client.id = t.client_id
LEFT JOIN public.profiles tasker ON tasker.id = t.assigned_tasker_id
LEFT JOIN public.payments pay ON pay.task_id = t.id
ORDER BY t.created_at DESC;


-- ═══════════════════════════════════════════════════════════════════════════
-- 30. STORAGE BUCKETS (Referencia para configuración en Supabase Dashboard)
-- ═══════════════════════════════════════════════════════════════════════════
-- Estos buckets deben configurarse en Supabase Storage:
--
-- 1. 'avatars'              → Fotos de perfil de usuarios
-- 2. 'verification-docs'    → Documentos de verificación (privado)
-- 3. 'task-photos'          → Fotos de tareas (antes/después)
-- 4. 'chat-images'          → Imágenes en el chat
-- 5. 'dispute-evidence'     → Evidencia para disputas (privado)
-- 6. 'claim-evidence'       → Evidencia para Happiness Pledge (privado)
-- 7. 'safety-evidence'      → Evidencia de reportes de seguridad (privado)
--
-- Nota: Los buckets 2, 5, 6, 7 deben ser PRIVADOS con acceso restringido.


-- ═══════════════════════════════════════════════════════════════════════════
-- FIN DEL ESQUEMA
-- ═══════════════════════════════════════════════════════════════════════════
