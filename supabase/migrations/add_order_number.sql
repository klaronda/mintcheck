-- Order number system: CCSSPPNNNN (country, state, product, sequence)

ALTER TABLE public.starter_kit_orders
  ADD COLUMN IF NOT EXISTS order_number text UNIQUE,
  ADD COLUMN IF NOT EXISTS shipping_country text,
  ADD COLUMN IF NOT EXISTS shipping_state text;

COMMENT ON COLUMN public.starter_kit_orders.order_number IS '10-digit order number: CC(country) SS(state) PP(product) NNNN(sequence)';
COMMENT ON COLUMN public.starter_kit_orders.shipping_country IS '2-letter ISO country from Stripe shipping address';
COMMENT ON COLUMN public.starter_kit_orders.shipping_state IS 'State/province code from Stripe shipping address';

CREATE SEQUENCE IF NOT EXISTS public.order_number_seq START WITH 1;

CREATE OR REPLACE FUNCTION public.generate_order_number(
  p_country_iso text,
  p_state text,
  p_product_code text DEFAULT '01'
) RETURNS text LANGUAGE plpgsql AS $$
DECLARE
  v_cc text;
  v_ss text;
  v_seq int;
  v_country text;
  v_state text;
BEGIN
  v_country := UPPER(COALESCE(NULLIF(TRIM(p_country_iso), ''), 'XX'));
  v_state   := UPPER(COALESCE(NULLIF(TRIM(p_state), ''), ''));

  -- Country codes (alphabetical after US/CA/MX)
  v_cc := CASE v_country
    WHEN 'US' THEN '01'
    WHEN 'CA' THEN '02'
    WHEN 'MX' THEN '03'
    WHEN 'AR' THEN '04'
    WHEN 'AU' THEN '05'
    WHEN 'AT' THEN '06'
    WHEN 'BE' THEN '07'
    WHEN 'BR' THEN '08'
    WHEN 'CL' THEN '09'
    WHEN 'CN' THEN '10'
    WHEN 'CO' THEN '11'
    WHEN 'CZ' THEN '12'
    WHEN 'DK' THEN '13'
    WHEN 'FI' THEN '14'
    WHEN 'FR' THEN '15'
    WHEN 'DE' THEN '16'
    WHEN 'GR' THEN '17'
    WHEN 'HK' THEN '18'
    WHEN 'IN' THEN '19'
    WHEN 'ID' THEN '20'
    WHEN 'IE' THEN '21'
    WHEN 'IL' THEN '22'
    WHEN 'IT' THEN '23'
    WHEN 'JP' THEN '24'
    WHEN 'KR' THEN '25'
    WHEN 'MY' THEN '26'
    WHEN 'NL' THEN '27'
    WHEN 'NZ' THEN '28'
    WHEN 'NO' THEN '29'
    WHEN 'PE' THEN '30'
    WHEN 'PH' THEN '31'
    WHEN 'PL' THEN '32'
    WHEN 'PT' THEN '33'
    WHEN 'RO' THEN '34'
    WHEN 'SA' THEN '35'
    WHEN 'SG' THEN '36'
    WHEN 'ZA' THEN '37'
    WHEN 'ES' THEN '38'
    WHEN 'SE' THEN '39'
    WHEN 'CH' THEN '40'
    WHEN 'TW' THEN '41'
    WHEN 'TH' THEN '42'
    WHEN 'TR' THEN '43'
    WHEN 'AE' THEN '44'
    WHEN 'GB' THEN '45'
    WHEN 'VN' THEN '46'
    ELSE '99'
  END;

  -- US state codes (alphabetical 01-50)
  IF v_country = 'US' THEN
    v_ss := CASE v_state
      WHEN 'AL' THEN '01' WHEN 'AK' THEN '02' WHEN 'AZ' THEN '03' WHEN 'AR' THEN '04'
      WHEN 'CA' THEN '05' WHEN 'CO' THEN '06' WHEN 'CT' THEN '07' WHEN 'DE' THEN '08'
      WHEN 'FL' THEN '09' WHEN 'GA' THEN '10' WHEN 'HI' THEN '11' WHEN 'ID' THEN '12'
      WHEN 'IL' THEN '13' WHEN 'IN' THEN '14' WHEN 'IA' THEN '15' WHEN 'KS' THEN '16'
      WHEN 'KY' THEN '17' WHEN 'LA' THEN '18' WHEN 'ME' THEN '19' WHEN 'MD' THEN '20'
      WHEN 'MA' THEN '21' WHEN 'MI' THEN '22' WHEN 'MN' THEN '23' WHEN 'MS' THEN '24'
      WHEN 'MO' THEN '25' WHEN 'MT' THEN '26' WHEN 'NE' THEN '27' WHEN 'NV' THEN '28'
      WHEN 'NH' THEN '29' WHEN 'NJ' THEN '30' WHEN 'NM' THEN '31' WHEN 'NY' THEN '32'
      WHEN 'NC' THEN '33' WHEN 'ND' THEN '34' WHEN 'OH' THEN '35' WHEN 'OK' THEN '36'
      WHEN 'OR' THEN '37' WHEN 'PA' THEN '38' WHEN 'RI' THEN '39' WHEN 'SC' THEN '40'
      WHEN 'SD' THEN '41' WHEN 'TN' THEN '42' WHEN 'TX' THEN '43' WHEN 'UT' THEN '44'
      WHEN 'VT' THEN '45' WHEN 'VA' THEN '46' WHEN 'WA' THEN '47' WHEN 'WV' THEN '48'
      WHEN 'WI' THEN '49' WHEN 'WY' THEN '50' WHEN 'DC' THEN '51'
      ELSE '00'
    END;
  ELSE
    v_ss := '00';
  END IF;

  v_seq := nextval('public.order_number_seq');

  RETURN v_cc || v_ss || p_product_code || LPAD(v_seq::text, 4, '0');
END;
$$;
