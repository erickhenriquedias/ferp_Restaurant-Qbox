-- ===============================================
-- FERP Restaurant System - Database Schema Only
-- ===============================================

-- Create restaurants table
CREATE TABLE IF NOT EXISTS `restaurants` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `restaurant_id` varchar(50) NOT NULL,
    `foods` longtext DEFAULT '[]',
    `toys` longtext DEFAULT '[]',
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    UNIQUE KEY `restaurant_id` (`restaurant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Create restaurant_food_items table
CREATE TABLE IF NOT EXISTS `restaurant_food_items` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `restaurant_id` varchar(50) NOT NULL,
    `name` varchar(100) NOT NULL,
    `description` varchar(255) DEFAULT NULL,
    `image_url` varchar(512) DEFAULT NULL,
    `food_type` enum('main','side','dessert','drink') NOT NULL DEFAULT 'main',
    `ingredients` text DEFAULT NULL,
    `active` tinyint(1) DEFAULT 1,
    `created_at` timestamp DEFAULT CURRENT_TIMESTAMP,
    `updated_at` timestamp DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`),
    KEY `restaurant_id` (`restaurant_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

-- Insert default restaurant data
INSERT IGNORE INTO `restaurants` (`restaurant_id`, `foods`, `toys`) VALUES
('burger_shot', '[]', '[]'),
('uwu_cafe', '[]', '[]'),
('rooster', '[]', '[]');


-- Example balanced food items for each restaurant (no premium multipliers)
INSERT IGNORE INTO `restaurant_food_items` (`restaurant_id`, `name`, `description`, `image_url`, `food_type`, `ingredients`, `active`) VALUES
-- Burger Shot Items
('burger_shot', 'Classic Burger', 'Hambúrguer clássico com proteína e vegetais', 'https://i.imgur.com/food1.png', 'main', '["beef","cheese","lettuce","bread"]', 1),
('burger_shot', 'Double Burger', 'Hambúrguer duplo com múltiplas proteínas', 'https://i.imgur.com/double_burger.png', 'main', '["beef","beef","lettuce","tomato","cheese"]', 1),
('burger_shot', 'French Fries', 'Batata frita tradicional', 'https://i.imgur.com/food2.png', 'side', '["potato","oil","salt"]', 1),
('burger_shot', 'Seasoned Fries', 'Batata frita temperada', 'https://i.imgur.com/seasoned_fries.png', 'side', '["potato","oil","salt","pepper","herbs"]', 1),
('burger_shot', 'Milkshake', 'Milkshake cremoso', 'https://i.imgur.com/food3.png', 'drink', '["milk","sugar","vanilla","cream"]', 1),

-- UwU Cafe Items
('uwu_cafe', 'Cat Latte', 'Café com arte de gato', 'https://i.imgur.com/cat_latte.png', 'drink', '["milk","sugar","cream"]', 1),
('uwu_cafe', 'Cheesecake', 'Cheesecake cremoso tradicional', 'https://i.imgur.com/cheesecake.png', 'dessert', '["cheese","eggs","sugar","vanilla"]', 1),
('uwu_cafe', 'Veggie Bowl', 'Tigela saudável com vegetais', 'https://i.imgur.com/veggie_bowl.png', 'side', '["broccoli","spinach","carrot","lettuce","tomato"]', 1),
('uwu_cafe', 'Hot Chocolate', 'Chocolate quente reconfortante', 'https://i.imgur.com/hot_choc.png', 'drink', '["milk","sugar","vanilla","cream"]', 1),
('uwu_cafe', 'Energy Cookie', 'Biscoito energético', 'https://i.imgur.com/energy_cookie.png', 'dessert', '["sugar","honey","vanilla","yeast"]', 1),

-- Rooster's Rest Items
('rooster', 'Fish Appetizer', 'Aperitivo de peixe fresco', 'https://i.imgur.com/fish_app.png', 'side', '["fish","bread","herbs","lemon"]', 1),
('rooster', 'Steak Dinner', 'Jantar de bife com vegetais', 'https://i.imgur.com/steak_dinner.png', 'main', '["beef","garlic","herbs","butter","broccoli","carrot"]', 1),
('rooster', 'Pasta Special', 'Massa especial com temperos', 'https://i.imgur.com/pasta_special.png', 'main', '["pasta","garlic","herbs","cheese","tomato"]', 1),
('rooster', 'Honey Carrots', 'Cenouras glaceadas com mel', 'https://i.imgur.com/honey_carrots.png', 'side', '["carrot","honey","butter"]', 1),
('rooster', 'Seasoned Rice', 'Arroz temperado especial', 'https://i.imgur.com/seasoned_rice.png', 'side', '["rice","garlic","herbs","spices"]', 1);

