-- Lab 08 — seed para docker postgres
-- Simula el schema de una app que usa la base de datos

CREATE TABLE IF NOT EXISTS app_users (
    id          SERIAL PRIMARY KEY,
    username    VARCHAR(50) UNIQUE NOT NULL,
    email       VARCHAR(100) UNIQUE NOT NULL,
    created_at  TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app_sessions (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER REFERENCES app_users(id),
    token       VARCHAR(255) NOT NULL,
    expires_at  TIMESTAMP NOT NULL,
    created_at  TIMESTAMP DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS app_audit_log (
    id          SERIAL PRIMARY KEY,
    user_id     INTEGER REFERENCES app_users(id),
    action      VARCHAR(100) NOT NULL,
    detail      TEXT,
    created_at  TIMESTAMP DEFAULT NOW()
);

-- Datos de prueba
INSERT INTO app_users (username, email) VALUES
    ('franco',   'franco@example.com'),
    ('ana',      'ana@example.com'),
    ('martin',   'martin@example.com')
ON CONFLICT DO NOTHING;

INSERT INTO app_audit_log (user_id, action, detail) VALUES
    (1, 'LOGIN',  'ip: 10.0.1.5'),
    (2, 'LOGIN',  'ip: 10.0.1.8'),
    (1, 'UPDATE', 'cambió email')
ON CONFLICT DO NOTHING;
