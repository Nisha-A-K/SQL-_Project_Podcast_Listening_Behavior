create database podcast;
use podcast;

-- Users with index on age_group for faster grouping
CREATE TABLE users (
    user_id INT PRIMARY KEY,
    name VARCHAR(50),
    age_group VARCHAR(20),
    subscription_status VARCHAR(10),
    INDEX (age_group)
);

-- Podcasts with genre indexing
CREATE TABLE podcasts (
    podcast_id INT PRIMARY KEY,
    title VARCHAR(100),
    genre VARCHAR(50),
    duration_minutes INT,
    release_date DATE,
    INDEX (genre)
);

-- Episodes Table
CREATE TABLE episodes (
    episode_id INT PRIMARY KEY,
    podcast_id INT,
    title VARCHAR(100),
    duration_minutes INT,
    release_date DATE,
    FOREIGN KEY (podcast_id) REFERENCES podcasts(podcast_id),
    INDEX (podcast_id)
);


-- Listening Sessions with foreign keys and ratings
CREATE TABLE listening_sessions (
    session_id INT PRIMARY KEY,
    user_id INT,
    episode_id INT,
    start_time DATETIME,
    end_time DATETIME,
    rating INT CHECK (rating BETWEEN 1 AND 5),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (episode_id) REFERENCES episodes(episode_id)
);

INSERT INTO users (user_id, name, age_group, subscription_status) VALUES
(1, 'Aarav', '18-25', 'Premium'),
(2, 'Diya', '26-35', 'Free'),
(3, 'Karan', '26-35', 'Premium'),
(4, 'Maya', '36-50', 'Premium'),
(5, 'Rohan', '18-25', 'Free');

INSERT INTO podcasts (podcast_id, title, genre, duration_minutes, release_date) VALUES
(101, 'MindBuzz', 'Mental Health', 45, '2024-05-10'),
(102, 'LaughTrack', 'Comedy', 30, '2023-12-01'),
(103, 'DarkFiles', 'True Crime', 60, '2024-03-15'),
(104, 'TechTonic', 'Technology', 50, '2024-07-20'),
(105, 'SpokenVerse', 'Storytelling', 40, '2024-04-08');

INSERT INTO episodes (episode_id, podcast_id, title, duration_minutes, release_date) VALUES
(1001, 101, 'Finding Calm', 45, '2024-05-10'),
(1002, 102, 'Jokes & Giggles', 30, '2023-12-01'),
(1003, 103, 'Case X', 60, '2024-03-15'),
(1004, 104, 'AI & the Future', 50, '2024-07-20'),
(1005, 105, 'The Lost Voice', 40, '2024-04-08');

INSERT INTO listening_sessions (session_id, user_id, episode_id, start_time, end_time, rating) VALUES
(5008, 1, 1001, '2025-07-01 10:00:00', '2025-07-01 10:45:00', 5),
(5009, 2, 1002, '2025-07-02 21:00:00', '2025-07-02 21:30:00', 3),
(5010, 3, 1003, '2025-07-03 19:00:00', '2025-07-03 20:00:00', 4),
(5011, 4, 1004, '2025-07-03 07:30:00', '2025-07-03 08:15:00', 5),
(5012, 5, 1005, '2025-07-04 22:00:00', '2025-07-04 22:40:00', 2),
(5013, 1, 1002, '2025-07-05 10:15:00', '2025-07-05 10:45:00', 4),
(5014, 3, 1005, '2025-07-06 12:30:00', '2025-07-06 13:10:00', 3);

DELETE FROM listening_sessions WHERE session_id = 5001;

-- 1. Top Genres by Age Group 
SELECT 
    u.age_group,
    p.genre,
    COUNT(*) AS listen_count
FROM listening_sessions ls
JOIN users u ON ls.user_id = u.user_id
JOIN episodes e ON ls.episode_id = e.episode_id
JOIN podcasts p ON e.podcast_id = p.podcast_id
GROUP BY u.age_group, p.genre
ORDER BY listen_count DESC;

-- 2. Listener Retention by Episode
SELECT 
    e.title,
    e.duration_minutes,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, ls.start_time, ls.end_time)), 2) AS actual_listening,
    ROUND((AVG(TIMESTAMPDIFF(MINUTE, ls.start_time, ls.end_time)) / e.duration_minutes) * 100, 2) AS retention_percent
FROM listening_sessions ls
JOIN episodes e ON ls.episode_id = e.episode_id
GROUP BY e.title, e.duration_minutes
ORDER BY retention_percent DESC;

-- 📅 3. Monthly Listening Trends View
CREATE VIEW monthly_listening_trends AS
SELECT 
    u.age_group,
    DATE_FORMAT(ls.start_time, '%Y-%m') AS month,
    COUNT(*) AS sessions,
    AVG(ls.rating) AS avg_rating
FROM listening_sessions ls
JOIN users u ON ls.user_id = u.user_id
GROUP BY u.age_group, month;

-- 🧠 4. Stored Procedure: Recommend Top Genres
DELIMITER $$

CREATE PROCEDURE recommend_top_genres(IN input_age_group VARCHAR(20))
BEGIN
    SELECT p.genre, COUNT(*) AS popularity
    FROM listening_sessions ls
    JOIN users u ON ls.user_id = u.user_id
    JOIN episodes e ON ls.episode_id = e.episode_id
    JOIN podcasts p ON e.podcast_id = p.podcast_id
    WHERE u.age_group = input_age_group
    GROUP BY p.genre
    ORDER BY popularity DESC
    LIMIT 3;
END $$

DELIMITER ;

-- 🚨 5. Trigger: Detect Low Engagement
CREATE TABLE low_engagement_log (
    log_id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    episode_id INT,
    engagement_percent DECIMAL(5,2),
    log_time TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

DELIMITER $$

CREATE TRIGGER log_low_engagement
AFTER INSERT ON listening_sessions
FOR EACH ROW
BEGIN
    DECLARE duration INT;
    DECLARE listened INT;
    DECLARE percent DECIMAL(5,2);

    SELECT duration_minutes INTO duration FROM episodes WHERE episode_id = NEW.episode_id;
    SET listened = TIMESTAMPDIFF(MINUTE, NEW.start_time, NEW.end_time);
    SET percent = (listened / duration) * 100;

    IF percent < 50 THEN
        INSERT INTO low_engagement_log (user_id, episode_id, engagement_percent)
        VALUES (NEW.user_id, NEW.episode_id, percent);
    END IF;
END $$

DELIMITER ;

-- 🎧 6. Identify Most Engaged Listeners per Genre
SELECT 
    sub.user_id,
    sub.genre,
    sub.genre_listens,
    RANK() OVER (PARTITION BY sub.genre ORDER BY sub.genre_listens DESC) AS genre_rank
FROM (
    SELECT 
        u.user_id,
        p.genre,
        COUNT(*) AS genre_listens
    FROM listening_sessions ls
    JOIN users u ON ls.user_id = u.user_id
    JOIN episodes e ON ls.episode_id = e.episode_id
    JOIN podcasts p ON e.podcast_id = p.podcast_id
    GROUP BY u.user_id, p.genre
) AS sub;

-- 🔁 7. Compare Session Durations with LEAD/LAG
SELECT 
    user_id,
    session_id,
    TIMESTAMPDIFF(MINUTE, start_time, end_time) AS session_duration,
    LAG(session_id) OVER (PARTITION BY user_id ORDER BY start_time) AS prev_session,
    LEAD(session_id) OVER (PARTITION BY user_id ORDER BY start_time) AS next_session
FROM listening_sessions;

-- 📈 8. Rolling Average Rating per Genre
SELECT 
    p.genre,
    ls.rating,
    AVG(ls.rating) OVER (PARTITION BY p.genre ORDER BY ls.start_time ROWS BETWEEN 2 PRECEDING AND CURRENT ROW) AS rolling_avg_rating
FROM listening_sessions ls
JOIN episodes e ON ls.episode_id = e.episode_id
JOIN podcasts p ON e.podcast_id = p.podcast_id;






