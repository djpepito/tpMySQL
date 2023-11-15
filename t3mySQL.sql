CREATE DATABASE IF NOT EXISTS tp_1;
USE tp_1;

CREATE TABLE IF NOT EXISTS tipoDeCliente (
    idTipoDeCliente INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    cliente_tipo ENUM('mayorista', 'minorista')
);

CREATE TABLE IF NOT EXISTS tipoDeProducto (
    idTipoDeProducto INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    tipoDeProducto VARCHAR(40)
);

CREATE TABLE IF NOT EXISTS nacionalidad(
    idNacionalidad INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    nombre VARCHAR(100) NOT NULL
);


CREATE TABLE IF NOT EXISTS informacionDeCliente (
    idInformacionDeCliente INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    idTipoDeCliente INT NOT NULL,
    nombre VARCHAR(50) NOT NULL,
    apellido VARCHAR(50) NOT NULL,
    dni VARCHAR(50) NOT NULL,
    direccion VARCHAR(100) NOT NULL,
    nacionalidad INT NOT NULL,
    FOREIGN KEY (idTipoDeCliente) REFERENCES tipoDeCliente(idTipoDeCliente),
    FOREIGN KEY (nacionalidad) REFERENCES nacionalidad(idNacionalidad)
);

CREATE TABLE IF NOT EXISTS cuentaDelCliente (
    idCuentaDelCliente INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    numeroDeCuenta INT(8) UNSIGNED,
    idInformacionDeCliente INT,
    FOREIGN KEY (idInformacionDeCliente) REFERENCES informacionDeCliente(idInformacionDeCliente)
);


CREATE TABLE IF NOT EXISTS infoDelProducto (
    idProducto INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    idTipoDeProducto INT NOT NULL,
    nombreDeMarca VARCHAR(40),
    fechaDeEntrada DATE,
    precio DECIMAL(10, 2),
    nacionalidad INT NOT NULL,
    FOREIGN KEY (idTipoDeProducto) REFERENCES tipoDeProducto(idTipoDeProducto),
    FOREIGN KEY (nacionalidad) REFERENCES nacionalidad(idNacionalidad)
);

CREATE TABLE IF NOT EXISTS productosComprados (
    idCompra INT NOT NULL PRIMARY KEY AUTO_INCREMENT,
    idCuentaDelCliente INT NOT NULL,
    idProducto INT NOT NULL,
    cantidad INT,
    FOREIGN KEY (idCuentaDelCliente) REFERENCES cuentaDelCliente(idCuentaDelCliente),
    FOREIGN KEY (idProducto) REFERENCES infoDelProducto(idProducto)
);


CREATE TEMPORARY TABLE  factura (
    cliente_id INT,
    cliente_nombre VARCHAR(50),
    producto_id INT,
    producto_nombre VARCHAR(50),
    cantidad INT,
    precio_unitario DECIMAL(10, 2),
    total DECIMAL(10, 2)
);

/*funciones*/

DELIMITER $$
CREATE FUNCTION CalcularCostoTotalConNombre(idCliente INT) RETURNS VARCHAR(100)
BEGIN
  DECLARE costoTotal DECIMAL(10, 2);
  DECLARE nombreCliente VARCHAR(100);
  
  SELECT ic.nombre INTO nombreCliente
  FROM informacionDeCliente ic
  WHERE ic.idInformacionDeCliente = idCliente;

  SELECT SUM(pc.cantidad * i.precio) INTO costoTotal
  FROM productosComprados pc
  JOIN infoDelProducto i ON pc.idProducto = i.idProducto
  WHERE pc.idCuentaDelCliente = idCliente;

  RETURN CONCAT('Nombre Cliente: ', nombreCliente, ', Costo Total: ', costoTotal);
END;

$$ 

DELIMITER $$

CREATE FUNCTION AumentarPrecioProductos(porcentaje DECIMAL(5, 2))
RETURNS INT
BEGIN
  DECLARE productos_actualizados INT;


  UPDATE infoDelProducto
  SET precio = precio * (1 + (porcentaje / 100));


  SET productos_actualizados = ROW_COUNT();

 
  RETURN productos_actualizados;
END;

$$
/*Stored procedure*/

DELIMITER $$

CREATE PROCEDURE SP_NombreClienteCantidadYCostoTotalProductos(IN cliente_id INT, 
OUT cliente_nombre VARCHAR(100), OUT cantidad_productos INT, 
OUT costo_total DECIMAL(10, 2))
BEGIN

  SELECT nombre INTO cliente_nombre
  FROM informacionDeCliente
  WHERE idInformacionDeCliente = cliente_id;

  SELECT SUM(pc.cantidad) INTO cantidad_productos
  FROM productosComprados pc
  JOIN cuentaDelCliente c ON pc.idCuentaDelCliente = c.idCuentaDelCliente
  WHERE c.idInformacionDeCliente = cliente_id;

  SELECT SUM(pc.cantidad * i.precio) INTO costo_total
  FROM productosComprados pc
  JOIN infoDelProducto i ON pc.idProducto = i.idProducto
  JOIN cuentaDelCliente c ON pc.idCuentaDelCliente = c.idCuentaDelCliente
  WHERE c.idInformacionDeCliente = cliente_id;
END 

$$

DELIMITER $$

CREATE PROCEDURE SP_AdministracionDeInventario(IN tipoDeProducto_id INT, 
OUT tipo_producto VARCHAR(40), OUT nombre_marca VARCHAR(40), 
OUT fecha_de_entrada DATE, OUT costo_total DECIMAL(10, 2),
 OUT nacionalidad VARCHAR(100))
BEGIN

  SELECT tipoDeProducto INTO tipo_producto
  FROM tipoDeProducto
  WHERE idTipoDeProducto = tipoDeProducto_id;

  SELECT nombreDeMarca INTO nombre_marca
  FROM infoDelProducto
  WHERE idTipoDeProducto = tipoDeProducto_id
  LIMIT 1;


  SELECT MIN(fechaDeEntrada) INTO fecha_de_entrada
  FROM infoDelProducto
  WHERE idTipoDeProducto = tipoDeProducto_id;


  SELECT SUM(pc.cantidad * i.precio) INTO costo_total
  FROM productosComprados pc
  JOIN infoDelProducto i ON pc.idProducto = i.idProducto
  WHERE i.idTipoDeProducto = tipoDeProducto_id;


  SELECT n.nombre INTO nacionalidad
  FROM nacionalidad n
  JOIN infoDelProducto i ON n.idNacionalidad = i.nacionalidad
  WHERE i.idTipoDeProducto = tipoDeProducto_id
  LIMIT 1;
END 

$$

/*triggers*/

DELIMITER $$
CREATE TRIGGER ModificarDNIAntesDeInsert 
BEFORE INSERT ON informacionDeCliente
FOR EACH ROW
BEGIN
  SET NEW.dni = CONCAT(NEW.dni, ', Nueva Información');
END;
$$

DELIMITER $$
CREATE TRIGGER ModificarDireccionAntesDeInsert
BEFORE INSERT ON informacionDeCliente
FOR EACH ROW
BEGIN
  SET NEW.direccion = CONCAT(NEW.direccion, ', Nueva Información');
END;
$$
DELIMITER ;

/* datos*/

INSERT INTO tipoDeCliente (cliente_tipo) VALUES
    ('mayorista'),
    ('minorista');

INSERT INTO tipoDeProducto (tipoDeProducto) VALUES
    ('ProductoDeHogar'),
    ('ProductoComestible');

INSERT INTO nacionalidad (nombre) VALUES
    ('Argentina'),
    ('Brasil');

INSERT INTO informacionDeCliente (idTipoDeCliente, nombre, apellido, dni, direccion, nacionalidad) VALUES
  (1, 'Fabricio', 'Devb', '1234567891', 'Jujuy 478', 1),
  (2, 'NombreCliente2', 'Lettio', '2548930415', 'Insauralde 8900', 2),
  (1, 'Lucía', 'Fernández', '364789512', 'Corrientes 1234', 1),
  (2, 'Andrés', 'Gómez', '784562315', 'Salta 567', 2),
  (1, 'Valeria', 'Rodriguez', '154789635', 'Tucumán 987', 1),
  (2, 'Eduardo', 'Vargas', '320154789', 'Entre Ríos 543', 2),
  (1, 'Florencia', 'Giménez', '985214756', 'Misiones 654', 1),
  (2, 'Carlos', 'Pérez', '214789632', 'Formosa 321', 2),
  (1, 'Micaela', 'Sánchez', '874651237', 'Catamarca 222', 1),
  (2, 'Marcos', 'Ríos', '785214769', 'La Rioja 444', 2);


INSERT INTO cuentaDelCliente (numeroDeCuenta, idInformacionDeCliente)
VALUES
    (123451511, 1),
    (123456782, 2),
    (987654321, 3),  
    (987654322, 4),
    (123456783, 5),  
    (987654323, 6),  
    (123456784, 7),
    (987654324, 8),  
    (123456785, 9),
    (987654325, 10);

INSERT INTO infoDelProducto (idTipoDeProducto, nombreDeMarca, fechaDeEntrada, precio, nacionalidad)
VALUES
    (1, 'Lysoform', '2023-10-08', 400.00, 1),
    (2, 'CocaCola', '2023-10-08', 960.00, 2);

INSERT INTO productosComprados (idCuentaDelCliente, idProducto, cantidad)
VALUES
    (1, 1, 500),
    (2, 2, 10),
    (3, 1, 825),
    (5, 2, 45),
    (4, 2, 2300),
    (6, 1, 4400),
    (7, 2, 20),
    (8, 2, 544),
    (9, 2, 4),
    (10, 2, 182);

    
CREATE OR REPLACE VIEW vistaClientesCuentas AS
SELECT ic.idInformacionDeCliente, ic.nombre, ic.apellido, ic.dni, ic.direccion, ic.nacionalidad, c.numeroDeCuenta
FROM informacionDeCliente ic
JOIN cuentaDelCliente c ON ic.idInformacionDeCliente = c.idInformacionDeCliente;

CREATE OR REPLACE VIEW vistaProductosComprados AS
SELECT pc.idCompra, pc.idCuentaDelCliente, pc.cantidad, i.nombreDeMarca, i.fechaDeEntrada, i.precio
FROM productosComprados pc
JOIN infoDelProducto i ON pc.idProducto = i.idProducto;

CREATE OR REPLACE VIEW vistaClientesCompras AS
SELECT ic.idInformacionDeCliente, ic.nombre, ic.apellido, ic.dni, ic.direccion, ic.nacionalidad, c.numeroDeCuenta, pc.idCompra, pc.cantidad, i.nombreDeMarca, i.fechaDeEntrada, i.precio
FROM informacionDeCliente ic
JOIN cuentaDelCliente c ON ic.idInformacionDeCliente = c.idInformacionDeCliente
LEFT JOIN productosComprados pc ON c.idCuentaDelCliente = pc.idCuentaDelCliente
LEFT JOIN infoDelProducto i ON pc.idProducto = i.idProducto;


CREATE OR REPLACE VIEW vistaPersonalizada AS
SELECT ic.idInformacionDeCliente, ic.nombre, ic.apellido, c.numeroDeCuenta
FROM informacionDeCliente ic
JOIN cuentaDelCliente c ON ic.idInformacionDeCliente = c.idInformacionDeCliente;

CREATE OR REPLACE VIEW vistaTipoDeCliente AS
SELECT tc.cliente_tipo, ic.nombre, ic.apellido, ic.dni
FROM tipoDeCliente tc
JOIN informacionDeCliente ic ON tc.idTipoDeCliente = ic.idTipoDeCliente;




INSERT INTO factura
SELECT DISTINCT
    ic.idInformacionDeCliente AS cliente_id,
    ic.nombre AS cliente_nombre,
    i.idProducto AS producto_id,
    i.nombreDeMarca AS producto_nombre,
    pc.cantidad,
    i.precio AS precio_unitario,
    pc.cantidad * i.precio AS total
FROM
    informacionDeCliente ic
JOIN
    cuentaDelCliente c ON ic.idInformacionDeCliente = c.idInformacionDeCliente
JOIN
    productosComprados pc ON c.idCuentaDelCliente = pc.idCuentaDelCliente
JOIN
    infoDelProducto i ON pc.idProducto = i.idProducto;

/*pruebas xD */

SELECT * FROM cuentaDelCliente;

SELECT * FROM informacionDeCliente;

SELECT* from nacionalidad;

SELECT * FROM infoDelProducto;

SELECT * from productoscomprados;

SELECT * from tipodecliente;

SELECT * from tipodeproducto;

SELECT * FROM cuentaDelCliente WHERE idCuentaDelCliente = 5;

SELECT * FROM infoDelProducto WHERE idProducto = 1;

SELECT * FROM productosComprados;

SELECT pc.idCompra, pc.idCuentaDelCliente, c.numeroDeCuenta, pc.cantidad
FROM productosComprados pc
INNER JOIN cuentaDelCliente c ON pc.idCuentaDelCliente = c.idCuentaDelCliente;

SELECT * FROM vistaClientesCuentas;

SELECT * FROM vistaClientesCompras;

SELECT * FROM vistaProductosComprados;

SELECT * FROM vistaPersonalizada;

SELECT * FROM factura;

SELECT CalcularCostoTotalConNombre(1);

SELECT AumentarPrecioProductos(1);

CALL SP_NombreClienteCantidadYCostoTotalProductos(1, @cliente_nombre, 
@cantidad_productos, @costo_total);

SELECT @cliente_nombre AS ClienteNombre, 
@cantidad_productos AS CantidadProductos, @costo_total AS CostoTotal;

CALL SP_AdministracionDeInventario(1, @tipo_producto, @nombre_marca, 
@fecha_de_entrada, @costo_total, @nacionalidad);

SELECT @tipo_producto AS TipoProducto, @nombre_marca AS NombreMarca, 
@fecha_de_entrada AS FechaEntrada, 
@costo_total AS CostoTotal, @nacionalidad AS Nacionalidad;

UPDATE informacionDeCliente
SET dni = '22222222'
WHERE idInformacionDeCliente = 1;

SELECT dni
FROM informacionDeCliente
WHERE idInformacionDeCliente = 1;

UPDATE informacionDeCliente
SET direccion = 'hibarra 456'
WHERE idInformacionDeCliente = 1;

SELECT direccion
FROM informacionDeCliente
WHERE idInformacionDeCliente = 1;

SELECT	*FROM informaciondecliente;