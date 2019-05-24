-- phpMyAdmin SQL Dump
-- version 4.8.3
-- https://www.phpmyadmin.net/
--
-- Хост: localhost
-- Время создания: Май 24 2019 г., 12:13
-- Версия сервера: 8.0.12
-- Версия PHP: 7.2.11

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
SET AUTOCOMMIT = 0;
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- База данных: `orionrpg`
--

-- --------------------------------------------------------

--
-- Структура таблицы `users`
--

CREATE TABLE `users` (
  `id` int(11) NOT NULL,
  `name` varchar(24) NOT NULL,
  `password` varchar(30) CHARACTER SET cp1251 COLLATE cp1251_general_ci NOT NULL,
  `email` varchar(32) CHARACTER SET cp1251 COLLATE cp1251_general_ci NOT NULL DEFAULT '-',
  `referal` varchar(24) NOT NULL DEFAULT '-',
  `gender` tinyint(1) NOT NULL DEFAULT '0',
  `character` smallint(3) NOT NULL DEFAULT '23',
  `money` int(11) NOT NULL DEFAULT '20000',
  `bankmoney` int(11) NOT NULL DEFAULT '75000',
  `dateofregister` varchar(10) NOT NULL DEFAULT '01.01.1970',
  `lastpos` varchar(50) NOT NULL DEFAULT '0.0|0.0|0.0|0.0|0|0'
) ENGINE=InnoDB DEFAULT CHARSET=cp1251;

--
-- Дамп данных таблицы `users`
--

INSERT INTO `users` (`id`, `name`, `password`, `email`, `referal`, `gender`, `character`, `money`, `bankmoney`, `dateofregister`, `lastpos`) VALUES
(1, 'd1maz.', '123456', 'admin@d1maz.ru', '', 1, 23, 20000, 75000, '25.4.2019', '0.0|0.0|0.0|0.0|0|0');

--
-- Индексы сохранённых таблиц
--

--
-- Индексы таблицы `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`id`);

--
-- AUTO_INCREMENT для сохранённых таблиц
--

--
-- AUTO_INCREMENT для таблицы `users`
--
ALTER TABLE `users`
  MODIFY `id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=2;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
