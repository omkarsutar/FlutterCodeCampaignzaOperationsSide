-- Function to resequence visit_order after deletion
-- This ensures visit_order values are always sequential (1, 2, 3, 4...)
CREATE OR REPLACE FUNCTION resequence_visit_order_after_delete()
RETURNS TRIGGER AS $$
BEGIN
  -- Resequence all items in the same agency that come after the deleted item
  UPDATE agency_brand_links abl
  SET visit_order = abl.visit_order - 1
  WHERE abl.agency_id = OLD.agency_id
    AND abl.visit_order > OLD.visit_order;
  
  RETURN OLD;
END;
$$ LANGUAGE plpgsql;

-- Create trigger to run after delete
-- Note: Make sure to drop existing trigger if it has the same name
DROP TRIGGER IF EXISTS resequence_after_delete ON agency_brand_links;

CREATE TRIGGER resequence_after_delete
  AFTER DELETE ON agency_brand_links
  FOR EACH ROW
  EXECUTE FUNCTION resequence_visit_order_after_delete();
