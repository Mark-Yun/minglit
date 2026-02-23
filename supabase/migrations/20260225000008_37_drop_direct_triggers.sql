DROP TRIGGER IF EXISTS on_application_status_notify ON public.event_applications;
DROP TRIGGER IF EXISTS on_new_application_notify ON public.event_applications;
DROP TRIGGER IF EXISTS on_verification_result_notify ON public.verification_submissions;
DROP TRIGGER IF EXISTS on_event_update_notify ON public.events;

DROP FUNCTION IF EXISTS public.notify_application_status();
DROP FUNCTION IF EXISTS public.notify_new_application_to_partner();
DROP FUNCTION IF EXISTS public.notify_verification_result();
DROP FUNCTION IF EXISTS public.notify_event_update();
