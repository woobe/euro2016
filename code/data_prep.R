# ------------------------------------------------------------------------------
# Euro 2016 - Data Preparation
# ------------------------------------------------------------------------------

library(data.table)

# Load CSV
d_team <- fread("./input/team_data.csv")
d_match <- fread("./input/match_data.csv")

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

