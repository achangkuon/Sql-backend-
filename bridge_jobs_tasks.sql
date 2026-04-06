-- ============================================================================
-- BRIDGE: Jobs (React Native) ↔ Tasks (Flutter)
-- Ejecutar en: Supabase SQL Editor del proyecto qsadtpckaowrkxkbxcxe
-- ============================================================================


-- ─── 1. fn_accept_job ────────────────────────────────────────────────────────
-- El Tasker (Flutter) llama a esta función vía RPC para aceptar un job.
-- Crea el task correspondiente, vincula ambos registros y notifica al cliente.
-- Retorna el UUID del task creado.

CREATE OR REPLACE FUNCTION public.fn_accept_job(
  p_job_id    UUID,
  p_tasker_id UUID
)
RETURNS UUID
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_job            RECORD;
  v_category_id    UUID;
  v_subcategory_id UUID;
  v_task_id        UUID;
  v_title          TEXT;
BEGIN
  -- 1. Bloquear y leer el job para evitar aceptación doble (race condition)
  SELECT * INTO v_job
  FROM public.jobs
  WHERE id = p_job_id AND status = 'pending'
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'job_not_available: El trabajo no existe o ya fue tomado.';
  END IF;

  -- 2. Solo los Taskers pueden aceptar
  IF NOT public.is_tasker() THEN
    RAISE EXCEPTION 'not_a_tasker: Solo los Taskers pueden aceptar solicitudes.';
  END IF;

  -- 3. Resolver category_id desde el slug guardado en jobs.category
  SELECT id INTO v_category_id
  FROM public.categories
  WHERE slug = v_job.category OR id::text = v_job.category
  LIMIT 1;

  -- Fallback: primera categoría activa
  IF v_category_id IS NULL THEN
    SELECT id INTO v_category_id
    FROM public.categories
    WHERE is_active = TRUE
    LIMIT 1;
  END IF;

  -- 4. Resolver subcategory_id desde el primer nombre de la lista separada por comas
  v_title := COALESCE(NULLIF(TRIM(split_part(v_job.subcategory, ', ', 1)), ''), v_job.category, 'Servicio');

  SELECT id INTO v_subcategory_id
  FROM public.subcategories
  WHERE category_id = v_category_id
    AND (name = v_title OR name ILIKE '%' || v_title || '%')
  LIMIT 1;

  -- Fallback: primera subcategoría de esa categoría
  IF v_subcategory_id IS NULL THEN
    SELECT id INTO v_subcategory_id
    FROM public.subcategories
    WHERE category_id = v_category_id
    LIMIT 1;
  END IF;

  -- 5. Crear el task vinculado
  INSERT INTO public.tasks (
    client_id,
    assigned_tasker_id,
    category_id,
    subcategory_id,
    title,
    description,
    address_line,
    latitude,
    longitude,
    client_min_budget,
    client_max_budget,
    status,
    confirmed_at
  ) VALUES (
    v_job.client_id,
    p_tasker_id,
    v_category_id,
    v_subcategory_id,
    v_title,
    COALESCE(v_job.details, ''),
    COALESCE(v_job.location_label, 'Dirección no especificada'),
    COALESCE(v_job.latitude,  0.0),
    COALESCE(v_job.longitude, 0.0),
    v_job.price_min,
    v_job.price_max,
    'confirmed',
    NOW()
  )
  RETURNING id INTO v_task_id;

  -- 6. Vincular job → task y marcar como matched
  UPDATE public.jobs
  SET
    status     = 'matched',
    task_id    = v_task_id,
    updated_at = NOW()
  WHERE id = p_job_id;

  -- 7. Notificar al cliente
  PERFORM public.create_notification(
    v_job.client_id,
    'task_accepted',
    '¡Tasker en camino!',
    'Tu solicitud fue aceptada. El Tasker ya está listo.',
    jsonb_build_object(
      'job_id',    p_job_id,
      'task_id',   v_task_id,
      'tasker_id', p_tasker_id
    )
  );

  RETURN v_task_id;
END;
$$;

-- Permitir ejecución a usuarios autenticados (el chequeo de rol está dentro)
GRANT EXECUTE ON FUNCTION public.fn_accept_job(UUID, UUID) TO authenticated;


-- ─── 2. fn_notify_taskers_on_new_job ─────────────────────────────────────────
-- Trigger: cuando un cliente publica un job, notifica a todos los Taskers activos.

CREATE OR REPLACE FUNCTION public.fn_notify_taskers_on_new_job()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_title TEXT;
BEGIN
  IF NEW.status = 'pending' THEN
    v_title := COALESCE(
      NULLIF(TRIM(split_part(NEW.subcategory, ', ', 1)), ''),
      NEW.category,
      'Servicio'
    );

    INSERT INTO public.notifications (user_id, type, title, body, data)
    SELECT
      p.id,
      'task_new_request',
      'Nueva solicitud: ' || v_title,
      COALESCE(NEW.location_label, 'Ubicación disponible') || ' · ' ||
        CASE
          WHEN NEW.price_min > 0 AND NEW.price_max > 0
            THEN '$' || NEW.price_min::INT || '–$' || NEW.price_max::INT
          ELSE 'Precio a negociar'
        END,
      jsonb_build_object(
        'job_id',   NEW.id,
        'category', NEW.category
      )
    FROM public.profiles p
    WHERE p.role = 'tasker'
      AND p.is_active = TRUE
      AND p.id != NEW.client_id;
  END IF;
  RETURN NEW;
END;
$$;

-- Eliminar el trigger si ya existe y recrearlo
DROP TRIGGER IF EXISTS on_new_job_notify_taskers ON public.jobs;

CREATE TRIGGER on_new_job_notify_taskers
  AFTER INSERT ON public.jobs
  FOR EACH ROW
  EXECUTE FUNCTION public.fn_notify_taskers_on_new_job();


-- ─── 3. Habilitar Realtime en jobs (si no está habilitado) ───────────────────
-- Esto permite que la app React Native reciba el cambio de status en tiempo real.
-- Ejecutar solo si jobs no está en la publicación de realtime todavía:
--
--   ALTER PUBLICATION supabase_realtime ADD TABLE public.jobs;
--
-- (Verificar primero en Supabase Dashboard > Database > Replication)
