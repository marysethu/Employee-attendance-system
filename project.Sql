create database Employees_Attendence_System;
use Employees_Attendence_System;
CREATE TABLE Departments (
    department_id INT PRIMARY KEY AUTO_INCREMENT,
    department_name VARCHAR(100) NOT NULL UNIQUE,
    manager_id INT NULL
);

CREATE TABLE Employees (
    employee_id INT PRIMARY KEY AUTO_INCREMENT,
    first_name VARCHAR(50) NOT NULL,
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    phone_number VARCHAR(15),
    hire_date DATE NOT NULL,
    department_id INT,
    position VARCHAR(100),
    status ENUM('Active', 'Inactive') DEFAULT 'Active',
    FOREIGN KEY (department_id) REFERENCES Departments(department_id)
);

CREATE TABLE AttendanceRecords (
    record_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id INT,
    date DATE NOT NULL,
    clock_in_time DATETIME,
    clock_out_time DATETIME,
    total_hours DECIMAL(5,2),
    status ENUM('Present','Absent','On Leave','Half Day') DEFAULT 'Present',
    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id)
);

CREATE TABLE LeaveRequests (
    leave_id INT PRIMARY KEY AUTO_INCREMENT,
    employee_id INT,
    leave_type ENUM('Sick','Casual','Vacation','Maternity','Other') NOT NULL,
    start_date DATE NOT NULL,
    end_date DATE NOT NULL,
    reason TEXT,
    status ENUM('Pending','Approved','Rejected') DEFAULT 'Pending',
    approved_by INT,
    FOREIGN KEY (employee_id) REFERENCES Employees(employee_id),
    FOREIGN KEY (approved_by) REFERENCES Employees(employee_id)
);

INSERT INTO Departments (department_name, manager_id)
VALUES
('Human Resources', NULL),
('Finance', NULL),
('IT', NULL),
('Marketing', NULL),
('Operations', NULL);

INSERT INTO Employees (first_name, last_name, email, phone_number, hire_date, department_id, position, status)
VALUES
('Alice', 'Johnson', 'alice.johnson@company.com', '555-1234', '2023-01-10', 1, 'HR Manager', 'Active'),
('Bob', 'Smith', 'bob.smith@company.com', '555-2345', '2023-03-15', 2, 'Accountant', 'Active'),
('Charlie', 'Brown', 'charlie.brown@company.com', '555-3456', '2022-11-01', 3, 'Software Engineer', 'Active'),
('Diana', 'White', 'diana.white@company.com', '555-4567', '2024-02-20', 4, 'Marketing Specialist', 'Active'),
('Ethan', 'Lee', 'ethan.lee@company.com', '555-5678', '2023-07-05', 5, 'Operations Analyst', 'Active');

INSERT INTO AttendanceRecords (employee_id, date, clock_in_time, clock_out_time, total_hours, status)
VALUES
(1, '2025-10-20', '2025-10-20 09:00:00', '2025-10-20 17:00:00', 8.00, 'Present'),
(2, '2025-10-20', '2025-10-20 09:15:00', '2025-10-20 17:10:00', 7.92, 'Present'),
(3, '2025-10-20', NULL, NULL, 0.00, 'On Leave'),
(4, '2025-10-20', '2025-10-20 09:30:00', '2025-10-20 16:30:00', 7.00, 'Half Day'),
(5, '2025-10-20', NULL, NULL, 0.00, 'Absent');

INSERT INTO LeaveRequests (employee_id, leave_type, start_date, end_date, reason, status, approved_by)
VALUES
(3, 'Sick', '2025-10-19', '2025-10-21', 'Flu and fever', 'Approved', 1),
(5, 'Vacation', '2025-10-25', '2025-10-30', 'Family trip', 'Pending', NULL),
(2, 'Casual', '2025-09-10', '2025-09-11', 'Personal matters', 'Approved', 1),
(4, 'Maternity', '2025-08-01', '2025-09-15', 'Maternity leave', 'Approved', 1),
(1, 'Other', '2025-07-05', '2025-07-06', 'Conference attendance', 'Approved', 2);



SELECT 
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    d.department_name,
    a.date,
    a.status,
    a.total_hours
FROM Employees e
JOIN Departments d ON e.department_id = d.department_id
LEFT JOIN AttendanceRecords a ON e.employee_id = a.employee_id
WHERE a.date = '2025-10-20';

CREATE VIEW v_AttendanceSummary AS
SELECT 
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
    d.department_name,
    COUNT(a.record_id) AS total_days,
    SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) AS days_present,
    SUM(a.total_hours) AS total_hours_worked
FROM Employees e
JOIN Departments d ON e.department_id = d.department_id
LEFT JOIN AttendanceRecords a ON e.employee_id = a.employee_id
GROUP BY e.employee_id, d.department_name;

SELECT * FROM v_AttendanceSummary;

DELIMITER $$

CREATE TRIGGER trg_UpdateAttendanceOnLeave
AFTER UPDATE ON LeaveRequests
FOR EACH ROW
BEGIN
    IF NEW.status = 'Approved' THEN
        UPDATE AttendanceRecords
        SET status = 'On Leave', total_hours = 0
        WHERE employee_id = NEW.employee_id
        AND date BETWEEN NEW.start_date AND NEW.end_date;
    END IF;
END$$

DELIMITER ;

DELIMITER $$

CREATE PROCEDURE GetMonthlyAttendanceReport(IN report_month INT, IN report_year INT)
BEGIN
    SELECT 
        e.employee_id,
        CONCAT(e.first_name, ' ', e.last_name) AS employee_name,
        COUNT(a.record_id) AS total_days,
        SUM(CASE WHEN a.status = 'Present' THEN 1 ELSE 0 END) AS days_present,
        SUM(a.total_hours) AS total_hours_worked
    FROM Employees e
    JOIN AttendanceRecords a ON e.employee_id = a.employee_id
    WHERE MONTH(a.date) = report_month AND YEAR(a.date) = report_year
    GROUP BY e.employee_id
    HAVING days_present > 0;
END$$

DELIMITER ;

CALL GetMonthlyAttendanceReport(10, 2025);

CREATE INDEX idx_employee_date ON AttendanceRecords(employee_id, date);

SELECT 
    e.employee_id,
    CONCAT(e.first_name, ' ', e.last_name) AS employee_name
FROM Employees e
WHERE e.employee_id IN (
    SELECT employee_id
    FROM LeaveRequests
    GROUP BY employee_id
    HAVING COUNT(leave_id) > 1
);

SELECT 
    d.department_name,
    AVG(a.total_hours) AS avg_hours
FROM Departments d
JOIN Employees e ON d.department_id = e.department_id
JOIN AttendanceRecords a ON e.employee_id = a.employee_id
GROUP BY d.department_name
HAVING AVG(a.total_hours) > 6;

SELECT * 
FROM Employees
WHERE first_name LIKE 'A%';
SELECT * 
FROM Employees
WHERE last_name LIKE '%son%';
