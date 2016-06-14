# ------------------------------------------------------------------------------
# Euro 2016 - Models
# ------------------------------------------------------------------------------

# Load data
source("./code/data_prep.R")

# Define features
col_ignore <-
  which(colnames(d_comb_final) %in%
          c("id",
            "home", "away",
            "h_ql_grp", "a_ql_grp",
            "h_grp", "a_grp",
            "goal_h", "goal_a", "goal_diff", "goal_total"))

features <- colnames(d_comb_final)[-col_ignore]
print(features)

# H2O
library(h2o)
library(h2oEnsemble)
h2o.init(nthreads = -1)

hex_data <- as.h2o(d_comb_final)

model <- h2o.deeplearning(x = features,
                 y = "goal_h",
                 activation = "RectifierWithDropout",
                 hidden = c(50, 100, 200),
                 epochs = 2000,
                 l1 = 1e-3,
                 l2 = 1e-3,
                 max_w2 = 10,
                 input_dropout_ratio = 0.05,
                 variable_importances = TRUE,
                 standardize = TRUE,
                 score_duty_cycle = 1,
                 score_training_samples = 0,
                 score_validation_samples = 0,
                 regression_stop = -1,
                 shuffle_training_data = TRUE,
                 #learn_rate = 0.01,
                 #ntrees = 10,
                 nfolds = 10,
                 seed = 1234,
                 training_frame = hex_data)
print(model)




print(h2o.varimp(model))

d_varimp <- as.data.frame(h2o.varimp(model))

yy <- as.data.frame(h2o.predict(model, hex_data))

d_comp <- data.frame(y = d_comb_final$goal_h, yy = yy)
plot(d_comp)

