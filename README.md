# SQL Project

# 🎧 Podcast Listening Behavior Analytics

## 🔍 Overview
This advanced SQL project analyzes how different age groups engage with podcasts across genres. By simulating user behavior and applying analytical queries, it uncovers trends in retention, binge behavior, and genre preferences.

## 🧠 Objectives
- Identify top genres per demographic
- Measure listener retention per episode
- Detect low engagement patterns
- Rank genre loyalty using window functions
- Build automated recommendations and alerts

## 🗃️ Schema
Relational tables include:
- `users` — demographics & subscription
- `podcasts` — genre & duration
- `episodes` — linked to podcasts
- `listening_sessions` — user activity logs

## 🧩 SQL Features Used
| Feature              | Used For                                                   |
|----------------------|------------------------------------------------------------|
| ✅ Window Functions   | Rank listeners, detect engagement trends                   |
| ✅ CTEs               | Data transformation and episode ladders                    |
| ✅ Views              | Monthly performance tracking                               |
| ✅ Triggers           | Logging low engagement listeners                           |
| ✅ Stored Procedures  | Dynamic recommendations based on user traits              |

## 📊 Sample Query: Listener Retention

```sql
SELECT 
    e.title,
    e.duration_minutes,
    ROUND(AVG(TIMESTAMPDIFF(MINUTE, ls.start_time, ls.end_time)), 2) AS actual_listening,
    ROUND((AVG(TIMESTAMPDIFF(MINUTE, ls.start_time, ls.end_time)) / e.duration_minutes) * 100, 2) AS retention_percent
FROM listening_sessions ls
JOIN episodes e ON ls.episode_id = e.episode_id
GROUP BY e.title, e.duration_minutes;
```

## 💡 Insights Discovered
- Comedy has highest retention among 18–25 group

- Listeners on free plans tend to rate content lower overall

- True Crime episodes show longer average session durations

- Low engagement spikes around episodes longer than 55 minutes


