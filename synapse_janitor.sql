DROP FUNCTION IF EXISTS synapse_clean_redacted_messages();
CREATE FUNCTION synapse_clean_redacted_messages()
    RETURNS void AS $$
    DECLARE
    BEGIN
        UPDATE events SET content = '{}' FROM redactions AS rdc
            WHERE events.event_id = rdc.redacts
            AND (events.type = 'm.room.encrypted' OR events.type = 'm.room.message');
    END;
$$ LANGUAGE 'plpgsql';

DROP FUNCTION IF EXISTS synapse_get_server_name();
CREATE FUNCTION synapse_get_server_name()
    RETURNS text AS $$
    DECLARE
        _someUser TEXT;
        _serverName TEXT;
    BEGIN
        select user_id from account_data limit 1 INTO _someUser;
        select regexp_replace(_someUser, '^.*:', ':') INTO _serverName;
        RETURN _serverName;
    END;
$$ LANGUAGE 'plpgsql';

DROP FUNCTION IF EXISTS synapse_get_unused_rooms();
CREATE FUNCTION synapse_get_unused_rooms()
    RETURNS TABLE(room_id TEXT) AS $$
    DECLARE
    BEGIN
        RETURN QUERY SELECT r.room_id FROM rooms AS r WHERE r.room_id NOT IN (
            SELECT DISTINCT(m.room_id) FROM room_memberships as m
                INNER JOIN current_state_events as c
                ON m.event_id = c.event_id
                AND m.room_id = c.room_id
                AND m.user_id = c.state_key
                WHERE c.type = 'm.room.member'
                AND m.membership = 'join'
                AND m.user_id LIKE concat('%', synapse_get_server_name())
        );
    END;
$$ LANGUAGE 'plpgsql';

DROP FUNCTION IF EXISTS synapse_clean_unused_rooms();
CREATE FUNCTION synapse_clean_unused_rooms()
    RETURNS void AS $$
    DECLARE
        _count INT;
    BEGIN
        CREATE TEMP TABLE synapse_clean_unused_rooms__tmp
            ON COMMIT DROP
            AS SELECT room_id FROM synapse_get_unused_rooms();

        SELECT COUNT(*) FROM synapse_clean_unused_rooms__tmp INTO _count;
        RAISE NOTICE 'synapse_clean_unused_rooms() Cleaning up % unused rooms', _count;

        DELETE FROM event_forward_extremities AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM event_backward_extremities AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM event_edges AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM room_depth AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM state_forward_extremities AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM events AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM event_json AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM state_events AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM current_state_events AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM room_memberships AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM feedback AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM topics AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM room_names AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM rooms AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM room_hosts AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM room_aliases AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM state_groups AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM state_groups_state AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM receipts_graph AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM receipts_linearized AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM guest_access AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM history_visibility AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM room_tags AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM room_tags_revisions AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM room_account_data AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM event_push_actions AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM local_invites AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM pusher_throttle AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM event_reports AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM public_room_list_stream AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM stream_ordering_to_exterm AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM event_auth AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
        DELETE FROM appservice_room_list AS x WHERE x.room_id IN (SELECT y.room_id FROM synapse_clean_unused_rooms__tmp AS y);
    END;
$$ LANGUAGE 'plpgsql';

SELECT synapse_clean_redacted_messages();
SELECT synapse_clean_unused_rooms();
