-- phpMyAdmin SQL Dump
-- version 5.2.3
-- https://www.phpmyadmin.net/
--
-- Máy chủ: 127.0.0.1:3306
-- Thời gian đã tạo: Th10 17, 2026 lúc 07:02 AM
-- Phiên bản máy phục vụ: 8.4.7
-- Phiên bản PHP: 8.3.28

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Cơ sở dữ liệu: `ai_chat_db`
--

-- --------------------------------------------------------

--
-- Cấu trúc bảng cho bảng `chat_messages`
--

DROP TABLE IF EXISTS `chat_messages`;
CREATE TABLE IF NOT EXISTS `chat_messages` (
  `id` bigint UNSIGNED NOT NULL AUTO_INCREMENT,
  `session_id` bigint UNSIGNED NOT NULL,
  `model_id` int DEFAULT NULL,
  `role` enum('system','user','assistant','tool') COLLATE utf8mb4_unicode_ci NOT NULL,
  `content` longtext COLLATE utf8mb4_unicode_ci NOT NULL,
  `metadata` json DEFAULT NULL,
  `prompt_tokens` int UNSIGNED DEFAULT '0',
  `completion_tokens` int UNSIGNED DEFAULT '0',
  `total_tokens` int UNSIGNED DEFAULT '0',
  `estimated_cost` decimal(10,6) DEFAULT '0.000000',
  `latency_ms` int UNSIGNED DEFAULT NULL,
  `created_at` timestamp(3) NULL DEFAULT CURRENT_TIMESTAMP(3),
  PRIMARY KEY (`id`),
  KEY `fk_messages_session` (`session_id`),
  KEY `fk_messages_model` (`model_id`)
) ENGINE=InnoDB AUTO_INCREMENT=27 DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

--
-- Đang đổ dữ liệu cho bảng `chat_messages`
--

INSERT INTO `chat_messages` (`id`, `session_id`, `model_id`, `role`, `content`, `metadata`, `prompt_tokens`, `completion_tokens`, `total_tokens`, `estimated_cost`, `latency_ms`, `created_at`) VALUES
(1, 1, NULL, 'user', 'Hãy giải thích khái niệm Database Indexing trong 2 câu.', NULL, 0, 0, 0, 0.000000, NULL, '2026-10-17 05:54:25.604'),
(2, 1, NULL, 'user', 'Hãy giải thích khái niệm Database Indexing trong 2 câu.', NULL, 0, 0, 0, 0.000000, NULL, '2026-10-17 05:54:25.604'),
(3, 1, NULL, 'user', 'Hãy giải thích khái niệm Database Indexing trong 2 câu.', NULL, 0, 0, 0, 0.000000, NULL, '2026-10-17 06:04:30.476'),
(4, 1, NULL, 'user', 'Hãy giải thích khái niệm Database Indexing trong 2 câu.', NULL, 0, 0, 0, 0.000000, NULL, '2026-10-17 06:04:30.476'),
(5, 1, NULL, 'user', 'Hãy giải thích khái niệm Database Indexing trong 2 câu.', NULL, 0, 0, 0, 0.000000, NULL, '2026-10-17 06:07:09.738'),
(6, 1, NULL, 'user', 'Hãy giải thích khái niệm Database Indexing trong 2 câu.', NULL, 0, 0, 0, 0.000000, NULL, '2026-10-17 06:07:09.738'),
(7, 1, NULL, 'user', 'Thử nghiệm lưu Token Usage vào CSDL MySQL.', NULL, 0, 0, 0, 0.000000, NULL, '2026-10-17 06:09:54.481'),
(8, 1, 1, 'assistant', '[Giả lập AI]: Đây là câu trả lời tự động cho câu hỏi \"Thử nghiệm lưu Token Usage vào CSDL MySQL.\". Database đã ghi nhận thành công!', '{\"is_mock\": true, \"finish_reason\": \"stop\"}', 11, 38, 49, 0.000408, 233, '2026-10-17 06:09:54.491'),
(9, 1, NULL, 'user', 'chào', NULL, 0, 0, 0, 0.000000, NULL, '2026-10-17 06:26:25.661'),
(10, 1, 1, 'assistant', '[Server trả lời]: Tôi đã nhận được tin nhắn \"chào\" của bạn. Dữ liệu đã được lưu vào MySQL!', '{\"is_mock\": true}', 18, 45, 63, 0.000495, 568, '2026-10-17 06:26:25.666'),
(11, 1, NULL, 'user', 'h', NULL, 0, 0, 0, 0.000000, NULL, '2026-10-17 06:34:57.421'),
(12, 1, 1, 'assistant', '[Server trả lời]: Tôi đã nhận được tin nhắn \"h\" của bạn. Dữ liệu đã được lưu vào MySQL!', '{\"is_mock\": true}', 12, 58, 70, 0.000610, 557, '2026-10-17 06:34:57.432'),
(13, 1, NULL, 'user', 'hello', NULL, 0, 0, 0, 0.000000, NULL, '2026-10-17 06:39:04.523'),
(14, 1, 1, 'assistant', '[Server trả lời]: Tôi đã nhận được tin nhắn \"hello\" của bạn. Dữ liệu đã được lưu vào MySQL!', '{\"is_mock\": true}', 14, 46, 60, 0.000495, 536, '2026-10-17 06:39:04.533'),
(15, 1, NULL, 'user', 't là sky', NULL, 0, 0, 0, 0.000000, NULL, '2026-10-17 06:48:53.309'),
(16, 1, 1, 'assistant', '[Server trả lời]: Tôi đã nhận được tin nhắn \"t là sky\" của bạn. Dữ liệu đã được lưu vào MySQL!', '{\"is_mock\": true}', 12, 50, 62, 0.000530, 522, '2026-10-17 06:48:53.320'),
(17, 4, NULL, 'user', 'lô', NULL, 0, 0, 0, 0.000000, NULL, '2026-10-17 07:00:08.474'),
(18, 4, 1, 'assistant', '[Server trả lời]: Tôi đã nhận được tin nhắn \"lô\" của bạn. Dữ liệu đã được lưu vào MySQL!', '{\"is_mock\": true}', 22, 23, 45, 0.000285, 543, '2026-10-17 07:00:08.485'),
(19, 3, NULL, 'user', 'dfg', NULL, 0, 0, 0, 0.000000, NULL, '2026-10-17 07:00:20.497'),
(20, 3, 1, 'assistant', '[Server trả lời]: Tôi đã nhận được tin nhắn \"dfg\" của bạn. Dữ liệu đã được lưu vào MySQL!', '{\"is_mock\": true}', 26, 56, 82, 0.000625, 298, '2026-10-17 07:00:20.506'),
(21, 2, NULL, 'user', 'sẻg', NULL, 0, 0, 0, 0.000000, NULL, '2026-10-17 07:00:24.613'),
(22, 2, 1, 'assistant', '[Server trả lời]: Tôi đã nhận được tin nhắn \"sẻg\" của bạn. Dữ liệu đã được lưu vào MySQL!', '{\"is_mock\": true}', 16, 41, 57, 0.000450, 503, '2026-10-17 07:00:24.623'),
(23, 5, NULL, 'user', 'hello fen', NULL, 0, 0, 0, 0.000000, NULL, '2026-10-17 07:01:10.937'),
(24, 5, 1, 'assistant', '[Server trả lời]: Tôi đã nhận được tin nhắn \"hello fen\" của bạn. Dữ liệu đã được lưu vào MySQL!', '{\"is_mock\": true}', 17, 56, 73, 0.000603, 332, '2026-10-17 07:01:10.945'),
(25, 6, NULL, 'user', 'aDa', NULL, 0, 0, 0, 0.000000, NULL, '2026-10-17 07:01:21.094'),
(26, 6, 1, 'assistant', '[Server trả lời]: Tôi đã nhận được tin nhắn \"aDa\" của bạn. Dữ liệu đã được lưu vào MySQL!', '{\"is_mock\": true}', 14, 37, 51, 0.000405, 369, '2026-10-17 07:01:21.103');

--
-- Ràng buộc đối với các bảng kết xuất
--

--
-- Ràng buộc cho bảng `chat_messages`
--
ALTER TABLE `chat_messages`
  ADD CONSTRAINT `fk_messages_model` FOREIGN KEY (`model_id`) REFERENCES `ai_models` (`id`) ON DELETE SET NULL,
  ADD CONSTRAINT `fk_messages_session` FOREIGN KEY (`session_id`) REFERENCES `chat_sessions` (`id`) ON DELETE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
