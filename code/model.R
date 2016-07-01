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
targets <- c("goal_h", "goal_a", "goal_diff", "goal_total")

# d_comb_final$goal_h <- as.factor(d_comb_final$goal_h)
# d_comb_final$goal_a <- as.factor(d_comb_final$goal_a)
# d_comb_final$goal_diff <- as.factor(d_comb_final$goal_diff)
# d_comb_final$goal_total <- as.factor(d_comb_final$goal_total)

# Split train / test
row_train <- which(d_comb_final$id <= 46) # <----------------- change this!!!
d_train <- d_comb_final[row_train,]
d_test <- d_comb_final[-row_train,]
rm(d_comb_final)


# H2O
library(h2o)
library(h2oEnsemble)
h2o.init(nthreads = -1)
h2o.removeAll()

# Convert
hex_train <- as.h2o(d_train)
hex_test <- as.h2o(d_test)

# Set up
learner <- c("h2o.glm.wrapper", "h2o.randomForest.wrapper",
             "h2o.gbm.wrapper", "h2o.deeplearning.wrapper")
metalearner <- "h2o.glm.wrapper"
n_folds <- 20

# Build ensembles for each target
for (n_target in 1) {

  dnn_1 <- h2o.deeplearning(x = features,
                            y = targets[n_target],
                            training_frame = hex_train,
                            activation = "RectifierWithDropout",
                            hidden = c(100, 100, 100),
                            epochs = 500,
                            l1 = 1e-7,
                            l2 = 1e-7,
                            max_w2 = 10,
                            input_dropout_ratio = 0.05,
                            standardize = TRUE,
                            seed = 1234,
                            nfolds = n_folds,
                            fold_assignment = "Modulo",
                            keep_cross_validation_predictions = TRUE)

  gbm_1 <- h2o.gbm(x = features,
                   y = targets[n_target],
                   training_frame = hex_train,
                   learn_rate = 0.01,
                   ntrees = 1000,
                   seed = 1234,
                   nfolds = n_folds,
                   fold_assignment = "Modulo",
                   keep_cross_validation_predictions = TRUE)

  drf_1 <- h2o.randomForest(x = features,
                            y = targets[n_target],
                            training_frame = hex_train,
                            ntrees = 1000,
                            seed = 1234,
                            nfolds = n_folds,
                            fold_assignment = "Modulo",
                            keep_cross_validation_predictions = TRUE)

  glm_1 <- h2o.glm(x = features,
                   y = targets[n_target],
                   training_frame = hex_train,
                   nfolds = n_folds,
                   fold_assignment = "Modulo",
                   keep_cross_validation_predictions = TRUE)

  models <- list(dnn_1, gbm_1, drf_1, glm_1)

  stack <- h2o.stack(models = models,
                     response_frame = hex_train[, targets[n_target]],
                     metalearner = metalearner,
                     seed = 1234,
                     keep_levelone_data = TRUE)

  perf <- h2o.ensemble_performance(stack, newdata = hex_test)
  print(perf)

  yy_test <- predict(stack, hex_test)



}





d_varimp <- as.data.frame(h2o.varimp(model))

yy <- as.data.frame(h2o.predict(model, hex_data))

d_comp <- data.frame(y = d_comb_final$goal_h, yy = yy)
plot(d_comp)

