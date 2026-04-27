export const VALID_STATUSES = ["draft", "active", "closed"] as const;
export const VALID_GENDERS = ["male", "female"] as const;

export const PARTY_FIELDS = [
  "title",
  "description",
  "image_urls",
  "contact_options",
  "required_verification_ids",
  "min_confirmed_count",
  "max_participants",
  "balance_config",
  "status",
  "metadata",
] as const;

export const LOCATION_FIELDS = [
  "name",
  "address",
  "address_detail",
  "region_1",
  "region_2",
  "region_3",
  "directions_guide",
  "postal_code",
  "geo_point",
] as const;
