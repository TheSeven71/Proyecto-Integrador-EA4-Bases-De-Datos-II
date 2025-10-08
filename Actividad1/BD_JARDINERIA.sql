DROP DATABASE IF EXISTS jardineria;
CREATE DATABASE jardineria;
USE jardineria;

CREATE TABLE oficina (
  ID_oficina INT AUTO_INCREMENT,
  Descripcion VARCHAR(10) NOT NULL,
  ciudad VARCHAR(30) NOT NULL,
  pais VARCHAR(50) NOT NULL,
  region VARCHAR(50) DEFAULT NULL,
  codigo_postal VARCHAR(10) NOT NULL,
  telefono VARCHAR(20) NOT NULL,
  linea_direccion1 VARCHAR(50) NOT NULL,
  linea_direccion2 VARCHAR(50) DEFAULT NULL,
  PRIMARY KEY (ID_oficina)
);

CREATE TABLE empleado (
  ID_empleado INT AUTO_INCREMENT NOT NULL,
  nombre VARCHAR(50) NOT NULL,
  apellido1 VARCHAR(50) NOT NULL,
  apellido2 VARCHAR(50) DEFAULT NULL,
  extension VARCHAR(10) NOT NULL,
  email VARCHAR(100) NOT NULL,
  ID_oficina INT NOT NULL,
  ID_jefe INT DEFAULT NULL,
  puesto VARCHAR(50) DEFAULT NULL,
  PRIMARY KEY (ID_empleado),
  FOREIGN KEY (ID_oficina) REFERENCES oficina(ID_oficina),
  FOREIGN KEY (ID_jefe) REFERENCES empleado(ID_empleado)
);

CREATE TABLE Categoria_producto (
  Id_Categoria INT AUTO_INCREMENT,
  Desc_Categoria VARCHAR(50) NOT NULL,
  descripcion_texto TEXT,
  descripcion_html TEXT,
  imagen VARCHAR(256),
  PRIMARY KEY (Id_Categoria)
);

CREATE TABLE cliente (
  ID_cliente INT AUTO_INCREMENT NOT NULL,
  nombre_cliente VARCHAR(50) NOT NULL,
  nombre_contacto VARCHAR(30) DEFAULT NULL,
  apellido_contacto VARCHAR(30) DEFAULT NULL,
  telefono VARCHAR(15) NOT NULL,
  fax VARCHAR(15) NOT NULL,
  linea_direccion1 VARCHAR(50) NOT NULL,
  linea_direccion2 VARCHAR(50) DEFAULT NULL,
  ciudad VARCHAR(50) NOT NULL,
  region VARCHAR(50) DEFAULT NULL,
  pais VARCHAR(50) DEFAULT NULL,
  codigo_postal VARCHAR(10) DEFAULT NULL,
  ID_empleado_rep_ventas INT DEFAULT NULL,
  limite_credito DECIMAL(15,2) DEFAULT NULL,
  PRIMARY KEY (ID_cliente),
  FOREIGN KEY (ID_empleado_rep_ventas) REFERENCES empleado(ID_empleado)
);

CREATE TABLE pedido (
  ID_pedido INT AUTO_INCREMENT NOT NULL,
  fecha_pedido DATE NOT NULL,
  fecha_esperada DATE NOT NULL,
  fecha_entrega DATE DEFAULT NULL,
  estado VARCHAR(15) NOT NULL,
  comentarios TEXT,
  ID_cliente INT NOT NULL,
  PRIMARY KEY (ID_pedido),
  FOREIGN KEY (ID_cliente) REFERENCES cliente(ID_cliente)
);

CREATE TABLE producto (
  ID_producto INT AUTO_INCREMENT NOT NULL,
  CodigoProducto VARCHAR(15) NOT NULL,
  nombre VARCHAR(70) NOT NULL,
  Categoria INT NOT NULL,
  dimensiones VARCHAR(25) NULL,
  proveedor VARCHAR(50) DEFAULT NULL,
  descripcion TEXT NULL,
  cantidad_en_stock SMALLINT NOT NULL,
  precio_venta DECIMAL(15,2) NOT NULL,
  precio_proveedor DECIMAL(15,2) DEFAULT NULL,
  PRIMARY KEY (ID_producto),
  FOREIGN KEY (Categoria) REFERENCES Categoria_producto(Id_Categoria)
);

SELECT * FROM producto;

CREATE TABLE detalle_pedido (
  ID_detalle_pedido INT AUTO_INCREMENT NOT NULL,
  ID_pedido INT NOT NULL,
  ID_producto INT NOT NULL,
  cantidad INT NOT NULL,
  precio_unidad DECIMAL(15,2) NOT NULL,
  numero_linea SMALLINT NOT NULL,
  PRIMARY KEY (ID_detalle_pedido),
  FOREIGN KEY (ID_pedido) REFERENCES pedido(ID_pedido),
  FOREIGN KEY (ID_producto) REFERENCES producto(ID_producto)
);

CREATE TABLE pago (
  ID_pago INT AUTO_INCREMENT NOT NULL,
  ID_cliente INT NOT NULL,
  forma_pago VARCHAR(40) NOT NULL,
  id_transaccion VARCHAR(50) NOT NULL,
  fecha_pago DATE NOT NULL,
  total DECIMAL(15,2) NOT NULL,
  PRIMARY KEY (ID_pago),
  FOREIGN KEY (ID_cliente) REFERENCES cliente(ID_cliente)
);


-- Datos
INSERT INTO oficina (Descripcion, ciudad, pais, region, codigo_postal, telefono, linea_direccion1, linea_direccion2) VALUES
('OF-01','Madrid','España','Madrid','28001','+34 911111111','Calle Sol, 1',NULL),
('OF-02','Barcelona','España','Cataluña','08001','+34 922222222','Calle Luna, 2',NULL),
('OF-03','Valencia','España','Valencia','46001','+34 933333333','Calle Mar, 3',NULL),
('OF-04','Sevilla','España','Andalucía','41001','+34 944444444','Calle Tierra, 4',NULL),
('OF-05','Bilbao','España','País Vasco','48001','+34 955555555','Calle Aire, 5',NULL),
('OF-06','Granada','España','Andalucía','18001','+34 966666666','Calle Fuego, 6',NULL),
('OF-07','Málaga','España','Andalucía','29001','+34 977777777','Calle Agua, 7',NULL),
('OF-08','Zaragoza','España','Aragón','50001','+34 988888888','Calle Nube, 8',NULL),
('OF-09','Valladolid','España','Castilla y León','47001','+34 999999999','Calle Rayo, 9',NULL),
('OF-10','Santander','España','Cantabria','39001','+34 910101010','Calle Estrella, 10',NULL),
('OF-11','Toledo','España','Castilla-La Mancha','45001','+34 920202020','Calle Río, 11',NULL),
('OF-12','Salamanca','España','Castilla y León','37001','+34 930303030','Calle Lago, 12',NULL),
('OF-13','Burgos','España','Castilla y León','09001','+34 940404040','Calle Monte, 13',NULL),
('OF-14','Alicante','España','Valencia','03001','+34 950505050','Calle Valle, 14',NULL),
('OF-15','Córdoba','España','Andalucía','14001','+34 960606060','Calle Camino, 15',NULL),
('OF-16','Gijón','España','Asturias','33201','+34 970707070','Calle Sendero, 16',NULL),
('OF-17','Oviedo','España','Asturias','33001','+34 980808080','Calle Prado, 17',NULL),
('OF-18','San Sebastián','España','País Vasco','20001','+34 990909090','Calle Bosque, 18',NULL),
('OF-19','Pamplona','España','Navarra','31001','+34 911212121','Calle Jardín, 19',NULL),
('OF-20','Logroño','España','La Rioja','26001','+34 922323232','Calle Viña, 20',NULL);

select * from oficina;

DESCRIBE empleado;
-- Ingresos en bloque (sin ID_empleado; Auto Increment genera el valor)  
INSERT INTO empleado (nombre, apellido1, apellido2, extension, email, ID_oficina, ID_jefe, puesto) VALUES
('Juan','Pérez','Gómez','1001','juan.perez@empresa.com',1,NULL,'Director'),
('Ana','Martínez','Sánchez','1002','ana.martinez@empresa.com',2,1,'Gerente'),
('Luis','Rodríguez','López','1003','luis.rodriguez@empresa.com',3,1,'Vendedor'),
('María','García','Fernández','1004','maria.garcia@empresa.com',4,2,'Secretaria'),
('Pedro','Hernández','Ruiz','1005','pedro.hernandez@empresa.com',5,1,'Vendedor'),
('Lucía','Jiménez','Moreno','1006','lucia.jimenez@empresa.com',6,2,'Contable'),
('Carlos','Alonso','Muñoz','1007','carlos.alonso@empresa.com',7,3,'Vendedor'),
('Sofía','Díaz','Romero','1008','sofia.diaz@empresa.com',8,4,'Secretaria'),
('Javier','Torres','Navarro','1009','javier.torres@empresa.com',9,1,'Vendedor'),
('Raquel','Ramos','Domínguez','1010','raquel.ramos@empresa.com',10,5,'Contable'),
('Miguel','Gutiérrez','Gil','1011','miguel.gutierrez@empresa.com',11,6,'Director'),
('Patricia','Castro','Serrano','1012','patricia.castro@empresa.com',12,7,'Gerente'),
('José','Molina','Blanco','1013','jose.molina@empresa.com',13,8,'Vendedor'),
('Sandra','Ortega','Garrido','1014','sandra.ortega@empresa.com',14,9,'Secretaria'),
('Alberto','Vega','Flores','1015','alberto.vega@empresa.com',15,10,'Vendedor'),
('Elena','Suárez','Medina','1016','elena.suarez@empresa.com',16,11,'Contable'),
('Francisco','Cruz','Aguilar','1017','francisco.cruz@empresa.com',17,12,'Vendedor'),
('Marta','Reyes','Castillo','1018','marta.reyes@empresa.com',18,13,'Secretaria'),
('David','Santos','Herrera','1019','david.santos@empresa.com',19,14,'Vendedor'),
('Beatriz','Ortega','Delgado','1020','beatriz.ortega@empresa.com',20,15,'Gerente');

INSERT INTO Categoria_producto (Desc_Categoria, descripcion_texto, descripcion_html, imagen) VALUES
('Herramientas','Herramientas para el jardín',NULL,NULL),
('Plantas','Plantas ornamentales',NULL,NULL),
('Árboles','Árboles frutales',NULL,NULL),
('Flores','Flores de temporada',NULL,NULL),
('Abonos','Abonos y fertilizantes',NULL,NULL),
('Macetas','Macetas de diversos tamaños',NULL,NULL),
('Riego','Sistemas de riego',NULL,NULL),
('Decoración','Elementos decorativos',NULL,NULL),
('Césped','Césped natural y artificial',NULL,NULL),
('Semillas','Semillas variadas',NULL,NULL),
('Sustratos','Sustratos para plantas',NULL,NULL),
('Pesticidas','Pesticidas y fungicidas',NULL,NULL),
('Muebles','Muebles de jardín',NULL,NULL),
('Iluminación','Iluminación exterior',NULL,NULL),
('Herr. Eléctricas','Herramientas eléctricas',NULL,NULL),
('Plantas exóticas','Plantas exóticas',NULL,NULL),
('Arbustos','Arbustos',NULL,NULL),
('Paisajismo','Servicios de paisajismo',NULL,NULL),
('Compost','Compost y reciclaje',NULL,NULL),
('Automatización','Sistemas automáticos',NULL,NULL);
 
 INSERT INTO cliente (nombre_cliente, nombre_contacto, apellido_contacto, telefono, fax, linea_direccion1, linea_direccion2, ciudad, region, pais, codigo_postal, ID_empleado_rep_ventas, limite_credito) VALUES
('Jardines SL','Laura','López','600000001','600000002','Calle Flor, 1',NULL,'Madrid','Madrid','España','28001',1,5000),
('Verde S.A.','Carlos','Ruiz','600000003','600000004','Calle Hoja, 2',NULL,'Barcelona','Cataluña','España','08001',2,7000),
('Flores y Más','Ana','Pérez','600000005','600000006','Calle Pétalo, 3',NULL,'Valencia','Valencia','España','46001',3,4000),
('Hogar Verde','Miguel','Santos','600000007','600000008','Calle Jardín, 4',NULL,'Sevilla','Andalucía','España','41001',4,9000),
('Campo Bello','Sofía','Martínez','600000009','600000010','Calle Césped, 5',NULL,'Bilbao','País Vasco','España','48001',5,3000),
('Mundo Planta','María','Gómez','600000011','600000012','Calle Maceta, 6',NULL,'Granada','Andalucía','España','18001',6,6000),
('Naturaleza','Pedro','Jiménez','600000013','600000014','Calle Riego, 7',NULL,'Málaga','Andalucía','España','29001',7,8000),
('Verde Hogar','Lucía','Alonso','600000015','600000016','Calle Sustrato, 8',NULL,'Zaragoza','Aragón','España','50001',8,2000),
('Jardín Real','Javier','Torres','600000017','600000018','Calle Bosque, 9',NULL,'Valladolid','Castilla y León','España','47001',9,10000),
('Plantas y Vida','Raquel','Ramos','600000019','600000020','Calle Estrella, 10',NULL,'Santander','Cantabria','España','39001',10,12000),
('Green World','Miguel','Gutiérrez','600000021','600000022','Calle Río, 11',NULL,'Toledo','Castilla-La Mancha','España','45001',11,9000),
('Natur Plant','Patricia','Castro','600000023','600000024','Calle Lago, 12',NULL,'Salamanca','Castilla y León','España','37001',12,4000),
('Jardines Urbanos','José','Molina','600000025','600000026','Calle Monte, 13',NULL,'Burgos','Castilla y León','España','09001',13,8000),
('Paisaje S.A.','Sandra','Ortega','600000027','600000028','Calle Valle, 14',NULL,'Alicante','Valencia','España','03001',14,3000),
('Planta y Flor','Alberto','Vega','600000029','600000030','Calle Camino, 15',NULL,'Córdoba','Andalucía','España','14001',15,5000),
('Ambiente Verde','Elena','Suárez','600000031','600000032','Calle Sendero, 16',NULL,'Gijón','Asturias','España','33201',16,7000),
('Verde Jardín','Francisco','Cruz','600000033','600000034','Calle Prado, 17',NULL,'Oviedo','Asturias','España','33001',17,11000),
('Jardinería Total','Marta','Reyes','600000035','600000036','Calle Bosque, 18',NULL,'San Sebastián','País Vasco','España','20001',18,15000),
('EcoJardín','David','Santos','600000037','600000038','Calle Jardín, 19',NULL,'Pamplona','Navarra','España','31001',19,6000),
('PlantaFácil','Beatriz','Ortega','600000039','600000040','Calle Viña, 20',NULL,'Logroño','La Rioja','España','26001',20,7000);

INSERT INTO pedido (fecha_pedido, fecha_esperada, fecha_entrega, estado, comentarios, ID_cliente) VALUES
('2025-08-01','2025-08-05','2025-08-05','Entregado','Todo correcto',1),
('2025-08-02','2025-08-06',NULL,'Pendiente','Falta pago',2),
('2025-08-03','2025-08-07','2025-08-08','Entregado','Entrega en tarde',3),
('2025-08-04','2025-08-09',NULL,'Pendiente','Cliente solicita cambio de fecha',4),
('2025-08-05','2025-08-10','2025-08-12','Entregado','Revisión satisfactoria',5),
('2025-08-06','2025-08-11',NULL,'Pendiente','Se espera confirmación',6),
('2025-08-07','2025-08-12','2025-08-12','Entregado','Entrega anticipada',7),
('2025-08-08','2025-08-13',NULL,'Pendiente','Cliente solicita horario especial',8),
('2025-08-09','2025-08-14','2025-08-15','Entregado','Entrega correcta',9),
('2025-08-10','2025-08-15',NULL,'Pendiente','Pendiente de pago',10),
('2025-08-11','2025-08-16','2025-08-17','Entregado','Cliente satisfecho',11),
('2025-08-12','2025-08-17',NULL,'Pendiente','Esperando proveedor',12),
('2025-08-13','2025-08-18','2025-08-19','Entregado','Producto en buen estado',13),
('2025-08-14','2025-08-19',NULL,'Pendiente','Cliente solicita descuento',14),
('2025-08-15','2025-08-20','2025-08-21','Entregado','Entrega parcial',15),
('2025-08-16','2025-08-21',NULL,'Pendiente','Pendiente revisión',16),
('2025-08-17','2025-08-22','2025-08-23','Entregado','Todo entregado',17),
('2025-08-18','2025-08-23',NULL,'Pendiente','Falta producto',18),
('2025-08-19','2025-08-24','2025-08-25','Entregado','Entrega completa',19),
('2025-08-20','2025-08-25',NULL,'Pendiente','Cliente ausente',20);

INSERT INTO producto (CodigoProducto, nombre, Categoria, dimensiones, proveedor, descripcion, cantidad_en_stock, precio_venta, precio_proveedor) VALUES
('PRD-0001','Tijeras de podar',1,'20cm','Herramientas SL','Tijeras para podar plantas',100,15,10),
('PRD-0002','Maceta grande',6,'40cm','Macetas SA','Maceta de plástico grande',200,8,5),
('PRD-0003','Césped artificial',9,'5m2','Green World','Césped sintético',50,50,40),
('PRD-0004','Riego automático',7,'10m','Riego SL','Kit de riego automático',30,90,70),
('PRD-0005','Abono universal',5,'5kg','Abonos SA','Abono para todo tipo de plantas',80,12,9),
('PRD-0006','Flor de temporada',4,'30cm','Flores SL','Flor decorativa',150,7,5),
('PRD-0007','Sustrato premium',11,'20L','Naturaleza','Sustrato de alta calidad',60,20,15),
('PRD-0008','Mesa jardín',13,'120x70cm','Muebles SA','Mesa exterior',20,120,90),
('PRD-0009','Lámpara solar',14,'25cm','Ilumina SL','Lámpara de jardín solar',40,33,25),
('PRD-0010','Compost orgánico',19,'10kg','Compost SA','Compost ecológico',70,16,12),
('PRD-0011','Arbusto decorativo',17,'60cm','Plantas SA','Arbusto ornamental',30,22,16),
('PRD-0012','Pesticida natural',12,'500ml','Bio SL','Pesticida ecológico',120,11,8),
('PRD-0013','Banco jardín',13,'150x40cm','Muebles SA','Banco de madera',10,110,80),
('PRD-0014','Maceta pequeña',6,'15cm','Macetas SA','Maceta de cerámica',300,4,2),
('PRD-0015','Iluminación LED',14,'10m','Ilumina SL','Tira LED jardín',25,40,30),
('PRD-0016','Árbol frutal',3,'1.5m','Árboles SA','Manzano joven',15,35,25),
('PRD-0017','Planta exótica',16,'50cm','Plantas Exóticas','Planta tropical',18,28,22),
('PRD-0018','Semillas césped',10,'500g','Semillas SL','Semillas césped rápido',90,6,4),
('PRD-0019','Fertilizante líquido',5,'1L','Abonos SA','Fertilizante rápido',100,9,6),
('PRD-0020','Silla jardín',13,'45x45cm','Muebles SA','Silla exterior',30,35,25);

INSERT INTO detalle_pedido (ID_pedido, ID_producto, cantidad, precio_unidad, numero_linea) VALUES
(1,1,10,15,1),
(1,2,5,8,2),
(2,3,2,50,1),
(2,4,1,90,2),
(3,5,8,12,1),
(3,6,12,7,2),
(4,7,3,20,1),
(4,8,1,120,2),
(5,9,5,33,1),
(5,10,3,16,2),
(6,11,2,22,1),
(6,12,6,11,2),
(7,13,1,110,1),
(7,14,15,4,2),
(8,15,2,40,1),
(8,16,1,35,2),
(9,17,3,28,1),
(9,18,20,6,2),
(10,19,10,9,1),
(10,20,2,35,2);


INSERT INTO pago (ID_cliente, forma_pago, id_transaccion, fecha_pago, total) VALUES
(1,'Tarjeta','TX-0001','2025-08-10',150),
(2,'Transferencia','TX-0002','2025-08-12',200),
(3,'Efectivo','TX-0003','2025-08-15',300),
(4,'Tarjeta','TX-0004','2025-08-18',170),
(5,'Transferencia','TX-0005','2025-08-20',250),
(6,'Efectivo','TX-0006','2025-08-22',180),
(7,'Tarjeta','TX-0007','2025-08-24',210),
(8,'Transferencia','TX-0008','2025-08-26',260),
(9,'Efectivo','TX-0009','2025-08-28',190),
(10,'Tarjeta','TX-0010','2025-08-30',300),
(11,'Transferencia','TX-0011','2025-09-01',350),
(12,'Efectivo','TX-0012','2025-09-02',400),
(13,'Tarjeta','TX-0013','2025-09-03',220),
(14,'Transferencia','TX-0014','2025-09-04',210),
(15,'Efectivo','TX-0015','2025-09-05',120),
(16,'Tarjeta','TX-0016','2025-09-06',450),
(17,'Transferencia','TX-0017','2025-09-07',370),
(18,'Efectivo','TX-0018','2025-09-08',330),
(19,'Tarjeta','TX-0019','2025-09-09',250),
(20,'Transferencia','TX-0020','2025-09-10',270);