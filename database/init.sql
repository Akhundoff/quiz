-- Initial database setup
USE quiz_system;

-- Create tables (they will be created by TypeORM, but this ensures the database exists)

-- Insert sample questions
INSERT INTO questions (text, type, options, required, order_number, is_active) VALUES
                                                                                   ('Xidmətimizlə nə qədər məmnunsunuz?', 'radio', '["Çox məmnunam", "Məmnunam", "Neytral", "Məmnun deyiləm", "Çox məmnun deyiləm"]', true, 1, true),
                                                                                   ('Hansı xidmətlərimizdən istifadə edirsiniz?', 'checkbox', '["Veb sayt", "Mobil tətbiq", "API", "Dəstək xidməti", "Konsaltinq"]', true, 2, true),
                                                                                   ('Bizə əlavə rəy və təklifləriniz var?', 'text', null, false, 3, true),
                                                                                   ('Yaşınız hansı aralıqda?', 'radio', '["18-25", "26-35", "36-45", "46-55", "55+"]', false, 4, true),
                                                                                   ('Xidmətimizi dostlarınıza tövsiyə edərdiniz?', 'radio', '["Mütləq", "Çox güman ki bəli", "Əmin deyiləm", "Çox güman ki xeyr", "Heç vaxt"]', true, 5, true);

-- Insert default admin user (password: admin123)
-- Password hash for 'admin123' using bcrypt
INSERT INTO admin_users (username, password_hash) VALUES
    ('admin', '$2b$10$rKvK1/8XvJxJxJxJxJxJxeOq7gHmWFg1TqO7HNQ8q9k6yX8aF9G0a')
    ON DUPLICATE KEY UPDATE password_hash = password_hash;