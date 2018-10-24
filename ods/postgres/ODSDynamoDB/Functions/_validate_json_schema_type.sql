CREATE OR REPLACE FUNCTION public._validate_json_schema_type(type text, data jsonb) RETURNS boolean AS $f$
BEGIN
  IF type = 'integer' THEN
    IF jsonb_typeof(data) != 'number' THEN
      RETURN false;
    END IF;
    IF trunc(data::text::numeric) != data::text::numeric THEN
      RETURN false;
    END IF;
  ELSE
    IF type != jsonb_typeof(data) THEN
      RETURN false;
    END IF;
  END IF;
  RETURN true;
END;
$f$ LANGUAGE 'plpgsql' IMMUTABLE;
