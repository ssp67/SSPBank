-- Create roles and users

CREATE ROLE bank_admin LOGIN PASSWORD 'adminpass';
CREATE ROLE teller LOGIN PASSWORD 'tellerpass';
CREATE ROLE auditor LOGIN PASSWORD 'auditorpass';
CREATE ROLE app_user LOGIN PASSWORD 'apppass';

-- Optional: create a dedicated readonly role for reporting
CREATE ROLE reporting NOLOGIN;
