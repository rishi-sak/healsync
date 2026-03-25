-- ============================================
-- HealSync Database Schema
-- ============================================

-- Database Name: healsync_db;

-- 1️⃣ USERS TABLE
CREATE TABLE users (
    id INT NOT NULL AUTO_INCREMENT,
    name VARCHAR(100),
    email VARCHAR(100) UNIQUE,
    password VARCHAR(255),
    role ENUM('Patient','Caregiver') DEFAULT 'Patient',
    PRIMARY KEY (id)
);

-- ============================================

-- 2️⃣ MEDICINE SCHEDULE TABLE
CREATE TABLE medicine_schedule (
    id INT NOT NULL AUTO_INCREMENT,
    user_id INT NOT NULL,
    medicine_name VARCHAR(100) NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    dosage_count INT NOT NULL,
    dosage_instructions VARCHAR(255),
    reminder_type VARCHAR(50),
    PRIMARY KEY (id),

    CONSTRAINT fk_user
    FOREIGN KEY (user_id)
    REFERENCES users(id)
    ON DELETE CASCADE
);

-- ============================================

-- 3️⃣ MEDICINE TIMES TABLE
CREATE TABLE medicine_times (
    id INT NOT NULL AUTO_INCREMENT,
    medicine_id INT NOT NULL,
    med_time TIME NOT NULL,
    PRIMARY KEY (id),

    CONSTRAINT fk_medicine
    FOREIGN KEY (medicine_id)
    REFERENCES medicine_schedule(id)
    ON DELETE CASCADE
);

-- ============================================

-- 4️⃣ DOSE LOGS TABLE
CREATE TABLE dose_logs (
    id INT NOT NULL AUTO_INCREMENT,
    user_id INT NOT NULL,
    medicine_name VARCHAR(255) NOT NULL,
    med_time TIME NOT NULL,
    event_date DATE NOT NULL,
    status ENUM('TAKEN','MISSED','SKIPPED') NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (id),

    CONSTRAINT uq_dose UNIQUE (user_id, medicine_name, med_time, event_date)
);

-- ============================================
-- END OF FILE
-- ============================================