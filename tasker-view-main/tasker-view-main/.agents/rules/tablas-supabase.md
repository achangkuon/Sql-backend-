---
trigger: always_on
---

# SERVI TASK — Esquema BD (Supabase/PostgreSQL)
Servicios del hogar Ecuador. Roles: client|tasker|admin. Escrow, Happiness Pledge, matching, KYC biométrico.

## Ext: uuid-ossp · postgis · pg_trgm
## ENUMs
- user_role: client|tasker|admin
- verification_status: pending|verified|rejected|suspended
- task_status: draft|published|matched|confirmed|in_progress|pending_review|completed|cancelled|disputed
- application_status: pending|accepted|rejected|withdrawn|expired
- payment_status: pending|held|released|refunded|partially_refunded|failed|disputed
- payment_method: credit_card|debit_card|bank_transfer|mobile_wallet|platform_credit
- notification_type: task_{new_request|accepted|rejected|started|completed|cancelled} · payment_{held|released|refunded} · review_received · chat_message · dispute_{opened|resolved} · document_{verified|rejected} · tier_upgrade|promotion|system
- document_type: cedula_front|cedula_back|selfie_biometric|criminal_record|professional_cert|insurance_policy|tool_inspection
- claim_status: submitted|under_review|approved|denied|paid_out
- claim_type: property_damage|bodily_injury|theft
- task_size: small|medium|large|project
- availability_type: available|busy|personal|synced
- tasker_tier: new|standard|pro|platinum
- dispute_status: opened|investigating|resolved_favor_{client|tasker}|resolved_partial|escalated|closed

## Tablas

**profiles** (extiende auth.users): id UUID PK→auth.users · role user_role DEFAULT client · full_name/email(UNIQUE) TEXT NN · phone TEXT · phone_verified BOOL · avatar_url TEXT · date_of_birth DATE · province/city/address_line TEXT · latitude/longitude DOUBLE · locale TEXT DEFAULT es-EC · is_active BOOL · is_online BOOL · last_seen_at/created_at/updated_at TIMESTAMPTZ

**tasker_profiles**: id UUID PK · user_id UUID UNIQUE→profiles · verification_status DEFAULT pending · verified_at TIMESTAMPTZ · background_check_date DATE · background_check_ok/psychometric_test_ok BOOL · bio TEXT · years_experience INT · service_radius_km NUMERIC(5,1) DEFAULT 10 · base_hourly_rate NUMERIC(10,2) · has_own_tools/has_vehicle BOOL · tier tasker_tier DEFAULT new · total_tasks_completed INT · total_earnings NUMERIC(12,2) · average_rating NUMERIC(3,2) · response_rate/acceptance_rate/punctuality_rate NUMERIC(5,2) · google_calendar_token/email TEXT · accepts_emergency BOOL · min_task_price NUMERIC(10,2) · created_at/updated_at TIMESTAMPTZ
*idx: user_id, tier, verification_status, average_rating DESC*

**verification_documents**: id UUID PK · user_id UUID→profiles · document_type NN · file_url TEXT NN · status verification_status DEFAULT pending · reviewed_by UUID→profiles · reviewed_at TIMESTAMPTZ · rejection_reason TEXT · expires_at DATE · created_at/updated_at TIMESTAMPTZ

**categories**: id UUID PK · name/slug TEXT UNIQUE · description/icon_url/image_url TEXT · sort_order INT DEFAULT 0 · is_active BOOL DEFAULT TRUE · is_mvp BOOL DEFAULT FALSE · created_at TIMESTAMPTZ

**subcategories**: id UUID PK · category_id UUID→categories CASCADE · name/slug TEXT NN · description/icon_url/image_url TEXT · base_price NUMERIC(10,2) · estimated_duration_minutes INT · sort_order INT · is_active BOOL · created_at TIMESTAMPTZ · UNIQUE(category_id,slug)

**tasker_skills**: id UUID PK · tasker_id UUID→tasker_profiles CASCADE · subcategory_id UUID→subcategories CASCADE · custom_hourly_rate NUMERIC(10,2) · years_experience INT · is_verified BOOL · created_at TIMESTAMPTZ · UNIQUE(tasker_id,subcategory_id)

**saved_addresses**: id UUID PK · user_id UUID→profiles CASCADE · label TEXT DEFAULT Casa · address_line TEXT NN · city/province/reference TEXT · latitude/longitude DOUBLE NN · is_default BOOL · created_at TIMESTAMPTZ

**tasks** (transaccional): id UUID PK · client_id UUID→profiles NN · assigned_tasker_id UUID→profiles · category_id/subcategory_id UUID NN · title/description TEXT NN · photos TEXT[] · task_size DEFAULT medium · tools_required TEXT[] · address_id UUID→saved_addresses · address_line TEXT NN · city TEXT · latitude/longitude DOUBLE NN · preferred_date DATE · preferred_time TIME · is_flexible_date/is_emergency BOOL · estimated_duration_hours NUMERIC(4,1) · client_min_budget/client_max_budget NUMERIC(10,2) · agreed_price/platform_fee/total_price NUMERIC(10,2) · status task_status DEFAULT draft · published_at/confirmed_at/started_at/completed_at/cancelled_at TIMESTAMPTZ · cancellation_reason TEXT · photos_before/photos_after TEXT[] · response_deadline TIMESTAMPTZ · created_at/updated_at TIMESTAMPTZ
*idx: client_id, assigned_tasker_id, status, category_id, subcategory_id, created_at DESC, GIST(location)*

**task_applications**: id UUID PK · task_id UUID→tasks CASCADE · tasker_id UUID→profiles · proposed_price NUMERIC(10,2) · message TEXT · estimated_hours NUMERIC(4,1) · status application_status DEFAULT pending · responded_at/expires_at TIMESTAMPTZ · UNIQUE(task_id,tasker_id)

**payments** (escrow): id UUID PK · task_id UUID→tasks · client_id/tasker_id UUID→profiles · subtotal/platform_fee/tip_amount/total_amount/tasker_payout NUMERIC(10,2) · status payment_status DEFAULT pending · payment_method · gateway_provider/tx_id TEXT · gateway_response JSONB · held_at/released_at/refunded_at TIMESTAMPTZ · refund_reason TEXT · created_at/updated_at TIMESTAMPTZ

**payment_methods**: id UUID PK · user_id UUID→profiles CASCADE · method_type payment_method NN · label TEXT · card_last_four CHAR(4) · card_brand TEXT · gateway_token TEXT · is_default/is_active BOOL · created_at TIMESTAMPTZ

**tasker_bank_accounts**: id UUID PK · tasker_id UUID→tasker_profiles CASCADE · bank_name/account_type/account_number(enc)/account_holder/id_number TEXT NN · is_default/is_verified BOOL · created_at TIMESTAMPTZ

**reviews** (bidireccional): id UUID PK · task_id UUID→tasks · reviewer_id/reviewee_id UUID→profiles · rating SMALLINT CHECK(1-5) · comment TEXT · is_public BOOL · rating_quality/punctuality/communication/value SMALLINT(1-5) · created_at TIMESTAMPTZ · UNIQUE(task_id,reviewer_id)

**conversations**: id UUID PK · task_id UUID→tasks CASCADE · client_id/tasker_id UUID→profiles · is_active BOOL · created_at TIMESTAMPTZ · UNIQUE(task_id)

**messages**: id UUID PK · conversation_id UUID→conversations CASCADE · sender_id UUID→profiles · content TEXT · image_url TEXT · is_system/is_read BOOL · read_at/created_at TIMESTAMPTZ

**notifications**: id UUID PK · user_id UUID→profiles CASCADE · type notification_type · title/body TEXT · data JSONB · is_read BOOL · read_at/created_at TIMESTAMPTZ

**availability_blocks**: id UUID PK · tasker_id UUID→tasker_profiles CASCADE · block_type availability_type DEFAULT available · title TEXT · start_time/end_time TIMESTAMPTZ NN · is_recurring BOOL · recurrence_rule TEXT (iCal RRULE) · external_id TEXT (Google Cal) · created_at/updated_at TIMESTAMPTZ · CHECK(end_time>start_time)

**disputes**: id UUID PK · task_id UUID→tasks · opened_by/assigned_admin UUID→profiles · reason/description TEXT NN · evidence_urls TEXT[] · status dispute_status DEFAULT opened · resolution_notes TEXT · refund_amount NUMERIC(10,2) · opened_at/resolved_at/created_at/updated_at TIMESTAMPTZ

**hpc**: id UUID PK · task_id UUID→tasks · claimant_id UUID→profiles · claim_type NN · description TEXT NN · evidence_urls TEXT[] · estimated_damage/approved_amount NUMERIC(10,2) · status claim_status DEFAULT submitted · reviewed_by UUID→profiles · review_notes TEXT · payment_id UUID→payments · submitted_at/resolved_at/created_at/updated_at TIMESTAMPTZ

**favorites**: id UUID PK · client_id/tasker_id UUID→profiles CASCADE · created_at TIMESTAMPTZ · UNIQUE(client_id,tasker_id)

**referrals**: id UUID PK · referrer_id/referred_id UUID→profiles · referral_code TEXT UNIQUE · referral_type TEXT DEFAULT user · reward_amount NUMERIC(10,2) DEFAULT 5 · is_redeemed BOOL · redeemed_at/created_at TIMESTAMPTZ

**wallet**: id UUID PK · user_id UUID UNIQUE→profiles CASCADE · balance NUMERIC(10,2) DEFAULT 0 · updated_at TIMESTAMPTZ

**wallet_transactions**: id UUID PK · wallet_id UUID→wallet CASCADE · amount NUMERIC(10,2)(+/-) · description TEXT NN · reference_type TEXT(referral|task_payment|promotion|refund) · reference_id UUID · created_at TIMESTAMPTZ

**search_history**: id UUID PK · user_id UUID→profiles CASCADE · query TEXT NN · category_id UUID→categories · subcategory_id UUID→subcategories · created_at TIMESTAMPTZ

**notification_preferences**: id UUID PK · user_id UUID UNIQUE→profiles CASCADE · push_enabled BOOL · sms_enabled BOOL · email_enabled BOOL · push_token TEXT · quiet_hours_start/end TIME · created_at/updated_at TIMESTAMPTZ

**safety_reports**: id UUID PK · task_id UUID→tasks · reporter_id/reported_user_id UUID→profiles · report_type TEXT (safety_concern|harassment|fraud|emergency) · description TEXT NN · evidence_urls TEXT[] · latitude/longitude DOUBLE · is_emergency BOOL · status TEXT DEFAULT open · assigned_admin UUID→profiles · resolution_notes TEXT · created_at/resolved_at TIMESTAMPTZ

**audit_log** (inmutable): id UUID PK · actor_id UUID→profiles · action TEXT · entity_type TEXT · entity_id UUID · metadata JSONB · ip_address INET · created_at TIMESTAMPTZ

**tasker_earnings_summary** ("Mi Negocio"): id UUID PK · tasker_id UUID→tasker_profiles CASCADE · period_type TEXT (weekly|monthly) · period_start/end DATE · subtotal_services/platform_fee_total/tips_total/net_payout NUMERIC(12,2) · tasks_completed/tasks_cancelled INT · average_rating NUMERIC(3,2) · created_at TIMESTAMPTZ · UNIQUE(tasker_id,period_type,period_start)

## Seed Data
- reparaciones(MVP): Handyman, Plomería, Electricidad, Electrodomésticos, Mecánica
- limpieza(MVP): Residencial, Oficinas y Locales, Deep Cleaning, Car Wash, Piscinas
- clases: Inglés, Matemática, Física, Química, Idiomas
- tecnologia: Soporte Técnico PC, Redes e Internet, Smart Home
- construccion: Montaje Ligero, Montaje General, Pintura, Albañilería, Drywall
- exteriores: Jardinería, Riego y Drenaje
- automotriz: Mecánica General, Electricidad Automotriz, Aire Acondicionado

## RLS Policies
- profiles: SELECT público · UPDATE propio · UPDATE admin
- tasker_profiles: SELECT público · INSERT/UPDATE propio · ALL admin
- verification_documents: SELECT/INSERT propio · ALL admin
- categories/subcategories: SELECT público · ALL admin
- tasker_skills: SELECT público · ALL propio tasker
- saved_addresses: ALL propio
- tasks: SELECT client/tasker/published-para-taskers · INSERT client · UPDATE participantes · ALL admin
- task_applications: SELECT propio tasker/client · INSERT tasker · ALL admin
- payments: SELECT propio client/tasker · ALL admin
- payment_methods: ALL propio
- tasker_bank_accounts: ALL propio tasker
- reviews: SELECT público(is_public) · INSERT participante · ALL admin
- conversations/messages: SELECT/INSERT participantes
- notifications: SELECT/UPDATE propio
- availability_blocks: SELECT público · ALL propio tasker
- disputes: SELECT participantes · INSERT opened_by · ALL admin
- happiness_pledge_claims: SELECT/INSERT propio · ALL admin
- favorites/referrals/wallet/wallet_transactions/search_history/notification_preferences/safety_reports: ALL propio
- audit_log: SELECT admin · tasker_earnings_summary: SELECT propio/admin

Aux: `is_admin()` · `is_tasker()` — SQL SECURITY DEFINER STABLE

## Triggers & Funciones
- **handle_updated_at()** → BEFORE UPDATE en todas las tablas con updated_at
- **handle_new_user()** → AFTER INSERT ON auth.users: crea profile+wallet+notification_preferences; si role=tasker crea tasker_profiles (SECURITY DEFINER)
- **update_tasker_metrics()** → AFTER UPDATE ON tasks cuando status→completed: actualiza total_tasks_completed, total_earnings, average_rating (SECURITY DEFINER)

## Vistas
- **v_available_taskers**: taskers verificados+online con skills/categorías → matching
- **v_admin_task_dashboard**: tareas con client/tasker/pago/categoría ORDER BY created_at DESC

## Storage Buckets
avatars(pub) · verification-docs(priv) · task-photos · chat-images · dispute-evidence(priv) · claim-evidence(priv) · safety-evidence(priv)