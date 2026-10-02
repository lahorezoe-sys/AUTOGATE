-- MariaDB dump 10.19  Distrib 10.4.32-MariaDB, for Win64 (AMD64)
--
-- Host: localhost    Database: autogate
-- ------------------------------------------------------
-- Server version	10.4.32-MariaDB

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `alertas`
--

DROP TABLE IF EXISTS `alertas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `alertas` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `evento_acceso_id` int(10) unsigned DEFAULT NULL,
  `dispositivo_id` int(10) unsigned DEFAULT NULL,
  `porton_id` int(10) unsigned DEFAULT NULL,
  `tipo` enum('intento_no_autorizado','dispositivo_fuera_de_linea','error_sensor','error_porton','timeout_acceso','advertencia_sistema') NOT NULL,
  `severidad` enum('baja','media','alta','critica') NOT NULL DEFAULT 'media',
  `titulo` varchar(120) NOT NULL,
  `mensaje` varchar(255) NOT NULL,
  `reconocida` tinyint(1) NOT NULL DEFAULT 0,
  `reconocida_por` int(10) unsigned DEFAULT NULL,
  `reconocida_en` datetime DEFAULT NULL,
  `resuelta_en` datetime DEFAULT NULL,
  `creado_en` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_alertas_evento` (`evento_acceso_id`),
  KEY `idx_alertas_dispositivo` (`dispositivo_id`),
  KEY `idx_alertas_porton` (`porton_id`),
  KEY `idx_alertas_tipo` (`tipo`),
  KEY `idx_alertas_severidad` (`severidad`),
  KEY `idx_alertas_reconocida` (`reconocida`),
  KEY `fk_alertas_usuarios` (`reconocida_por`),
  CONSTRAINT `fk_alertas_dispositivos` FOREIGN KEY (`dispositivo_id`) REFERENCES `dispositivos_iot` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_alertas_eventos` FOREIGN KEY (`evento_acceso_id`) REFERENCES `eventos_acceso` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_alertas_portones` FOREIGN KEY (`porton_id`) REFERENCES `portones` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_alertas_usuarios` FOREIGN KEY (`reconocida_por`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `alertas`
--

LOCK TABLES `alertas` WRITE;
/*!40000 ALTER TABLE `alertas` DISABLE KEYS */;
/*!40000 ALTER TABLE `alertas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `ci_sessions`
--

DROP TABLE IF EXISTS `ci_sessions`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `ci_sessions` (
  `id` varchar(128) NOT NULL,
  `ip_address` varchar(45) NOT NULL,
  `timestamp` int(10) unsigned NOT NULL DEFAULT 0,
  `data` blob NOT NULL,
  PRIMARY KEY (`id`),
  KEY `ci_sessions_timestamp` (`timestamp`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `ci_sessions`
--

LOCK TABLES `ci_sessions` WRITE;
/*!40000 ALTER TABLE `ci_sessions` DISABLE KEYS */;
/*!40000 ALTER TABLE `ci_sessions` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `configuraciones_sistema`
--

DROP TABLE IF EXISTS `configuraciones_sistema`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `configuraciones_sistema` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `clave` varchar(80) NOT NULL,
  `valor` text NOT NULL,
  `tipo_valor` varchar(20) NOT NULL DEFAULT 'string',
  `descripcion` varchar(255) DEFAULT NULL,
  `actualizado_por` int(10) unsigned DEFAULT NULL,
  `actualizado_en` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_config_clave` (`clave`),
  KEY `idx_config_actualizado_por` (`actualizado_por`),
  CONSTRAINT `fk_config_usuarios` FOREIGN KEY (`actualizado_por`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `configuraciones_sistema`
--

LOCK TABLES `configuraciones_sistema` WRITE;
/*!40000 ALTER TABLE `configuraciones_sistema` DISABLE KEYS */;
/*!40000 ALTER TABLE `configuraciones_sistema` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `dispositivos_iot`
--

DROP TABLE IF EXISTS `dispositivos_iot`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `dispositivos_iot` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `producto_id` int(10) unsigned NOT NULL COMMENT 'Referencia al producto autorizado',
  `vinculacion_id` int(10) unsigned NOT NULL COMMENT 'Vinculaci??n activa',
  `empresa_id` int(10) unsigned NOT NULL,
  `porton_id` int(10) unsigned DEFAULT NULL COMMENT 'NULL hasta asignarse a un port??n',
  `nombre` varchar(80) NOT NULL,
  `tipo_dispositivo` enum('esp32','controlador_acceso','otro') NOT NULL DEFAULT 'esp32',
  `direccion` enum('entrada','salida','ambas') NOT NULL DEFAULT 'ambas',
  `mac` varchar(32) NOT NULL COMMENT 'MAC address del ESP32',
  `ip` varchar(45) DEFAULT NULL,
  `version_firmware` varchar(30) DEFAULT NULL,
  `estado` enum('en_linea','fuera_de_linea','mantenimiento') NOT NULL DEFAULT 'fuera_de_linea',
  `ultimo_visto` datetime DEFAULT NULL,
  `api_key_hash` varchar(255) DEFAULT NULL,
  `creado_en` datetime NOT NULL DEFAULT current_timestamp(),
  `actualizado_en` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_dispositivos_mac` (`mac`),
  KEY `idx_dispositivos_porton` (`porton_id`),
  KEY `idx_dispositivos_tipo` (`tipo_dispositivo`),
  KEY `idx_dispositivos_estado` (`estado`),
  KEY `idx_dispositivos_producto` (`producto_id`),
  KEY `idx_dispositivos_vinculacion` (`vinculacion_id`),
  KEY `idx_dispositivos_empresa` (`empresa_id`),
  CONSTRAINT `fk_dispositivos_empresas` FOREIGN KEY (`empresa_id`) REFERENCES `empresas` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_dispositivos_portones` FOREIGN KEY (`porton_id`) REFERENCES `portones` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_dispositivos_productos` FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_dispositivos_vinculaciones` FOREIGN KEY (`vinculacion_id`) REFERENCES `vinculaciones_producto` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `dispositivos_iot`
--

LOCK TABLES `dispositivos_iot` WRITE;
/*!40000 ALTER TABLE `dispositivos_iot` DISABLE KEYS */;
INSERT INTO `dispositivos_iot` VALUES (2,1,2,2,2,'aaaaa','esp32','entrada','AA:BB:CC:11:22:33','::1',NULL,'en_linea','2026-09-04 09:50:04',NULL,'2026-08-25 12:51:16','2026-09-04 09:50:04'),(3,2,3,2,NULL,'qwqeweq','esp32','','10:20:30:40:50:60',NULL,NULL,'en_linea',NULL,NULL,'2026-08-26 10:33:40','2026-09-08 11:11:34'),(4,10,4,2,2,'ESP32 Principal - Entrada','esp32','entrada','8C:94:DF:8E:02:CC','192.168.0.223','v2.0-slave','en_linea','2026-09-28 11:43:22',NULL,'2026-09-04 10:04:09','2026-09-28 11:43:22'),(5,11,5,2,2,'ESP32 Main - Porton Buzzer','esp32','entrada','88:57:21:2F:12:68','192.168.0.169','v2.0-main-dual-pn532','en_linea','2026-09-28 11:43:05',NULL,'2026-09-09 22:08:43','2026-09-28 11:43:05');
/*!40000 ALTER TABLE `dispositivos_iot` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `empresas`
--

DROP TABLE IF EXISTS `empresas`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `empresas` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `codigo_empresa` varchar(50) NOT NULL,
  `nombre_empresa` varchar(150) NOT NULL,
  `configuracion_json` longtext DEFAULT NULL,
  `max_dispositivos` int(10) unsigned NOT NULL DEFAULT 5 COMMENT 'L??mite de ESP32 que puede vincular la empresa',
  `contacto_email` varchar(120) DEFAULT NULL,
  `contacto_telefono` varchar(30) DEFAULT NULL,
  `estado` enum('activo','inactivo') NOT NULL DEFAULT 'activo',
  `creado_en` datetime NOT NULL DEFAULT current_timestamp(),
  `actualizado_en` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_empresas_codigo` (`codigo_empresa`)
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `empresas`
--

LOCK TABLES `empresas` WRITE;
/*!40000 ALTER TABLE `empresas` DISABLE KEYS */;
INSERT INTO `empresas` VALUES (2,'CUENTADEFACU-38D8E3','Cuenta de facundo llorens',NULL,5,NULL,NULL,'activo','2026-08-25 12:39:31','2026-08-25 12:39:31');
/*!40000 ALTER TABLE `empresas` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `eventos_acceso`
--

DROP TABLE IF EXISTS `eventos_acceso`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `eventos_acceso` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `empresa_id` int(10) unsigned NOT NULL COMMENT 'Aislamiento multi-tenant para queries directas',
  `porton_id` int(10) unsigned DEFAULT NULL COMMENT 'NULL si el dispositivo a??n no tiene port??n asignado',
  `dispositivo_id` int(10) unsigned DEFAULT NULL COMMENT 'NULL si el dispositivo operativo fue eliminado pero se guarda el hist??rico',
  `tarjeta_id` int(10) unsigned DEFAULT NULL,
  `usuario_id` int(10) unsigned DEFAULT NULL,
  `uid_leido` varchar(32) NOT NULL,
  `direccion` enum('entrada','salida') NOT NULL DEFAULT 'entrada',
  `resultado` enum('permitido','denegado') NOT NULL,
  `motivo` enum('tarjeta_autorizada','tarjeta_no_registrada','tarjeta_inactiva','tarjeta_suspendida','usuario_inactivo','acceso_denegado_por_regla','timeout_sensor','error_dispositivo','desconocido') NOT NULL DEFAULT 'desconocido',
  `detectado_en` datetime NOT NULL DEFAULT current_timestamp(),
  `respondido_en` datetime DEFAULT NULL,
  `porton_abierto_en` datetime DEFAULT NULL,
  `vehiculo_detectado_en` datetime DEFAULT NULL,
  `porton_cerrado_en` datetime DEFAULT NULL,
  `mensaje_respuesta` varchar(255) DEFAULT NULL,
  `creado_en` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_eventos_empresa` (`empresa_id`),
  KEY `idx_eventos_porton` (`porton_id`),
  KEY `idx_eventos_dispositivo` (`dispositivo_id`),
  KEY `idx_eventos_tarjeta` (`tarjeta_id`),
  KEY `idx_eventos_usuario` (`usuario_id`),
  KEY `idx_eventos_empresa_fecha` (`empresa_id`,`detectado_en`),
  KEY `idx_eventos_porton_fecha` (`porton_id`,`detectado_en`),
  KEY `idx_eventos_uid_fecha` (`uid_leido`,`detectado_en`),
  CONSTRAINT `fk_eventos_dispositivos` FOREIGN KEY (`dispositivo_id`) REFERENCES `dispositivos_iot` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_eventos_empresas` FOREIGN KEY (`empresa_id`) REFERENCES `empresas` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_eventos_portones` FOREIGN KEY (`porton_id`) REFERENCES `portones` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_eventos_tarjetas` FOREIGN KEY (`tarjeta_id`) REFERENCES `tarjetas_rfid` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_eventos_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=115 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `eventos_acceso`
--

LOCK TABLES `eventos_acceso` WRITE;
/*!40000 ALTER TABLE `eventos_acceso` DISABLE KEYS */;
INSERT INTO `eventos_acceso` VALUES (2,2,2,2,2,2,'SIM-B67F9878','entrada','permitido','tarjeta_autorizada','2026-08-25 13:02:33','2026-08-25 13:02:33','2026-08-25 13:02:33',NULL,NULL,'Ingreso aceptado por simulacion.','2026-08-25 13:02:33'),(3,2,2,2,2,2,'SIM-B67F9878','entrada','permitido','tarjeta_autorizada','2026-09-04 09:50:04','2026-09-04 09:50:04','2026-09-04 09:50:04',NULL,NULL,'Acceso permitido para facundo llorens.','2026-09-04 09:50:04'),(4,2,2,4,2,2,'SIM-B67F9878','entrada','permitido','tarjeta_autorizada','2026-09-04 10:04:09','2026-09-04 10:04:09','2026-09-04 10:04:09',NULL,NULL,'Acceso permitido para facundo llorens.','2026-09-04 10:04:09'),(5,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-08 09:47:57','2026-09-08 09:47:57',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-08 09:47:57'),(6,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-08 11:05:12','2026-09-08 11:05:12',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-08 11:05:12'),(7,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-08 11:05:22','2026-09-08 11:05:22',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-08 11:05:22'),(8,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-08 11:05:24','2026-09-08 11:05:24',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-08 11:05:24'),(9,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-08 11:08:11','2026-09-08 11:08:11',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-08 11:08:11'),(10,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-08 11:09:54','2026-09-08 11:09:54',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-08 11:09:54'),(11,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-08 11:09:56','2026-09-08 11:09:56',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-08 11:09:56'),(12,2,2,4,NULL,NULL,'8C2FCD04','entrada','denegado','tarjeta_no_registrada','2026-09-08 11:12:08','2026-09-08 11:12:08',NULL,NULL,NULL,'Acceso denegado: UID desconocida (8C2FCD04)','2026-09-08 11:12:08'),(13,2,2,4,NULL,NULL,'8C2FCD04','entrada','denegado','tarjeta_no_registrada','2026-09-08 11:13:37','2026-09-08 11:13:37',NULL,NULL,NULL,'Acceso denegado: UID desconocida (8C2FCD04)','2026-09-08 11:13:37'),(14,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-08 11:13:59','2026-09-08 11:13:59','2026-09-08 11:13:59',NULL,NULL,'Acceso permitido para victor.','2026-09-08 11:13:59'),(15,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-08 11:26:15','2026-09-08 11:26:15','2026-09-08 11:26:15',NULL,NULL,'Acceso permitido para victor.','2026-09-08 11:26:15'),(16,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-08 11:26:23','2026-09-08 11:26:23',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-08 11:26:23'),(17,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-08 11:26:31','2026-09-08 11:26:31',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-08 11:26:31'),(18,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-08 11:26:34','2026-09-08 11:26:34',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-08 11:26:34'),(19,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-08 11:26:41','2026-09-08 11:26:41','2026-09-08 11:26:41',NULL,NULL,'Acceso permitido para victor.','2026-09-08 11:26:41'),(20,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-08 11:26:51','2026-09-08 11:26:51',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-08 11:26:51'),(21,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-08 11:26:53','2026-09-08 11:26:53',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-08 11:26:53'),(22,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-08 11:27:02','2026-09-08 11:27:02',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-08 11:27:02'),(23,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-08 11:27:26','2026-09-08 11:27:26',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-08 11:27:26'),(24,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-08 11:27:29','2026-09-08 11:27:29',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-08 11:27:29'),(25,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-08 11:27:39','2026-09-08 11:27:39',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-08 11:27:39'),(26,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-08 11:29:26','2026-09-08 11:29:26','2026-09-08 11:29:26',NULL,NULL,'Acceso permitido para victor.','2026-09-08 11:29:26'),(27,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-08 11:29:36','2026-09-08 11:29:36',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-08 11:29:36'),(28,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-08 11:29:46','2026-09-08 11:29:46','2026-09-08 11:29:46',NULL,NULL,'Acceso permitido para victor.','2026-09-08 11:29:46'),(29,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-08 11:29:53','2026-09-08 11:29:53','2026-09-08 11:29:53',NULL,NULL,'Acceso permitido para victor.','2026-09-08 11:29:53'),(30,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-08 11:30:01','2026-09-08 11:30:01',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-08 11:30:01'),(31,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-08 11:30:14','2026-09-08 11:30:14','2026-09-08 11:30:14',NULL,NULL,'Acceso permitido para victor.','2026-09-08 11:30:14'),(32,2,2,4,NULL,NULL,'12345678','entrada','denegado','tarjeta_no_registrada','2026-09-09 20:44:58','2026-09-09 20:44:58',NULL,NULL,NULL,'Acceso denegado: UID desconocida (12345678)','2026-09-09 20:44:58'),(33,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-09 20:46:25','2026-09-09 20:46:25',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-09 20:46:25'),(34,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-09 20:46:29','2026-09-09 20:46:29','2026-09-09 20:46:29',NULL,NULL,'Acceso permitido para victor.','2026-09-09 20:46:29'),(35,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-09 21:01:31','2026-09-09 21:01:31','2026-09-09 21:01:31',NULL,NULL,'Acceso permitido para victor.','2026-09-09 21:01:31'),(36,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-09 21:08:27','2026-09-09 21:08:27','2026-09-09 21:08:27',NULL,NULL,'Acceso permitido para victor.','2026-09-09 21:08:27'),(37,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-09 21:08:43','2026-09-09 21:08:43',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-09 21:08:43'),(38,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-09 21:08:49','2026-09-09 21:08:49','2026-09-09 21:08:49',NULL,NULL,'Acceso permitido para victor.','2026-09-09 21:08:49'),(39,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-09 21:43:21','2026-09-09 21:43:21',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-09 21:43:21'),(40,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-09 21:47:14','2026-09-09 21:47:14',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-09 21:47:14'),(41,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-09 21:47:17','2026-09-09 21:47:17',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-09 21:47:17'),(42,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-09 21:47:19','2026-09-09 21:47:19','2026-09-09 21:47:19',NULL,NULL,'Acceso permitido para victor.','2026-09-09 21:47:19'),(43,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-09 22:15:48','2026-09-09 22:15:48',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-09 22:15:48'),(44,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-09 22:15:51','2026-09-09 22:15:51',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-09 22:15:51'),(45,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-09 22:15:54','2026-09-09 22:15:54',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-09 22:15:54'),(46,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-09 22:15:56','2026-09-09 22:15:56',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-09 22:15:56'),(47,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-09 22:16:00','2026-09-09 22:16:00','2026-09-09 22:16:00',NULL,NULL,'Acceso permitido para victor.','2026-09-09 22:16:00'),(48,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-09 22:16:18','2026-09-09 22:16:18','2026-09-09 22:16:18',NULL,NULL,'Acceso permitido para victor.','2026-09-09 22:16:18'),(49,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-09 22:16:27','2026-09-09 22:16:27','2026-09-09 22:16:27',NULL,NULL,'Acceso permitido para victor.','2026-09-09 22:16:27'),(50,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-09 22:16:47','2026-09-09 22:16:47','2026-09-09 22:16:47',NULL,NULL,'Acceso permitido para victor.','2026-09-09 22:16:47'),(51,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-09 22:17:00','2026-09-09 22:17:00','2026-09-09 22:17:00',NULL,NULL,'Acceso permitido para victor.','2026-09-09 22:17:00'),(52,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-09 22:17:12','2026-09-09 22:17:12',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-09 22:17:12'),(53,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-09 22:18:22','2026-09-09 22:18:22',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-09 22:18:22'),(54,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-09 22:18:25','2026-09-09 22:18:25',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-09 22:18:25'),(55,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-09 22:18:28','2026-09-09 22:18:28','2026-09-09 22:18:28',NULL,NULL,'Acceso permitido para victor.','2026-09-09 22:18:28'),(56,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-09 22:34:01','2026-09-09 22:34:01',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-09 22:34:01'),(57,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-09 22:34:03','2026-09-09 22:34:03',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-09 22:34:03'),(58,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-09 22:34:05','2026-09-09 22:34:05',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-09 22:34:05'),(59,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-09 22:34:08','2026-09-09 22:34:08',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-09 22:34:08'),(60,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-09 22:34:10','2026-09-09 22:34:10',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-09 22:34:10'),(61,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-09 22:34:23','2026-09-09 22:34:23',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-09 22:34:23'),(62,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-09 22:34:26','2026-09-09 22:34:26',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-09 22:34:26'),(63,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-09 22:34:30','2026-09-09 22:34:30','2026-09-09 22:34:30',NULL,NULL,'Acceso permitido para victor.','2026-09-09 22:34:30'),(64,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-09 22:34:37','2026-09-09 22:34:37','2026-09-09 22:34:37',NULL,NULL,'Acceso permitido para victor.','2026-09-09 22:34:37'),(65,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-09 22:34:43','2026-09-09 22:34:43','2026-09-09 22:34:43',NULL,NULL,'Acceso permitido para victor.','2026-09-09 22:34:43'),(66,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-09 22:34:50','2026-09-09 22:34:50','2026-09-09 22:34:50',NULL,NULL,'Acceso permitido para victor.','2026-09-09 22:34:50'),(67,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-09 22:35:12','2026-09-09 22:35:12','2026-09-09 22:35:12',NULL,NULL,'Acceso permitido para victor.','2026-09-09 22:35:12'),(68,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-09 22:35:53','2026-09-09 22:35:53','2026-09-09 22:35:53',NULL,NULL,'Acceso permitido para victor.','2026-09-09 22:35:53'),(69,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-09 22:36:05','2026-09-09 22:36:05','2026-09-09 22:36:05',NULL,NULL,'Acceso permitido para victor.','2026-09-09 22:36:05'),(70,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-09 22:36:25','2026-09-09 22:36:25','2026-09-09 22:36:25',NULL,NULL,'Acceso permitido para victor.','2026-09-09 22:36:25'),(71,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-09 22:36:36','2026-09-09 22:36:36','2026-09-09 22:36:36',NULL,NULL,'Acceso permitido para victor.','2026-09-09 22:36:36'),(72,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-09 22:36:44','2026-09-09 22:36:44','2026-09-09 22:36:44',NULL,NULL,'Acceso permitido para victor.','2026-09-09 22:36:44'),(73,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-09 22:36:50','2026-09-09 22:36:50',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-09 22:36:50'),(74,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-09 22:38:33','2026-09-09 22:38:33','2026-09-09 22:38:33',NULL,NULL,'Acceso permitido para victor.','2026-09-09 22:38:33'),(75,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-09 22:38:46','2026-09-09 22:38:46',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-09 22:38:46'),(76,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-14 19:36:43','2026-09-14 19:36:43',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-14 19:36:43'),(77,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-14 19:36:47','2026-09-14 19:36:47','2026-09-14 19:36:47',NULL,NULL,'Acceso permitido para victor.','2026-09-14 19:36:47'),(78,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-14 19:43:20','2026-09-14 19:43:20','2026-09-14 19:43:20',NULL,NULL,'Acceso permitido para victor.','2026-09-14 19:43:20'),(79,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-14 19:43:46','2026-09-14 19:43:46','2026-09-14 19:43:46',NULL,NULL,'Acceso permitido para victor.','2026-09-14 19:43:46'),(80,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-14 19:43:55','2026-09-14 19:43:55','2026-09-14 19:43:55',NULL,NULL,'Acceso permitido para victor.','2026-09-14 19:43:55'),(81,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-14 19:44:11','2026-09-14 19:44:11','2026-09-14 19:44:11',NULL,NULL,'Acceso permitido para victor.','2026-09-14 19:44:11'),(82,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-14 19:44:53','2026-09-14 19:44:53','2026-09-14 19:44:53',NULL,NULL,'Acceso permitido para victor.','2026-09-14 19:44:53'),(83,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-14 19:45:44','2026-09-14 19:45:44','2026-09-14 19:45:44',NULL,NULL,'Acceso permitido para victor.','2026-09-14 19:45:44'),(84,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-14 19:45:50','2026-09-14 19:45:50','2026-09-14 19:45:50',NULL,NULL,'Acceso permitido para victor.','2026-09-14 19:45:50'),(85,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-14 19:48:57','2026-09-14 19:48:57','2026-09-14 19:48:57',NULL,NULL,'Acceso permitido para victor.','2026-09-14 19:48:57'),(86,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-14 19:49:43','2026-09-14 19:49:43','2026-09-14 19:49:43',NULL,NULL,'Acceso permitido para victor.','2026-09-14 19:49:43'),(87,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-14 19:50:42','2026-09-14 19:50:42','2026-09-14 19:50:42',NULL,NULL,'Acceso permitido para victor.','2026-09-14 19:50:42'),(88,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-14 19:50:59','2026-09-14 19:50:59',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-14 19:50:59'),(89,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-14 19:51:06','2026-09-14 19:51:06','2026-09-14 19:51:06',NULL,NULL,'Acceso permitido para victor.','2026-09-14 19:51:06'),(90,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-14 19:53:13','2026-09-14 19:53:13','2026-09-14 19:53:13',NULL,NULL,'Acceso permitido para victor.','2026-09-14 19:53:13'),(91,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-14 19:53:21','2026-09-14 19:53:21',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-14 19:53:21'),(92,2,2,4,NULL,NULL,'222BCD04','entrada','denegado','tarjeta_no_registrada','2026-09-14 19:53:24','2026-09-14 19:53:24',NULL,NULL,NULL,'Acceso denegado: UID desconocida (222BCD04)','2026-09-14 19:53:24'),(93,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-14 20:08:13','2026-09-14 20:08:13','2026-09-14 20:08:13',NULL,NULL,'Acceso permitido para victor.','2026-09-14 20:08:13'),(94,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-15 22:34:35','2026-09-15 22:34:35','2026-09-15 22:34:35',NULL,NULL,'Acceso permitido para victor.','2026-09-15 22:34:35'),(95,2,2,5,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-15 22:39:16','2026-09-15 22:39:16','2026-09-15 22:39:16',NULL,NULL,'Acceso permitido para victor.','2026-09-15 22:39:16'),(96,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-15 22:39:20','2026-09-15 22:39:20','2026-09-15 22:39:20',NULL,NULL,'Acceso permitido para victor.','2026-09-15 22:39:20'),(97,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-15 22:39:27','2026-09-15 22:39:27','2026-09-15 22:39:27',NULL,NULL,'Acceso permitido para victor.','2026-09-15 22:39:27'),(98,2,2,5,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-15 22:39:28','2026-09-15 22:39:28','2026-09-15 22:39:28',NULL,NULL,'Acceso permitido para victor.','2026-09-15 22:39:28'),(99,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-15 22:39:39','2026-09-15 22:39:39','2026-09-15 22:39:39',NULL,NULL,'Acceso permitido para victor.','2026-09-15 22:39:39'),(100,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-15 22:39:45','2026-09-15 22:39:45','2026-09-15 22:39:45',NULL,NULL,'Acceso permitido para victor.','2026-09-15 22:39:45'),(101,2,2,5,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-15 22:43:35','2026-09-15 22:43:35','2026-09-15 22:43:35',NULL,NULL,'Acceso permitido para victor.','2026-09-15 22:43:35'),(102,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-15 22:44:14','2026-09-15 22:44:14','2026-09-15 22:44:14',NULL,NULL,'Acceso permitido para victor.','2026-09-15 22:44:14'),(103,2,2,5,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-15 22:44:20','2026-09-15 22:44:20','2026-09-15 22:44:20',NULL,NULL,'Acceso permitido para victor.','2026-09-15 22:44:20'),(104,2,2,5,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-15 22:44:44','2026-09-15 22:44:44','2026-09-15 22:44:44',NULL,NULL,'Acceso permitido para victor.','2026-09-15 22:44:44'),(105,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-15 22:44:46','2026-09-15 22:44:46','2026-09-15 22:44:46',NULL,NULL,'Acceso permitido para victor.','2026-09-15 22:44:46'),(106,2,2,4,3,3,'8C2FCD04','entrada','permitido','tarjeta_autorizada','2026-09-15 22:44:49','2026-09-15 22:44:49','2026-09-15 22:44:49',NULL,NULL,'Acceso permitido para victor.','2026-09-15 22:44:49'),(107,2,2,5,NULL,NULL,'E541CB04','entrada','denegado','tarjeta_no_registrada','2026-09-28 11:30:03','2026-09-28 11:30:03',NULL,NULL,NULL,'Acceso denegado: UID desconocida (E541CB04)','2026-09-28 11:30:03'),(108,2,2,5,NULL,NULL,'E541CB04','entrada','denegado','tarjeta_no_registrada','2026-09-28 11:30:56','2026-09-28 11:30:56',NULL,NULL,NULL,'Acceso denegado: UID desconocida (E541CB04)','2026-09-28 11:30:56'),(109,2,2,5,NULL,NULL,'E541CB04','entrada','denegado','tarjeta_no_registrada','2026-09-28 11:36:43','2026-09-28 11:36:43',NULL,NULL,NULL,'Acceso denegado: UID desconocida (E541CB04)','2026-09-28 11:36:43'),(110,2,2,5,NULL,NULL,'E541CB04','entrada','denegado','tarjeta_no_registrada','2026-09-28 11:39:02','2026-09-28 11:39:02',NULL,NULL,NULL,'Acceso denegado: UID desconocida (E541CB04)','2026-09-28 11:39:02'),(111,2,2,4,NULL,NULL,'E541CB04','entrada','denegado','tarjeta_no_registrada','2026-09-28 11:39:06','2026-09-28 11:39:06',NULL,NULL,NULL,'Acceso denegado: UID desconocida (E541CB04)','2026-09-28 11:39:06'),(112,2,2,4,NULL,NULL,'E541CB04','entrada','denegado','tarjeta_no_registrada','2026-09-28 11:39:11','2026-09-28 11:39:11',NULL,NULL,NULL,'Acceso denegado: UID desconocida (E541CB04)','2026-09-28 11:39:11'),(113,2,2,4,4,4,'E541CB04','entrada','permitido','tarjeta_autorizada','2026-09-28 11:41:13','2026-09-28 11:41:13','2026-09-28 11:41:13',NULL,NULL,'Acceso permitido para santiago goat farias.','2026-09-28 11:41:13'),(114,2,2,4,4,4,'E541CB04','entrada','permitido','tarjeta_autorizada','2026-09-28 11:41:36','2026-09-28 11:41:36','2026-09-28 11:41:36',NULL,NULL,'Acceso permitido para santiago goat farias.','2026-09-28 11:41:36');
/*!40000 ALTER TABLE `eventos_acceso` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `logs_auditoria`
--

DROP TABLE IF EXISTS `logs_auditoria`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `logs_auditoria` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `empresa_id` int(10) unsigned DEFAULT NULL COMMENT 'NULL si fue una acci??n global del sistema',
  `usuario_actor_id` int(10) unsigned DEFAULT NULL,
  `accion` enum('iniciar_sesion','cerrar_sesion','crear_usuario','actualizar_usuario','desactivar_usuario','reactivar_usuario','registrar_tarjeta','asignar_tarjeta','revocar_tarjeta','actualizar_configuracion','reconocer_alerta','registrar_producto','vincular_producto','desvincular_producto','actualizar_dispositivo','otro') NOT NULL,
  `tipo_entidad` varchar(60) NOT NULL,
  `entidad_id` int(10) unsigned DEFAULT NULL,
  `detalles` longtext CHARACTER SET utf8mb4 COLLATE utf8mb4_bin DEFAULT NULL CHECK (json_valid(`detalles`)),
  `ip_origen` varchar(45) DEFAULT NULL,
  `creado_en` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_logs_empresa` (`empresa_id`),
  KEY `idx_logs_usuario` (`usuario_actor_id`),
  KEY `idx_logs_accion` (`accion`),
  KEY `idx_logs_entidad` (`tipo_entidad`),
  KEY `idx_logs_entidad_id` (`entidad_id`),
  KEY `idx_logs_fecha` (`creado_en`),
  CONSTRAINT `fk_logs_empresas` FOREIGN KEY (`empresa_id`) REFERENCES `empresas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_logs_usuarios` FOREIGN KEY (`usuario_actor_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=36 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `logs_auditoria`
--

LOCK TABLES `logs_auditoria` WRITE;
/*!40000 ALTER TABLE `logs_auditoria` DISABLE KEYS */;
INSERT INTO `logs_auditoria` VALUES (2,2,2,'iniciar_sesion','usuario',2,'{\"descripcion\":\"Inicio de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-08-25 12:39:36'),(3,2,2,'cerrar_sesion','usuario',2,'{\"descripcion\":\"Cierre de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-08-25 12:41:03'),(4,2,2,'iniciar_sesion','usuario',2,'{\"descripcion\":\"Inicio de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-08-25 12:42:53'),(5,2,2,'otro','portones',2,'{\"accion_detalle\":\"registrar_porton\",\"descripcion\":\"Se creó un nuevo portón: aaaaa\",\"ip\":\"::1\"}','::1','2026-08-25 12:51:16'),(6,2,2,'vincular_producto','dispositivos_iot',2,'{\"accion_detalle\":\"vincular_dispositivo\",\"descripcion\":\"Se vinculó la ESP32 \'aaaaa\' con MAC AA:BB:CC:11:22:33 al portón ID 2\",\"mac\":\"AA:BB:CC:11:22:33\",\"producto_id\":\"1\",\"porton_id\":2,\"ip\":\"::1\"}','::1','2026-08-25 12:51:16'),(7,2,2,'cerrar_sesion','usuario',2,'{\"descripcion\":\"Cierre de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-08-25 13:02:44'),(8,2,2,'iniciar_sesion','usuario',2,'{\"descripcion\":\"Inicio de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-08-25 13:02:47'),(9,2,2,'vincular_producto','dispositivos_iot',3,'{\"accion_detalle\":\"vincular_dispositivo\",\"descripcion\":\"Se vinculó la ESP32 \'qwqeweq\' con MAC 10:20:30:40:50:60 al portón ID 2\",\"mac\":\"10:20:30:40:50:60\",\"producto_id\":\"2\",\"porton_id\":2,\"ip\":\"::1\"}','::1','2026-08-26 10:33:40'),(10,2,2,'otro','dispositivos_iot',3,'{\"accion_detalle\":\"desvincular_dispositivo\",\"descripcion\":\"Dispositivo desvinculado del portón: qwqeweq\",\"ip\":\"::1\"}','::1','2026-09-08 11:11:34'),(11,2,2,'crear_usuario','usuario',3,'{\"descripcion\":\"Usuario creado: victor\",\"username\":\"victor natalian\",\"email\":null,\"rol_id\":4,\"estado\":\"activo\",\"ip\":\"::1\"}','::1','2026-09-08 11:13:10'),(12,2,2,'registrar_tarjeta','tarjeta_rfid',3,'{\"descripcion\":\"Tarjeta registrada: 8C2FCD04 para victor\",\"uid\":\"8C2FCD04\",\"usuario_id\":3,\"usuario\":\"victor\",\"estado\":\"activa\",\"ip\":\"::1\"}','::1','2026-09-08 11:13:52'),(13,2,2,'iniciar_sesion','usuario',2,'{\"descripcion\":\"Inicio de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-09-08 11:27:24'),(14,2,2,'cerrar_sesion','usuario',2,'{\"descripcion\":\"Cierre de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-09-08 11:27:29'),(15,2,2,'iniciar_sesion','usuario',2,'{\"descripcion\":\"Inicio de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-09-08 11:27:35'),(16,2,2,'iniciar_sesion','usuario',2,'{\"descripcion\":\"Inicio de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-09-22 22:02:48'),(17,2,2,'cerrar_sesion','usuario',2,'{\"descripcion\":\"Cierre de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-09-23 19:19:21'),(18,2,2,'iniciar_sesion','usuario',2,'{\"descripcion\":\"Inicio de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-09-23 19:29:54'),(19,2,2,'cerrar_sesion','usuario',2,'{\"descripcion\":\"Cierre de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-09-23 19:38:07'),(20,2,2,'iniciar_sesion','usuario',2,'{\"descripcion\":\"Inicio de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-09-23 19:38:22'),(21,2,2,'cerrar_sesion','usuario',2,'{\"descripcion\":\"Cierre de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-09-27 13:38:10'),(22,2,2,'iniciar_sesion','usuario',2,'{\"descripcion\":\"Inicio de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-09-27 13:38:12'),(23,2,2,'cerrar_sesion','usuario',2,'{\"descripcion\":\"Cierre de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-09-27 13:38:14'),(24,2,2,'iniciar_sesion','usuario',2,'{\"descripcion\":\"Inicio de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-09-27 13:48:58'),(25,2,2,'cerrar_sesion','usuario',2,'{\"descripcion\":\"Cierre de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-09-27 20:01:18'),(26,2,2,'iniciar_sesion','usuario',2,'{\"descripcion\":\"Inicio de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-09-27 20:01:20'),(27,2,2,'cerrar_sesion','usuario',2,'{\"descripcion\":\"Cierre de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-09-28 10:34:05'),(28,2,2,'iniciar_sesion','usuario',2,'{\"descripcion\":\"Inicio de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-09-28 10:34:19'),(29,2,2,'iniciar_sesion','usuario',2,'{\"descripcion\":\"Inicio de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-09-28 11:40:08'),(30,2,2,'crear_usuario','usuario',4,'{\"descripcion\":\"Usuario creado: santiago goat farias\",\"username\":\"popeye\",\"email\":\"asdasdad@gmail.com\",\"rol_id\":1,\"estado\":\"activo\",\"ip\":\"::1\"}','::1','2026-09-28 11:40:54'),(31,2,2,'registrar_tarjeta','tarjeta_rfid',4,'{\"descripcion\":\"Tarjeta registrada: E541CB04 para santiago goat farias\",\"uid\":\"E541CB04\",\"usuario_id\":4,\"usuario\":\"santiago goat farias\",\"estado\":\"activa\",\"ip\":\"::1\"}','::1','2026-09-28 11:41:02'),(32,2,2,'cerrar_sesion','usuario',2,'{\"descripcion\":\"Cierre de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-09-30 20:04:00'),(33,2,2,'iniciar_sesion','usuario',2,'{\"descripcion\":\"Inicio de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-09-30 20:04:04'),(34,2,2,'cerrar_sesion','usuario',2,'{\"descripcion\":\"Cierre de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-09-30 20:04:30'),(35,2,2,'iniciar_sesion','usuario',2,'{\"descripcion\":\"Inicio de sesion: facundo.llorens\",\"username\":\"facundo.llorens\",\"ip\":\"::1\"}','::1','2026-09-30 20:05:50');
/*!40000 ALTER TABLE `logs_auditoria` ENABLE KEYS */;
UNLOCK TABLES;


--
-- Table structure for table `pagos`
--

DROP TABLE IF EXISTS `pagos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `pagos` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `empresa_id` int(10) unsigned DEFAULT NULL,
  `usuario_id` int(10) unsigned DEFAULT NULL,
  `producto_id` int(10) unsigned DEFAULT NULL,
  `monto` decimal(10,2) NOT NULL DEFAULT 0.00,
  `moneda` varchar(10) NOT NULL DEFAULT 'USD',
  `estado` enum('pendiente','completado','fallido','reembolsado') NOT NULL DEFAULT 'pendiente',
  `metodo_pago` varchar(50) DEFAULT 'paypal',
  `paypal_order_id` varchar(100) DEFAULT NULL,
  `referencia_externa` varchar(150) DEFAULT NULL,
  `creado_en` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  KEY `idx_pagos_empresa` (`empresa_id`),
  KEY `idx_pagos_usuario` (`usuario_id`),
  KEY `idx_pagos_producto` (`producto_id`),
  CONSTRAINT `fk_pagos_empresas` FOREIGN KEY (`empresa_id`) REFERENCES `empresas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_pagos_productos` FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_pagos_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `pagos`
--

LOCK TABLES `pagos` WRITE;
/*!40000 ALTER TABLE `pagos` DISABLE KEYS */;
/*!40000 ALTER TABLE `pagos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `password_resets`
--

DROP TABLE IF EXISTS `password_resets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `password_resets` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` int(10) unsigned NOT NULL,
  `email` varchar(190) NOT NULL,
  `token_hash` char(64) NOT NULL,
  `expira_en` datetime NOT NULL,
  `usado_en` datetime DEFAULT NULL,
  `creado_en` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_password_resets_token` (`token_hash`),
  KEY `idx_password_resets_usuario` (`usuario_id`),
  CONSTRAINT `fk_password_resets_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `password_resets`
--

LOCK TABLES `password_resets` WRITE;
/*!40000 ALTER TABLE `password_resets` DISABLE KEYS */;
INSERT INTO `password_resets` VALUES (1,2,'facundollorens4@gmail.com','2b33127cb0635b14425087fa1821c3957abaa840e36646b09b2159a84e9452a7','2026-08-25 13:41:13','2026-08-25 12:42:34','2026-08-25 12:41:13');
/*!40000 ALTER TABLE `password_resets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `portones`
--

DROP TABLE IF EXISTS `portones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `portones` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `empresa_id` int(10) unsigned NOT NULL,
  `nombre` varchar(80) NOT NULL,
  `ubicacion` varchar(120) DEFAULT NULL,
  `estado` enum('cerrado','abierto','abriendo','cerrando','error','mantenimiento') NOT NULL DEFAULT 'cerrado',
  `activo` tinyint(1) NOT NULL DEFAULT 1,
  `duracion_apertura_seg` int(10) unsigned NOT NULL DEFAULT 0,
  `retardo_cierre_seg` int(10) unsigned NOT NULL DEFAULT 0,
  `ultima_apertura` datetime DEFAULT NULL,
  `ultimo_cierre` datetime DEFAULT NULL,
  `ultimo_cambio_estado` datetime DEFAULT NULL,
  `creado_en` datetime NOT NULL DEFAULT current_timestamp(),
  `actualizado_en` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_portones_empresa_nombre` (`empresa_id`,`nombre`),
  CONSTRAINT `fk_portones_empresas` FOREIGN KEY (`empresa_id`) REFERENCES `empresas` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=3 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `portones`
--

LOCK TABLES `portones` WRITE;
/*!40000 ALTER TABLE `portones` DISABLE KEYS */;
INSERT INTO `portones` VALUES (2,2,'aaaaa',NULL,'abierto',1,5,0,'2026-09-28 11:41:36',NULL,'2026-09-28 11:41:36','2026-08-25 12:51:16','2026-09-28 11:41:36');
/*!40000 ALTER TABLE `portones` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `productos`
--

DROP TABLE IF EXISTS `productos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `productos` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `codigo_serial` varchar(80) NOT NULL COMMENT 'C??digo ??nico de serie f??sico',
  `mac` varchar(32) NOT NULL COMMENT 'MAC address f??sica del ESP32 (de f??brica)',
  `modelo` enum('autogate_v1','autogate_v2','autogate_mini') NOT NULL DEFAULT 'autogate_v1',
  `version_firmware` varchar(30) DEFAULT NULL,
  `lote` varchar(50) DEFAULT NULL,
  `estado` enum('disponible','activado','defectuoso','retirado') NOT NULL DEFAULT 'disponible',
  `notas_internas` text DEFAULT NULL,
  `creado_en` datetime NOT NULL DEFAULT current_timestamp(),
  `actualizado_en` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_productos_serial` (`codigo_serial`),
  UNIQUE KEY `uq_productos_mac` (`mac`),
  KEY `idx_productos_estado` (`estado`),
  KEY `idx_productos_modelo` (`modelo`)
) ENGINE=InnoDB AUTO_INCREMENT=12 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `productos`
--

LOCK TABLES `productos` WRITE;
/*!40000 ALTER TABLE `productos` DISABLE KEYS */;
INSERT INTO `productos` VALUES (1,'AG-2026-ESP001','AA:BB:CC:11:22:33','autogate_v1','v1.0.0','LOTE-2026-A','activado','ESP32 oficial de prueba 1','2026-08-25 14:20:48','2026-08-25 12:51:16'),(2,'AG-2026-ESP002','10:20:30:40:50:60','autogate_v2','v1.0.0','LOTE-2026-A','activado','ESP32 oficial de prueba 2','2026-08-25 14:20:48','2026-08-26 10:33:40'),(3,'AG-2026-ESP003','E0:E2:E6:AA:BB:CC','autogate_mini','v1.0.0','LOTE-2026-B','disponible','ESP32 oficial de prueba 3','2026-08-25 14:20:48','2026-08-25 14:20:48'),(4,'AG-2026-ESP004','24:6F:28:1A:2B:3C','autogate_v1','v1.0.0','LOTE-TEST-2026','disponible','ESP32 Test Laboratorio 1','2026-08-25 12:46:41','2026-08-25 12:46:41'),(5,'AG-2026-ESP005','30:AE:A4:4D:5E:6F','autogate_v2','v1.0.0','LOTE-TEST-2026','disponible','ESP32 Test Laboratorio 2','2026-08-25 12:46:41','2026-08-25 12:46:41'),(6,'AG-2026-ESP006','AC:67:B2:7A:8B:9C','autogate_v1','v1.0.0','LOTE-TEST-2026','disponible','ESP32 Test Porton Principal','2026-08-25 12:46:41','2026-08-25 12:46:41'),(7,'AG-2026-ESP007','84:F3:EB:11:22:33','autogate_v2','v1.0.0','LOTE-TEST-2026','disponible','ESP32 Test Entrada','2026-08-25 12:46:41','2026-08-25 12:46:41'),(8,'AG-2026-ESP008','94:B9:7E:AA:CC:EE','autogate_mini','v1.0.0','LOTE-TEST-2026','disponible','ESP32 Test Salida','2026-08-25 12:46:41','2026-08-25 12:46:41'),(10,'AG-REAL-8C94DF8E02CC','8C:94:DF:8E:02:CC','autogate_v1','v2.0-spi','LOTE-REAL-2026','activado','ESP32 real de Facundo - PN532 SPI','2026-09-04 10:04:09','2026-09-04 10:04:09'),(11,'AG-REAL-8857212F1268','88:57:21:2F:12:68','autogate_v1','v2.0-main','LOTE-REAL-2026','activado','ESP32 Main de Facundo - Porton Buzzer','2026-09-09 22:08:43','2026-09-09 22:08:43');
/*!40000 ALTER TABLE `productos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `roles`
--

DROP TABLE IF EXISTS `roles`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `roles` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `empresa_id` int(10) unsigned DEFAULT NULL COMMENT 'NULL = Rol global/plantilla',
  `nombre` varchar(50) NOT NULL,
  `descripcion` varchar(255) DEFAULT NULL,
  `es_admin` tinyint(1) NOT NULL DEFAULT 0,
  `permisos_json` longtext DEFAULT NULL COMMENT 'JSON con flags de permisos',
  `creado_en` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_roles_empresa_nombre` (`empresa_id`,`nombre`),
  KEY `idx_roles_empresa` (`empresa_id`),
  CONSTRAINT `fk_roles_empresas` FOREIGN KEY (`empresa_id`) REFERENCES `empresas` (`id`) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `roles`
--

LOCK TABLES `roles` WRITE;
/*!40000 ALTER TABLE `roles` DISABLE KEYS */;
INSERT INTO `roles` VALUES (1,NULL,'admin','Acceso total al sistema',1,'{}','2026-08-25 14:20:48'),(2,NULL,'operador','Operacion diaria de tarjetas, dispositivos y accesos',0,'{\"panel\": {\"ver\": true}, \"tarjetas\": {\"ver\": true, \"editar\": true}, \"dispositivos\": {\"ver\": true, \"editar\": true}, \"accesos\": {\"ver\": true, \"editar\": true}, \"usuarios\": {\"ver\": false, \"editar\": false}, \"auditoria\": {\"ver\": false}, \"comprar\": {\"ver\": false}}','2026-08-25 14:20:48');
/*!40000 ALTER TABLE `roles` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `sesiones`
--

DROP TABLE IF EXISTS `sesiones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `sesiones` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` int(10) unsigned NOT NULL,
  `token_hash` varchar(255) NOT NULL,
  `ip` varchar(45) DEFAULT NULL,
  `user_agent` varchar(255) DEFAULT NULL,
  `creado_en` datetime NOT NULL DEFAULT current_timestamp(),
  `ultima_actividad` datetime DEFAULT NULL,
  `expira_en` datetime NOT NULL,
  `revocada_en` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_sesiones_token` (`token_hash`),
  KEY `idx_sesiones_usuario` (`usuario_id`),
  KEY `idx_sesiones_expira` (`expira_en`),
  CONSTRAINT `fk_sesiones_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON DELETE CASCADE ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `sesiones`
--

LOCK TABLES `sesiones` WRITE;
/*!40000 ALTER TABLE `sesiones` DISABLE KEYS */;
/*!40000 ALTER TABLE `sesiones` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `tarjetas_rfid`
--

DROP TABLE IF EXISTS `tarjetas_rfid`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `tarjetas_rfid` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `usuario_id` int(10) unsigned NOT NULL,
  `uid` varchar(32) NOT NULL,
  `etiqueta` varchar(80) DEFAULT NULL,
  `estado` enum('activa','inactiva','perdida','revocada','suspendida') NOT NULL DEFAULT 'activa',
  `asignada_en` datetime NOT NULL DEFAULT current_timestamp(),
  `revocada_en` datetime DEFAULT NULL,
  `notas` varchar(255) DEFAULT NULL,
  `creado_en` datetime NOT NULL DEFAULT current_timestamp(),
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_tarjetas_uid` (`uid`),
  KEY `idx_tarjetas_usuario` (`usuario_id`),
  KEY `idx_tarjetas_estado` (`estado`),
  CONSTRAINT `fk_tarjetas_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=5 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `tarjetas_rfid`
--

LOCK TABLES `tarjetas_rfid` WRITE;
/*!40000 ALTER TABLE `tarjetas_rfid` DISABLE KEYS */;
INSERT INTO `tarjetas_rfid` VALUES (2,2,'SIM-B67F9878','Tarjeta simulada','activa','2026-08-25 13:02:33',NULL,'Generada para probar ingresos sin ESP32.','2026-08-25 13:02:33'),(3,3,'8C2FCD04',NULL,'activa','2026-09-08 11:13:52',NULL,NULL,'2026-09-08 11:13:52'),(4,4,'E541CB04',NULL,'activa','2026-09-28 11:41:02',NULL,NULL,'2026-09-28 11:41:02');
/*!40000 ALTER TABLE `tarjetas_rfid` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `usuarios`
--

DROP TABLE IF EXISTS `usuarios`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `usuarios` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `rol_id` int(10) unsigned NOT NULL,
  `es_superadmin` tinyint(1) NOT NULL DEFAULT 0,
  `empresa_id` int(10) unsigned NOT NULL,
  `username` varchar(50) NOT NULL,
  `nombre_completo` varchar(120) NOT NULL,
  `email` varchar(120) DEFAULT NULL,
  `telefono` varchar(30) DEFAULT NULL,
  `password_hash` varchar(255) NOT NULL,
  `estado` enum('activo','inactivo','suspendido') NOT NULL DEFAULT 'activo',
  `restringir_horario` tinyint(1) DEFAULT 0,
  `hora_entrada_permitida` time DEFAULT NULL,
  `hora_salida_permitida` time DEFAULT NULL,
  `dias_permitidos` set('1','2','3','4','5','6','7') DEFAULT '1,2,3,4,5',
  `ultimo_login` datetime DEFAULT NULL,
  `creado_en` datetime NOT NULL DEFAULT current_timestamp(),
  `actualizado_en` datetime NOT NULL DEFAULT current_timestamp() ON UPDATE current_timestamp(),
  `desactivado_en` datetime DEFAULT NULL,
  PRIMARY KEY (`id`),
  UNIQUE KEY `uq_usuarios_username` (`username`),
  UNIQUE KEY `uq_usuarios_email` (`email`),
  KEY `idx_usuarios_rol` (`rol_id`),
  KEY `idx_usuarios_estado` (`estado`),
  KEY `idx_usuarios_empresa` (`empresa_id`),
  CONSTRAINT `fk_usuarios_empresas` FOREIGN KEY (`empresa_id`) REFERENCES `empresas` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_usuarios_roles` FOREIGN KEY (`rol_id`) REFERENCES `roles` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `usuarios`
--

LOCK TABLES `usuarios` WRITE;
/*!40000 ALTER TABLE `usuarios` DISABLE KEYS */;
INSERT INTO `usuarios` VALUES (2,1,1,2,'facundo.llorens','facundo llorens','facundollorens4@gmail.com',NULL,'$2y$10$CWwhqJZ6TiUqk8y2IsOSyeCgEU7R2DY0kTcqIOlrpOuydncmc14LC','activo',0,NULL,NULL,'1,2,3,4,5','2026-09-30 20:05:50','2026-08-25 12:39:31','2026-09-30 20:07:19',NULL),(3,2,0,2,'victor natalian','victor',NULL,NULL,'$2y$10$ZnBQSsBKuathITq..bYCAuSK6.MDNo3/QiKrbSFQGE4JPX4kihQoS','activo',0,NULL,NULL,'1,2,3,4,5',NULL,'2026-09-08 11:13:10','2026-09-28 10:48:33',NULL),(4,1,0,2,'popeye','santiago goat farias','asdasdad@gmail.com','451516151516','$2y$10$pHJd7aWq4urpvji6dAMXwu7Y8Qa0aMmFTmkIRj//S0PtF.4.4sPjO','activo',0,NULL,NULL,'1,2,3,4,5',NULL,'2026-09-28 11:40:54','2026-09-28 11:40:54',NULL),(5,1,1,2,'santi','Santiago Admin','santi@autogate.com','1123456789','$2y$10$r5wjr/JS3Qls0RR30xCQ2.zNcNrrHy7cUnPKxZ2.SqwBQ1dOspWlC','activo',0,NULL,NULL,'1,2,3,4,5',NULL,'2026-09-30 20:07:19','2026-09-30 20:07:19',NULL);
/*!40000 ALTER TABLE `usuarios` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `vinculaciones_producto`
--

DROP TABLE IF EXISTS `vinculaciones_producto`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `vinculaciones_producto` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `producto_id` int(10) unsigned NOT NULL COMMENT 'Producto autorizado',
  `empresa_id` int(10) unsigned NOT NULL COMMENT 'Empresa propietaria',
  `usuario_id` int(10) unsigned NOT NULL COMMENT 'Usuario que vincul??',
  `estado` enum('activa','desvinculada') NOT NULL DEFAULT 'activa',
  `activado_en` datetime NOT NULL DEFAULT current_timestamp(),
  `desvinculado_en` datetime DEFAULT NULL,
  `desvinculado_por` int(10) unsigned DEFAULT NULL COMMENT 'Usuario que desvincul??',
  `motivo_desvinculacion` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `idx_vinculaciones_producto` (`producto_id`),
  KEY `idx_vinculaciones_empresa` (`empresa_id`),
  KEY `idx_vinculaciones_usuario` (`usuario_id`),
  KEY `idx_vinculaciones_estado` (`estado`),
  KEY `idx_vinculaciones_desvinculado_por` (`desvinculado_por`),
  CONSTRAINT `fk_vinculaciones_desvinculado_por` FOREIGN KEY (`desvinculado_por`) REFERENCES `usuarios` (`id`) ON DELETE SET NULL ON UPDATE CASCADE,
  CONSTRAINT `fk_vinculaciones_empresas` FOREIGN KEY (`empresa_id`) REFERENCES `empresas` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_vinculaciones_productos` FOREIGN KEY (`producto_id`) REFERENCES `productos` (`id`) ON UPDATE CASCADE,
  CONSTRAINT `fk_vinculaciones_usuarios` FOREIGN KEY (`usuario_id`) REFERENCES `usuarios` (`id`) ON UPDATE CASCADE
) ENGINE=InnoDB AUTO_INCREMENT=6 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_spanish_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `vinculaciones_producto`
--

LOCK TABLES `vinculaciones_producto` WRITE;
/*!40000 ALTER TABLE `vinculaciones_producto` DISABLE KEYS */;
INSERT INTO `vinculaciones_producto` VALUES (2,1,2,2,'activa','2026-08-25 12:51:16',NULL,NULL,NULL),(3,2,2,2,'activa','2026-08-26 10:33:40',NULL,NULL,NULL),(4,10,2,2,'activa','2026-09-04 10:04:09',NULL,NULL,NULL),(5,11,2,2,'activa','2026-09-09 22:08:43',NULL,NULL,NULL);
/*!40000 ALTER TABLE `vinculaciones_producto` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2026-09-30 20:14:07
