-- =====================
-- DDL - BUAT TABEL
-- =====================
CREATE TABLE mobil (
    id_mobil    NUMBER PRIMARY KEY,
    merk        VARCHAR2(50) NOT NULL,
    model       VARCHAR2(50) NOT NULL,
    tahun       NUMBER(4),
    warna       VARCHAR2(30),
    harga       NUMBER(15),
    stok        NUMBER DEFAULT 0
);

CREATE TABLE customer (
    id_customer NUMBER PRIMARY KEY,
    nama        VARCHAR2(100) NOT NULL,
    no_telp     VARCHAR2(20),
    alamat      VARCHAR2(200),
    email       VARCHAR2(100)
);

CREATE TABLE transaksi (
    id_transaksi  NUMBER PRIMARY KEY,
    id_customer   NUMBER REFERENCES customer(id_customer),
    id_mobil      NUMBER REFERENCES mobil(id_mobil),
    tgl_transaksi DATE DEFAULT SYSDATE,
    total_harga   NUMBER(15),
    status        VARCHAR2(20) DEFAULT 'pending'
);

-- =====================
-- INSERT DATA MOBIL
-- =====================
INSERT INTO mobil VALUES (1, 'Toyota', 'Avanza', 2022, 'Putih', 185000000, 3);
INSERT INTO mobil VALUES (2, 'Honda', 'Brio', 2023, 'Merah', 165000000, 5);
INSERT INTO mobil VALUES (3, 'Mitsubishi', 'Xpander', 2022, 'Hitam', 265000000, 2);

-- =====================
-- INSERT DATA CUSTOMER
-- =====================
INSERT INTO customer VALUES (1, 'Budi Santoso', '081234567890', 'Jl. Sudirman No.10 Pekanbaru', 'budi@email.com');
INSERT INTO customer VALUES (2, 'Siti Rahayu', '082345678901', 'Jl. Diponegoro No.5 Pekanbaru', 'siti@email.com');
INSERT INTO customer VALUES (3, 'Ahmad Fauzi', '083456789012', 'Jl. Gajah Mada No.20 Pekanbaru', 'ahmad@email.com');

-- =====================
-- INSERT DATA TRANSAKSI
-- =====================
INSERT INTO transaksi VALUES (1, 1, 1, SYSDATE, 185000000, 'selesai');
INSERT INTO transaksi VALUES (2, 2, 2, SYSDATE, 165000000, 'pending');
INSERT INTO transaksi VALUES (3, 3, 3, SYSDATE, 265000000, 'selesai');

-- =====================
-- QUERY JOIN (BUGGY)
-- =====================
SELECT t.id_transaksi, c.nama, m.merk, m.model, t.total_harga, t.status
FROM transaksi t
JOIN customers c ON t.id_customer = c.id_customer
JOIN mobil m ON t.id_mobil = m.id_mobil;

-- =====================
-- QUERY JOIN (FIXED)
-- =====================
SELECT t.id_transaksi, c.nama, m.merk, m.model, t.total_harga, t.status
FROM transaksi t
JOIN customer c ON t.id_customer = c.id_customer
JOIN mobil m ON t.id_mobil = m.id_mobil;

-- =====================
-- STORED PROCEDURE
-- =====================
CREATE OR REPLACE PROCEDURE tambah_transaksi (
    p_id        IN NUMBER,
    p_customer  IN NUMBER,
    p_mobil     IN NUMBER,
    p_harga     IN NUMBER
) AS
BEGIN
    INSERT INTO transaksi (id_transaksi, id_customer, id_mobil, tgl_transaksi, total_harga, status)
    VALUES (p_id, p_customer, p_mobil, SYSDATE, p_harga, 'pending');
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Transaksi berhasil ditambahkan');
END;

-- =====================
-- EKSEKUSI PROCEDURE
-- =====================
BEGIN
    tambah_transaksi(4, 1, 2, 165000000);
END;

SELECT * FROM transaksi

--fuction (Perintah yang mengembalikan nilai/hasil)
CREATE OR REPLACE FUNCTION hitung_total_transaksi(
    p_id_customer IN NUMBER
) RETURN NUMBER AS
    v_total NUMBER;
BEGIN
    SELECT COUNT(*) INTO v_total
    FROM transaksi
    WHERE id_customer = p_id_customer;
    RETURN v_total;
END;

--tes
SELECT hitung_total_transaksi(1) FROM dual

--procedure (Perintah yang bisa dipanggil berulang kali)
CREATE OR REPLACE PROCEDURE update_status_transaksi(
    p_id_transaksi IN NUMBER,
    p_status       IN VARCHAR2
) AS
BEGIN
    UPDATE transaksi
    SET status = p_status
    WHERE id_transaksi = p_id_transaksi;
    COMMIT;
    DBMS_OUTPUT.PUT_LINE('Status transaksi ' || p_id_transaksi || ' berhasil diupdate');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK;
        DBMS_OUTPUT.PUT_LINE('Error: ' || SQLERRM);
END;

--tes 
BEGIN
    update_status_transaksi(2, 'selesai');
END;

SELECT * FROM transaksi

-- Trigger (Aksi otomatis yang jalan sendiri ketika ada kejadian)
CREATE OR REPLACE TRIGGER kurangi_stok
AFTER INSERT ON transaksi
FOR EACH ROW                                                                                                                                                -- setiap baris
BEGIN
    UPDATE mobil                                                                                                                                           --mengubah data di mobil 
    SET stok = stok - 1                                                                                                                                  -- kurangin kolom
    WHERE id_mobil = :NEW.id_mobil;                                                                                                                 -- stokny mobil id yg sama
END;

--tes 
BEGIN
    tambah_transaksi(5, 2, 1, 185000000);  -- transaksi ,customer,mobil (id)(procedure/parameter)
END;

SELECT * FROM mobil

--cursor (menampilkn tabel mobil)
DECLARE
    CURSOR c_transaksi IS
        SELECT t.id_transaksi, c.nama, m.merk, t.total_harga, t.status
        FROM transaksi t
        JOIN customer c ON t.id_customer = c.id_customer
        JOIN mobil m ON t.id_mobil = m.id_mobil;
    
    v_id        transaksi.id_transaksi%TYPE;
    v_nama      customer.nama%TYPE;
    v_merk      mobil.merk%TYPE;
    v_harga     transaksi.total_harga%TYPE;
    v_status    transaksi.status%TYPE;
BEGIN
    OPEN c_transaksi;
    LOOP
        FETCH c_transaksi INTO v_id, v_nama, v_merk, v_harga, v_status;
        EXIT WHEN c_transaksi%NOTFOUND;
        DBMS_OUTPUT.PUT_LINE('ID: ' || v_id || ' | ' || v_nama || ' | ' || v_merk || ' | ' || v_harga || ' | ' || v_status);
    END LOOP;
    CLOSE c_transaksi;
END;

--exception 
DECLARE
    v_harga transaksi.total_harga%TYPE;
BEGIN
    SELECT total_harga INTO v_harga
    FROM transaksi
    WHERE id_transaksi = 999;
    
    DBMS_OUTPUT.PUT_LINE('Harga: ' || v_harga);
EXCEPTION
    WHEN NO_DATA_FOUND THEN
        DBMS_OUTPUT.PUT_LINE('Error: Transaksi ID 999 tidak ditemukan!');
    WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('Error tidak terduga: ' || SQLERRM);
END;

--
