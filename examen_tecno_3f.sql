CREATE DATABASE IF NOT EXISTS examen_tecno_3f;
use examen_tecno_3f;

/*table*/

CREATE TABLE IF NOT EXISTS Categoria (
   categoria_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
   nombre VARCHAR(50) NOT NULL
);



CREATE TABLE IF NOT EXISTS Producto(
    id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    categoria_id INT NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    cantidad VARCHAR(50) NOT NULL,
    precio VARCHAR(50) NOT NULL,
    FOREIGN KEY (categoria_id) REFERENCES Categoria(categoria_id)
);


CREATE TABLE IF NOT EXISTS log_categoria (
    log_id INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    categoria_id INT,
    nombre_categoria VARCHAR(50),
    usuario_eliminacion VARCHAR(50),
    fecha_hora_eliminacion TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
/*insert*/
insert into Categoria (nombre) VALUES 
('Electrico'),
('Hogar'),
('Bazar'),
('Decoracion');

insert into Producto(id, categoria_id, nombre, cantidad, precio) Values
(1, 1, 'Toshiba', '10', '700'),
(2, 2, 'Cooler', '2', '100'),
(3, 1, 'Teclado Gamer', '3', '90'),
(4, 2, 'Mouse LG', '0', '200'),
(5, 2, 'Monitor Samsung 12"', '20', '1900.36');

/*Pruebas*/
/*1*/
SELECT nombre, cantidad
FROM Producto
WHERE cantidad < 5
ORDER BY cantidad DESC;

/*2*/

SELECT * FROM Producto
WHERE precio >= 50 AND precio <= 200;

/*3*/

SELECT P.nombre AS nombre_producto, C.nombre AS nombre_categoria, P.precio
FROM Producto AS P
JOIN Categoria AS C ON P.categoria_id = C.categoria_id
WHERE P.precio > 100;

/*4*/

CREATE VIEW VistaProductosMasCaros AS
SELECT P.nombre AS nombre_producto, C.nombre AS nombre_categoria, P.precio
FROM Producto AS P
JOIN Categoria AS C ON P.categoria_id = C.categoria_id
ORDER BY P.precio DESC
LIMIT 5;

/*5*/

SELECT C.categoria_id AS id, C.nombre AS nombre, COUNT(P.id) AS cantidad
FROM Categoria AS C
LEFT JOIN Producto AS P ON C.categoria_id = P.categoria_id
GROUP BY C.categoria_id, C.nombre;

/*6*/
SELECT C.categoria_id AS id, C.nombre AS nombre, COUNT(P.id) AS cantidad
FROM Categoria AS C
LEFT JOIN Producto AS P ON C.categoria_id = P.categoria_id
GROUP BY C.categoria_id, C.nombre
HAVING COUNT(P.id) > 0;

/*7*/

SELECT C.categoria_id AS id, C.nombre AS nombre
FROM Categoria AS C
WHERE C.categoria_id NOT IN (
    SELECT DISTINCT P.categoria_id
    FROM Producto AS P
);

/*8*/

SELECT C.nombre AS nombre_categoria,
       CONCAT(FORMAT((COUNT(P.id) / (SELECT COUNT(*) FROM Producto)) * 100, 0), '%') AS porcentaje
FROM Categoria AS C
LEFT JOIN Producto AS P ON C.categoria_id = P.categoria_id
GROUP BY C.nombre;

/*9*/
/*SP*/

DELIMITER //

CREATE PROCEDURE InsertarCategoria(IN nueva_categoria VARCHAR(50))
BEGIN
    DECLARE categoria_existente INT;

    SELECT COUNT(*) INTO categoria_existente FROM Categoria WHERE nombre = 'nueva_categoria';

    IF categoria_existente = 0 THEN

        INSERT INTO Categoria(nombre) VALUES (nueva_categoria);
        SELECT 'Categoría insertada correctamente' AS mensaje;
    ELSE
        SELECT 'La categoría ya existe' AS mensaje;
    END IF;
END //

CALL InsertarCategoria('Oficina');

/*10*/

INSERT INTO Producto( id, categoria_id, nombre, cantidad, precio)
VALUES ( 6, 5, 'Mouse Pad', '10', '1000.00');

/*11*/

UPDATE Producto
SET cantidad = '30'
WHERE categoria_id = (SELECT categoria_id FROM Categoria WHERE nombre = 'Electrico');

SELECT * FROM Producto WHERE categoria_id = (SELECT categoria_id FROM Categoria WHERE nombre = 'Electrico');


/*12*/
DELIMITER //

CREATE TRIGGER before_delete_categoria
BEFORE DELETE ON Categoria
FOR EACH ROW
BEGIN
    INSERT INTO log_categoria (categoria_id, nombre_categoria, usuario_eliminacion)
    VALUES (OLD.categoria_id, OLD.nombre, 'nombre_usuario_que_elimina');
END //

DELIMITER ;


CREATE USER 'tot'@'vas' IDENTIFIED BY '1234';


GRANT ALL PRIVILEGES ON examen_tecno_3f.* TO 'tot'@'vas';


FLUSH PRIVILEGES;


