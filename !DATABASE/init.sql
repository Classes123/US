-- --------------------------------------------------------
-- Хост:                         127.0.0.1
-- Версия сервера:               5.7.29 - MySQL Community Server (GPL)
-- Операционная система:         Win64
-- HeidiSQL Версия:              11.2.0.6213
-- --------------------------------------------------------

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET NAMES utf8 */;
/*!50503 SET NAMES utf8mb4 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

-- Дамп структуры для таблица uni.us_admin
CREATE TABLE IF NOT EXISTS `us_admin` (
  `admin_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `auth` int(10) unsigned NOT NULL COMMENT 'Admin Steam32',
  `name` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL DEFAULT '' COMMENT 'Admin name (Permanent)',
  PRIMARY KEY (`admin_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Admin profiles';

-- Дамп данных таблицы uni.us_admin: ~1 rows (приблизительно)
/*!40000 ALTER TABLE `us_admin` DISABLE KEYS */;
REPLACE INTO `us_admin` (`admin_id`, `auth`, `name`) VALUES
	(0, 0, 'Console');
/*!40000 ALTER TABLE `us_admin` ENABLE KEYS */;

-- Дамп структуры для таблица uni.us_admin_data
CREATE TABLE IF NOT EXISTS `us_admin_data` (
  `admin_data_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `admin_id` int(10) unsigned NOT NULL COMMENT '`us_admin`.`admin_id`',
  `group_id` int(10) unsigned NOT NULL COMMENT '`us_admin_group`.`group_id`',
  `server_id` int(10) unsigned NOT NULL COMMENT '`us_server`.`server_id`',
  `expiry_date` int(10) unsigned NOT NULL COMMENT 'UNIX timestamp expiry date',
  PRIMARY KEY (`admin_data_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Admins routings';

-- Дамп данных таблицы uni.us_admin_data: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `us_admin_data` DISABLE KEYS */;
/*!40000 ALTER TABLE `us_admin_data` ENABLE KEYS */;

-- Дамп структуры для таблица uni.us_admin_group
CREATE TABLE IF NOT EXISTS `us_admin_group` (
  `group_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `name` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Group name',
  `flags` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'Flags bits',
  `immunity` int(10) unsigned NOT NULL DEFAULT '0' COMMENT 'Group immunity',
  PRIMARY KEY (`group_id`) USING BTREE,
  UNIQUE KEY `name` (`name`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Admins groups';

-- Дамп данных таблицы uni.us_admin_group: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `us_admin_group` DISABLE KEYS */;
/*!40000 ALTER TABLE `us_admin_group` ENABLE KEYS */;

-- Дамп структуры для таблица uni.us_client
CREATE TABLE IF NOT EXISTS `us_client` (
  `client_id` int(11) unsigned NOT NULL,
  `client_name` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Client name',
  `first_login` int(11) unsigned NOT NULL COMMENT 'First login UNIX timestamp',
  `last_login` int(11) unsigned NOT NULL COMMENT 'Last login UNIX timestamp',
  `last_ip` int(11) unsigned NOT NULL COMMENT 'Last INET_ATON() IP address',
  PRIMARY KEY (`client_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Client profiles';

-- Дамп данных таблицы uni.us_client: ~1 rows (приблизительно)
/*!40000 ALTER TABLE `us_client` DISABLE KEYS */;
REPLACE INTO `us_client` (`client_id`, `client_name`, `first_login`, `last_login`, `last_ip`) VALUES
	(0, 'Unknown Player', 0, 0, 0);
/*!40000 ALTER TABLE `us_client` ENABLE KEYS */;

-- Дамп структуры для таблица uni.us_punish
CREATE TABLE IF NOT EXISTS `us_punish` (
  `punish_id` int(11) NOT NULL AUTO_INCREMENT,
  `punish_type` int(11) unsigned NOT NULL COMMENT '`us_punish_type`.`punish_type_id`',
  `punish_reason` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Punishment reason',
  `client_id` int(11) unsigned NOT NULL COMMENT 'Client Steam32',
  `client_ip` int(10) unsigned NOT NULL COMMENT 'Client IP address',
  `server_id` int(11) unsigned NOT NULL COMMENT '`us_server`.`server_id` or 0 for global',
  `admin_id` int(11) unsigned NOT NULL COMMENT '`us_admin`.`admin_id` who adds a punishment',
  `create_date` int(11) unsigned NOT NULL COMMENT 'UNIX timestamp create date',
  `update_date` int(11) unsigned NOT NULL COMMENT 'By default, `update_date` = `create_date` for easy sorting',
  `expiry_date` int(11) unsigned NOT NULL COMMENT 'UNIX timestamp expiry date',
  `remove_date` int(11) unsigned NOT NULL DEFAULT '0' COMMENT 'UNIX timestamp remove date',
  `remove_admin_id` int(11) unsigned NOT NULL DEFAULT '0' COMMENT '`us_admin`.`admin_id` who removes a punishment',
  PRIMARY KEY (`punish_id`) USING BTREE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Punishments profiles';

-- Дамп данных таблицы uni.us_punish: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `us_punish` DISABLE KEYS */;
/*!40000 ALTER TABLE `us_punish` ENABLE KEYS */;

-- Дамп структуры для таблица uni.us_punish_type
CREATE TABLE IF NOT EXISTS `us_punish_type` (
  `punish_type_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `identifier` varchar(32) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Unique identifier',
  PRIMARY KEY (`punish_type_id`),
  UNIQUE KEY `identifier` (`identifier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Punishments types';

-- Дамп данных таблицы uni.us_punish_type: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `us_punish_type` DISABLE KEYS */;
/*!40000 ALTER TABLE `us_punish_type` ENABLE KEYS */;

-- Дамп структуры для таблица uni.us_punish_update
CREATE TABLE IF NOT EXISTS `us_punish_update` (
  `punish_update_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `punish_update_date` int(10) unsigned NOT NULL COMMENT 'UNIX timestamp update date',
  `punish_update_reason` varchar(256) COLLATE utf8mb4_unicode_ci NOT NULL COMMENT 'Update reason',
  `punish_id` int(10) unsigned NOT NULL COMMENT '`us_punish`.`punish_id`',
  `admin_id` int(10) unsigned NOT NULL COMMENT '`us_admin`.`admin_id` who updates a punishment',
  `prev_expiry_date` int(10) unsigned NOT NULL COMMENT 'Previous UNIX timestamp expiry date',
  `new_expiry_date` int(10) unsigned NOT NULL COMMENT 'New UNIX timestamp expiry date',
  PRIMARY KEY (`punish_update_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Punishments updates';

-- Дамп данных таблицы uni.us_punish_update: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `us_punish_update` DISABLE KEYS */;
/*!40000 ALTER TABLE `us_punish_update` ENABLE KEYS */;

-- Дамп структуры для таблица uni.us_server
CREATE TABLE IF NOT EXISTS `us_server` (
  `server_id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `address` int(10) unsigned NOT NULL COMMENT 'Server INET_ATON() IP address',
  `port` smallint(5) unsigned NOT NULL COMMENT 'Server port',
  `hostname` varchar(256) COLLATE utf8mb4_unicode_ci DEFAULT NULL COMMENT 'Server hostname',
  `lastsync` int(11) unsigned DEFAULT NULL COMMENT 'UNIX timestamp last synchronization date',
  PRIMARY KEY (`server_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci COMMENT='Servers profiles';

-- Дамп данных таблицы uni.us_server: ~0 rows (приблизительно)
/*!40000 ALTER TABLE `us_server` DISABLE KEYS */;
/*!40000 ALTER TABLE `us_server` ENABLE KEYS */;

/*!40101 SET SQL_MODE=IFNULL(@OLD_SQL_MODE, '') */;
/*!40014 SET FOREIGN_KEY_CHECKS=IFNULL(@OLD_FOREIGN_KEY_CHECKS, 1) */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40111 SET SQL_NOTES=IFNULL(@OLD_SQL_NOTES, 1) */;
