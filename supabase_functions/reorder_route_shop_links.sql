-- PostgreSQL function to reorder agency brand links
-- This function takes the link_id of the item being moved and its new position
-- and updates all affected items in a single transaction

CREATE OR REPLACE FUNCTION reorder_agency_brand_links(
  p_link_id UUID,
  p_new_position INTEGER
)
RETURNS TABLE (
  link_id UUID,
  agency_id UUID,
  brand_id UUID,
  visit_order INTEGER,
  created_at TIMESTAMPTZ,
  updated_at TIMESTAMPTZ
) 
LANGUAGE plpgsql
AS $$
DECLARE
  v_old_position INTEGER;
  v_agency_id UUID;
BEGIN
  -- Get the current position and agency_id of the item being moved
  SELECT abl.visit_order, abl.agency_id 
  INTO v_old_position, v_agency_id
  FROM agency_brand_links abl
  WHERE abl.link_id = p_link_id;

  -- If moving down (increasing position)
  IF p_new_position > v_old_position THEN
    -- Shift items between old and new position up by 1
    UPDATE agency_brand_links abl
    SET visit_order = abl.visit_order - 1
    WHERE abl.agency_id = v_agency_id
      AND abl.visit_order > v_old_position
      AND abl.visit_order <= p_new_position;
  
  -- If moving up (decreasing position)
  ELSIF p_new_position < v_old_position THEN
    -- Shift items between new and old position down by 1
    UPDATE agency_brand_links abl
    SET visit_order = abl.visit_order + 1
    WHERE abl.agency_id = v_agency_id
      AND abl.visit_order >= p_new_position
      AND abl.visit_order < v_old_position;
  END IF;

  -- Update the moved item to its new position
  UPDATE agency_brand_links abl
  SET visit_order = p_new_position
  WHERE abl.link_id = p_link_id;

  -- Return all items for this agency in the new order
  RETURN QUERY
  SELECT 
    abl.link_id,
    abl.agency_id,
    abl.brand_id,
    abl.visit_order,
    abl.created_at,
    abl.updated_at
  FROM agency_brand_links abl
  WHERE abl.agency_id = v_agency_id
  ORDER BY abl.visit_order ASC;
END;
$$;
