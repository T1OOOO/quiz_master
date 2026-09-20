ALTER TABLE attempt_bundles
 ADD COLUMN manifest_sha256 text
 CHECK (manifest_sha256 IS NULL OR manifest_sha256 ~ '^[0-9a-f]{64}$');

DROP TRIGGER immutable_attempt_bundle ON attempt_bundles;

CREATE FUNCTION guard_attempt_bundle_mutation() RETURNS trigger LANGUAGE plpgsql AS $$
BEGIN
 IF TG_OP = 'INSERT' THEN
  IF NEW.manifest_sha256 IS NULL THEN
   RAISE EXCEPTION 'manifest hash required for new attempt bundle';
  END IF;
  RETURN NEW;
 END IF;
 IF TG_OP = 'DELETE' THEN
  RAISE EXCEPTION 'immutable attempt bundle';
 END IF;
 IF OLD.manifest_sha256 IS NULL AND NEW.manifest_sha256 IS NOT NULL AND
  NEW.bundle_sha256 IS NOT DISTINCT FROM OLD.bundle_sha256 AND
  NEW.bundle_version IS NOT DISTINCT FROM OLD.bundle_version AND
  NEW.controlled_bundle IS NOT DISTINCT FROM OLD.controlled_bundle
 THEN
  RETURN NEW;
 END IF;
 RAISE EXCEPTION 'immutable attempt bundle';
END;
$$;

CREATE TRIGGER immutable_attempt_bundle
 BEFORE INSERT OR UPDATE OR DELETE ON attempt_bundles
 FOR EACH ROW EXECUTE FUNCTION guard_attempt_bundle_mutation();
