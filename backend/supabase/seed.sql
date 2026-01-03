--
-- SEED DATA
--

-- 1. Global Verifications
-- Note: Categories are career, asset, marriage, academic, vehicle, etc.
insert into public.verifications (id, category, internal_name, display_name, description, icon_key, form_schema, partner_id)
values
  (
    '00000000-0000-0000-0000-000000000001',
    'etc',
    'Global Identity Verification',
    '본인인증',
    'PASS 또는 SMS를 통해 본인을 인증하세요.',
    'person_check',
    '[{"key": "phone", "type": "text", "label": "휴대폰 번호", "required": true}]'::jsonb,
    null
  ),
  (
    '00000000-0000-0000-0000-000000000002',
    'career',
    'Global Career Verification',
    '직장인 인증',
    '재직증명서 또는 명함으로 직업을 인증하세요.',
    'business_center',
    '[{"key": "company", "type": "text", "label": "회사명", "required": true}, {"key": "proof", "type": "file", "label": "증빙 서류", "required": true}]'::jsonb,
    null
  ),
  (
    '00000000-0000-0000-0000-000000000003',
    'academic',
    'Global Academic Verification',
    '학력 인증',
    '졸업증명서 또는 학생증으로 학력을 인증하세요.',
    'school',
    '[{"key": "school", "type": "text", "label": "학교명", "required": true}, {"key": "proof", "type": "file", "label": "증빙 서류", "required": true}]'::jsonb,
    null
  ),
  (
    '00000000-0000-0000-0000-000000000004',
    'asset',
    'Global Asset Verification',
    '자산 인증',
    '자산을 증빙할 수 있는 서류를 제출하세요.',
    'savings',
    '[{"key": "asset_type", "type": "text", "label": "자산 종류", "required": true}, {"key": "proof", "type": "file", "label": "증빙 서류", "required": true}]'::jsonb,
    null
  );
