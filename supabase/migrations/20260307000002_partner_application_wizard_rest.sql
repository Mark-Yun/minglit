-- Partner Application Wizard: constraints, columns, policies, and triggers

-- 1. Relax NOT NULL constraints to support draft saves
ALTER TABLE public.partner_applications ALTER COLUMN brand_name DROP NOT NULL;
ALTER TABLE public.partner_applications ALTER COLUMN biz_type DROP NOT NULL;
ALTER TABLE public.partner_applications ALTER COLUMN biz_name DROP NOT NULL;
ALTER TABLE public.partner_applications ALTER COLUMN biz_number DROP NOT NULL;
ALTER TABLE public.partner_applications ALTER COLUMN representative_name DROP NOT NULL;
ALTER TABLE public.partner_applications ALTER COLUMN bank_name DROP NOT NULL;
ALTER TABLE public.partner_applications ALTER COLUMN account_number DROP NOT NULL;
ALTER TABLE public.partner_applications ALTER COLUMN account_holder DROP NOT NULL;
ALTER TABLE public.partner_applications ALTER COLUMN biz_registration_path DROP NOT NULL;
ALTER TABLE public.partner_applications ALTER COLUMN bankbook_path DROP NOT NULL;

-- 2. Add new columns for wizard
ALTER TABLE public.partner_applications ADD COLUMN IF NOT EXISTS profile_image_path text;
ALTER TABLE public.partner_applications ADD COLUMN IF NOT EXISTS current_step integer DEFAULT 0;

-- 3. Allow users to update their own draft/needs_correction applications
CREATE POLICY "users_can_update_own_application" ON public.partner_applications
  FOR UPDATE
  USING (auth.uid() = user_id AND status IN ('draft', 'needs_correction'))
  WITH CHECK (auth.uid() = user_id AND status IN ('draft', 'needs_correction', 'pending'));

-- 4. Grant UPDATE permission to authenticated users
GRANT UPDATE ON public.partner_applications TO authenticated;

-- 5. Trigger function: auto-create partner on approval
CREATE OR REPLACE FUNCTION public.handle_partner_application_approved()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER SET search_path = public
AS $$
DECLARE
  v_partner_id uuid;
BEGIN
  -- Guard: required fields must be present at approval time
  IF NEW.brand_name IS NULL OR NEW.biz_type IS NULL OR NEW.biz_name IS NULL OR
     NEW.biz_number IS NULL OR NEW.representative_name IS NULL OR
     NEW.bank_name IS NULL OR NEW.account_number IS NULL OR NEW.account_holder IS NULL THEN
    RAISE EXCEPTION 'Cannot approve application with missing required fields';
  END IF;

  -- Create partner record
  INSERT INTO public.partners (
    name, introduction, address, contact_phone, contact_email,
    representative_name, biz_name, biz_number, profile_image_url, is_active
  ) VALUES (
    NEW.brand_name, NEW.introduction, NEW.address, NEW.contact_phone, NEW.contact_email,
    NEW.representative_name, NEW.biz_name, NEW.biz_number, NEW.profile_image_path, true
  )
  RETURNING id INTO v_partner_id;

  -- Create settlement record
  INSERT INTO public.partner_settlements (
    partner_id, biz_type, biz_name, biz_number, representative_name,
    bank_name, account_number, account_holder, tax_email,
    biz_registration_path, bankbook_path
  ) VALUES (
    v_partner_id, NEW.biz_type, NEW.biz_name, NEW.biz_number, NEW.representative_name,
    NEW.bank_name, NEW.account_number, NEW.account_holder, NEW.tax_email,
    NEW.biz_registration_path, NEW.bankbook_path
  );

  -- Create owner permission (trigger_sync_permissions auto-fills permissions array)
  INSERT INTO public.partner_member_permissions (partner_id, user_id, role)
  VALUES (v_partner_id, NEW.user_id, 'owner');

  RETURN NEW;
END;
$$;

-- 6. Trigger: fire on status change to 'approved'
CREATE TRIGGER on_partner_application_approved
  AFTER UPDATE ON public.partner_applications
  FOR EACH ROW
  WHEN (NEW.status = 'approved' AND OLD.status IS DISTINCT FROM 'approved')
  EXECUTE FUNCTION public.handle_partner_application_approved();
