# ------------------------------------------------------------------------------
# Euro 2016 - Data Preparation
# ------------------------------------------------------------------------------

# Load CSV
library(data.table)
d_team <- fread("./input/team_data.csv", stringsAsFactors = TRUE)
d_match <- fread("./input/match_data.csv", stringsAsFactors = TRUE)

# Merge Home Team Stats
d_home <- d_match[, c(2,3), with = FALSE]
colnames(d_home) <- c("id", "team")
d_home <- merge(d_home, d_team, by = "team")
colnames(d_home) <- c("home", "id", paste0("h_", colnames(d_team)[-1]))

# Merge Away Team Stats
d_away <- d_match[, c(2,4), with = FALSE]
colnames(d_away) <- c("id", "team")
d_away <- merge(d_away, d_team, by = "team")
colnames(d_away) <- c("away", "id", paste0("a_", colnames(d_team)[-1]))

# Merge by match ID
d_comb <- merge(d_home, d_away, by = "id")

# Merge odds, kickoff.ai and targets
d_comb <- merge(d_comb, d_match[, c(2, 5:ncol(d_match)), with = F], by = "id")

# Convert to normal df
d_comb <- as.data.frame(d_comb)

# Add a Reverse version (i.e. flip home/away as they are not truly home/away)
d_rev_left <- d_comb[, 2:30]
d_rev_right <- d_comb[, 31:59]
d_match_rev <- d_match[, c("odds_a", "odds_d", "odds_h",
                           "koai_a", "koai_h",
                           "goal_a", "goal_h"),
                       with = FALSE]
d_comb_rev <- data.frame(id = d_comb$id,
                         d_rev_right, d_rev_left, d_match_rev)
colnames(d_comb_rev) <- colnames(d_comb)

# Combine
d_comb_final <- rbind(d_comb, d_comb_rev)

# Add more targets
d_comb_final$goal_diff <- d_comb_final$goal_h - d_comb_final$goal_a
d_comb_final$goal_total <- d_comb_final$goal_h + d_comb_final$goal_a

# Clean up
rm(d_away, d_home, d_comb, d_comb_rev, d_match, d_match_rev,
   d_rev_left, d_rev_right, d_team)

