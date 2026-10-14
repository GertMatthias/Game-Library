"""Prepared two-session integrity checks. LOCAL disposable PostgreSQL only.

Requires psql on PATH; uses PGUSER/PGPASSWORD/PGDATABASE from the environment.
Does not configure Auth or execute migrations. Creates and removes test fixtures.
"""
import os
import subprocess
import time
import uuid

if os.environ.get("PGHOST") not in ("127.0.0.1", "localhost", "::1"):
    raise SystemExit("Refusing non-local PGHOST. Set PGHOST=127.0.0.1 for a disposable local database.")


def run(sql, name="gv_test_control", check=True):
    result = subprocess.run(
        ["psql", "-X", "-Atq", "-v", "ON_ERROR_STOP=1"], input=sql,
        text=True, capture_output=True, env={**os.environ, "PGAPPNAME": name},
        timeout=30,
    )
    if check and result.returncode:
        # Report server error without exposing connection strings/passwords.
        raise AssertionError(result.stderr)
    return result


def race(first, second, expected_state):
    session_a = subprocess.Popen(
        ["psql", "-X", "-Atq", "-v", "ON_ERROR_STOP=1"],
        stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
        text=True, env={**os.environ, "PGAPPNAME": "gv_test_a"},
    )
    session_b = None
    try:
        session_a.stdin.write("BEGIN;\n" + first + "\nSELECT 'READY';\n")
        session_a.stdin.flush()
        # A's SQL is intentionally held uncommitted until B blocks on a lock.
        while True:
            line = session_a.stdout.readline()
            if line.strip() == "READY":
                break
            if not line:
                raise AssertionError("Session A failed before synchronization: " + session_a.stderr.read())
        session_b = subprocess.Popen(
            ["psql", "-X", "-Atq", "-v", "ON_ERROR_STOP=1"],
            stdin=subprocess.PIPE, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
            text=True, env={**os.environ, "PGAPPNAME": "gv_test_b"},
        )
        session_b.stdin.write("\\set VERBOSITY verbose\nBEGIN;\n" + second + "\nCOMMIT;\n")
        session_b.stdin.close()
        session_b.stdin = None
        deadline = time.monotonic() + 10
        while time.monotonic() < deadline:
            waiting = run("SELECT count(*) FROM pg_stat_activity WHERE application_name='gv_test_b' AND wait_event_type='Lock';").stdout.strip()
            if waiting == "1":
                break
            if session_b.poll() is not None:
                raise AssertionError("Session B did not wait for the concurrent writer")
            time.sleep(0.05)
        else:
            raise AssertionError("Concurrent lock wait not observed")
        session_a.stdin.write("COMMIT;\n")
        session_a.stdin.close()
        session_a.stdin = None
        _, error_a = session_a.communicate(timeout=15)
        _, error_b = session_b.communicate(timeout=15)
        assert session_a.returncode == 0, error_a
        assert session_b.returncode != 0 and expected_state in error_b, error_b
    finally:
        for session in (session_a, session_b):
            if session is not None and session.poll() is None:
                session.kill()
                session.wait()


tag = "Concurrency " + uuid.uuid4().hex
try:
    # One developer remains represented by a base game throughout duplicate races.
    result = run(f"""BEGIN;
      INSERT INTO public.developers(name,country) VALUES ('{tag} A','Estonia');
      INSERT INTO public.developers(name,country) VALUES ('{tag} B','Finland');
      INSERT INTO public.games(title,full_price,platform) VALUES ('{tag} base',0,'PC');
      INSERT INTO public.game_developers
        SELECT g.game_id,d.developer_id FROM public.games g CROSS JOIN public.developers d
        WHERE g.title='{tag} base' AND d.name IN ('{tag} A','{tag} B');
      COMMIT;
      SELECT game_id FROM public.games WHERE title='{tag} base';
      SELECT developer_id FROM public.developers WHERE name='{tag} A';
      SELECT developer_id FROM public.developers WHERE name='{tag} B';
    """)
    game, developer_a, developer_b = map(int, result.stdout.strip().splitlines())
    # currval is connection-local, so each writer links only its own candidate.
    duplicate = f"""INSERT INTO public.games(title,full_price,platform) VALUES ('{tag} duplicate',0,'PC');
      INSERT INTO public.game_developers VALUES (currval('public.games_game_id_seq'),{developer_a});"""
    race(duplicate, duplicate, "23505")
    assert run(f"SELECT count(*) FROM public.games WHERE title='{tag} duplicate';").stdout.strip() == "1"
    print("PASS: simultaneous exact-set duplicate inserts; only one commits")

    # Keep each developer represented elsewhere; test GAME minimum independently.
    run(f"""BEGIN;
      INSERT INTO public.games(title,full_price,platform) VALUES ('{tag} support',0,'PC');
      INSERT INTO public.game_developers SELECT g.game_id,d.developer_id
        FROM public.games g CROSS JOIN public.developers d
        WHERE g.title='{tag} support' AND d.name IN ('{tag} A','{tag} B');
      COMMIT;""")
    race(
        f"DELETE FROM public.game_developers WHERE game_id={game} AND developer_id={developer_a};",
        f"DELETE FROM public.game_developers WHERE game_id={game} AND developer_id={developer_b};",
        "23514",
    )
    assert run(f"SELECT count(*) FROM public.game_developers WHERE game_id={game};").stdout.strip() == "1"
    print("PASS: concurrent removals cannot leave a game with no developer")

    # Separate fixture for the reciprocal DEVELOPER minimum.
    ids = run(f"""BEGIN;
      INSERT INTO public.developers(name,country) VALUES ('{tag} C','Canada');
      INSERT INTO public.games(title,full_price,platform) VALUES ('{tag} left',0,'PC'),('{tag} right',0,'PC');
      INSERT INTO public.game_developers SELECT g.game_id,d.developer_id
        FROM public.games g CROSS JOIN public.developers d
        WHERE g.title IN ('{tag} left','{tag} right') AND d.name IN ('{tag} A','{tag} C');
      COMMIT;
      SELECT game_id FROM public.games WHERE title IN ('{tag} left','{tag} right') ORDER BY title;
      SELECT developer_id FROM public.developers WHERE name='{tag} C';""").stdout.strip().splitlines()
    left, right, developer_c = map(int, ids)
    race(
        f"DELETE FROM public.game_developers WHERE game_id={left} AND developer_id={developer_c};",
        f"DELETE FROM public.game_developers WHERE game_id={right} AND developer_id={developer_c};",
        "23514",
    )
    assert run(f"SELECT count(*) FROM public.game_developers WHERE developer_id={developer_c};").stdout.strip() == "1"
    print("PASS: concurrent removals cannot leave a developer without games")
finally:
    run(f"""BEGIN;
      DELETE FROM public.games WHERE title LIKE '{tag}%';
      DELETE FROM public.developers WHERE name LIKE '{tag}%';
      COMMIT;""")
