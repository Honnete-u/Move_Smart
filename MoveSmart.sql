-- MoveSmart database schema
-- Target: MySQL 8.0+
-- Based on the supplied MoveSmart ERD.

CREATE DATABASE IF NOT EXISTS movesmart
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
USE movesmart;

CREATE TABLE role (
  role_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT
) ENGINE=InnoDB;

-- Configuration table: intentionally has no foreign keys, as stated in the ERD.
CREATE TABLE status_transition (
  transition_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  from_status VARCHAR(60) NOT NULL,
  to_status VARCHAR(60) NOT NULL,
  allowed_role VARCHAR(100) NOT NULL,
  description TEXT,
  UNIQUE KEY uq_status_transition (from_status, to_status, allowed_role)
) ENGINE=InnoDB;

CREATE TABLE user (
  user_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  role_id BIGINT UNSIGNED NOT NULL,
  full_name VARCHAR(160) NOT NULL,
  email VARCHAR(255) NOT NULL UNIQUE,
  phone VARCHAR(30),
  password_hash VARCHAR(255) NOT NULL,
  account_status VARCHAR(40) NOT NULL DEFAULT 'active',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_by BIGINT UNSIGNED NULL,
  last_login_at DATETIME NULL,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_user_role FOREIGN KEY (role_id) REFERENCES role(role_id),
  CONSTRAINT fk_user_created_by FOREIGN KEY (created_by) REFERENCES user(user_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE parcel_category (
  category_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  name VARCHAR(100) NOT NULL UNIQUE,
  description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE vehicle (
  vehicle_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  plate_number VARCHAR(30) NOT NULL UNIQUE,
  vehicle_type VARCHAR(80) NOT NULL,
  capacity_kg DECIMAL(10,2) NOT NULL,
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  CONSTRAINT chk_vehicle_capacity CHECK (capacity_kg > 0)
) ENGINE=InnoDB;

CREATE TABLE driver (
  driver_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL UNIQUE,
  license_number VARCHAR(80) NOT NULL UNIQUE,
  vehicle_id BIGINT UNSIGNED NULL UNIQUE,
  driver_status VARCHAR(40) NOT NULL DEFAULT 'available',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_driver_user FOREIGN KEY (user_id) REFERENCES user(user_id),
  CONSTRAINT fk_driver_vehicle FOREIGN KEY (vehicle_id) REFERENCES vehicle(vehicle_id) ON DELETE SET NULL
) ENGINE=InnoDB;

CREATE TABLE exception_reason (
  reason_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  label VARCHAR(120) NOT NULL UNIQUE,
  description TEXT,
  is_active BOOLEAN NOT NULL DEFAULT TRUE
) ENGINE=InnoDB;

CREATE TABLE parcel (
  parcel_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  category_id BIGINT UNSIGNED NOT NULL,
  registered_by BIGINT UNSIGNED NOT NULL,
  tracking_reference VARCHAR(80) NOT NULL UNIQUE,
  sender_name VARCHAR(160) NOT NULL,
  sender_phone VARCHAR(30) NOT NULL,
  sender_email VARCHAR(255),
  recipient_name VARCHAR(160) NOT NULL,
  recipient_phone VARCHAR(30) NOT NULL,
  pickup_address TEXT NOT NULL,
  destination_address TEXT NOT NULL,
  pickup_area VARCHAR(160) NOT NULL,
  destination_area VARCHAR(160) NOT NULL,
  weight_kg DECIMAL(10,2) NOT NULL,
  priority VARCHAR(30) NOT NULL DEFAULT 'normal',
  description TEXT,
  delivery_instructions TEXT,
  internal_notes TEXT,
  current_status VARCHAR(60) NOT NULL DEFAULT 'registered',
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_parcel_category FOREIGN KEY (category_id) REFERENCES parcel_category(category_id),
  CONSTRAINT fk_parcel_registered_by FOREIGN KEY (registered_by) REFERENCES user(user_id),
  CONSTRAINT chk_parcel_weight CHECK (weight_kg > 0),
  INDEX idx_parcel_status (current_status),
  INDEX idx_parcel_created_at (created_at)
) ENGINE=InnoDB;

CREATE TABLE audit_log (
  log_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  user_id BIGINT UNSIGNED NOT NULL,
  action VARCHAR(100) NOT NULL,
  entity_type VARCHAR(100) NOT NULL,
  entity_id BIGINT UNSIGNED NOT NULL,
  old_value JSON NULL,
  new_value JSON NULL,
  ip_address VARCHAR(45),
  created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES user(user_id),
  INDEX idx_audit_entity (entity_type, entity_id),
  INDEX idx_audit_created_at (created_at)
) ENGINE=InnoDB;

CREATE TABLE app_setting (
  setting_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  setting_key VARCHAR(120) NOT NULL UNIQUE,
  setting_value TEXT,
  updated_by BIGINT UNSIGNED NOT NULL,
  updated_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  CONSTRAINT fk_setting_user FOREIGN KEY (updated_by) REFERENCES user(user_id)
) ENGINE=InnoDB;

CREATE TABLE shipment_status_history (
  history_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  parcel_id BIGINT UNSIGNED NOT NULL,
  previous_status VARCHAR(60),
  new_status VARCHAR(60) NOT NULL,
  changed_by BIGINT UNSIGNED NOT NULL,
  changed_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  remarks TEXT,
  CONSTRAINT fk_history_parcel FOREIGN KEY (parcel_id) REFERENCES parcel(parcel_id),
  CONSTRAINT fk_history_user FOREIGN KEY (changed_by) REFERENCES user(user_id),
  INDEX idx_history_parcel_time (parcel_id, changed_at)
) ENGINE=InnoDB;

CREATE TABLE delivery_assignment (
  assignment_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  parcel_id BIGINT UNSIGNED NOT NULL,
  driver_id BIGINT UNSIGNED NOT NULL,
  assigned_by BIGINT UNSIGNED NOT NULL,
  assigned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  assignment_status VARCHAR(50) NOT NULL DEFAULT 'assigned',
  is_active BOOLEAN NOT NULL DEFAULT TRUE,
  reassign_reason TEXT,
  acknowledged_at DATETIME NULL,
  CONSTRAINT fk_assignment_parcel FOREIGN KEY (parcel_id) REFERENCES parcel(parcel_id),
  CONSTRAINT fk_assignment_driver FOREIGN KEY (driver_id) REFERENCES driver(driver_id),
  CONSTRAINT fk_assignment_user FOREIGN KEY (assigned_by) REFERENCES user(user_id),
  INDEX idx_assignment_parcel (parcel_id),
  INDEX idx_assignment_driver (driver_id)
) ENGINE=InnoDB;

CREATE TABLE delivery_confirmation (
  confirmation_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  parcel_id BIGINT UNSIGNED NOT NULL UNIQUE,
  driver_id BIGINT UNSIGNED NOT NULL,
  submitted_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  delivered_at DATETIME NULL,
  delivery_note TEXT,
  CONSTRAINT fk_confirmation_parcel FOREIGN KEY (parcel_id) REFERENCES parcel(parcel_id),
  CONSTRAINT fk_confirmation_driver FOREIGN KEY (driver_id) REFERENCES driver(driver_id)
) ENGINE=InnoDB;

CREATE TABLE delivery_exception (
  exception_id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
  parcel_id BIGINT UNSIGNED NOT NULL,
  driver_id BIGINT UNSIGNED NOT NULL,
  reason_id BIGINT UNSIGNED NOT NULL,
  reported_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  details TEXT,
  exception_status VARCHAR(50) NOT NULL DEFAULT 'open',
  next_action TEXT,
  resolved_by BIGINT UNSIGNED NULL,
  resolved_at DATETIME NULL,
  CONSTRAINT fk_exception_parcel FOREIGN KEY (parcel_id) REFERENCES parcel(parcel_id),
  CONSTRAINT fk_exception_driver FOREIGN KEY (driver_id) REFERENCES driver(driver_id),
  CONSTRAINT fk_exception_reason FOREIGN KEY (reason_id) REFERENCES exception_reason(reason_id),
  CONSTRAINT fk_exception_resolved_by FOREIGN KEY (resolved_by) REFERENCES user(user_id) ON DELETE SET NULL,
  INDEX idx_exception_parcel (parcel_id),
  INDEX idx_exception_status (exception_status)
) ENGINE=InnoDB;

-- Suggested initial roles (optional):
-- INSERT INTO role (name, description) VALUES
-- ('Admin', 'System administrator'),
-- ('Dispatcher', 'Registers parcels and assigns deliveries'),
-- ('Driver', 'Delivers parcels');
