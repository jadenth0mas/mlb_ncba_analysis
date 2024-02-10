library(tidyverse)
library(MASS)
library(verification)
library(e1071)
library(class)
library(neuralnet)

set.seed(2024)

mlb_2023 <- read_csv("mlbBaseballPlayers_2023.csv")
club_2024 <- read_csv("clubBaseballPlayers_2024.csv")

club_2024 <- club_2024 %>% 
  mutate(Age=(year(Sys.Date())-year(as.Date(paste0("01/", club_2024$DOB), format="%d/%m/%Y"))),
         POS=str_split_i(POS, pattern=" / ", i=1)) %>% 
  rename(BAT=Bats, THW=Throws)

full <- bind_rows(mlb_2023, club_2024)

sub <- full %>% dplyr::select(fname, lname, Age, HT, WT, city, state, POS, Team, League) %>% 
  mutate(League=as.factor(League)) %>% mutate(MLB=(League=="MLB"))


ggplot(sub, aes(x=WT, y=HT)) +
  geom_point(aes(color=League))

summary(sub)
sub %>% group_by(League) %>% summarise(mean(HT), mean(WT), mean(Age))

sub %>% ggplot(aes(x=Age, y=League)) +
  geom_boxplot()
sub %>% ggplot(aes(x=HT, y=League)) +
  geom_boxplot()
sub %>% ggplot(aes(x=WT, y=League)) +
  geom_boxplot()

train <- sample(c(TRUE, FALSE), nrow(sub), replace=T, prob=c(0.7, 0.3))
sub.train <- sub[train,]
sub.test <- sub[!train,]
Y.test <- sub.test$MLB


# Logisitc Regression
m.fit <- glm(MLB~HT+WT, data=sub.train, family="binomial")
summary(m.fit)
m.probs <- predict(m.fit, sub.test, type="response")
m.pred <- rep(F, length(m.probs))
m.pred[m.probs>.5] <- T
table(m.pred, Y.test)
mean(m.pred==Y.test)
plot(m.fit)

# LDA
lda.fit <- lda(MLB~HT+WT, data=sub.train)
lda.fit
plot(lda.fit)
lda.pred <- predict(lda.fit, sub.test)
table(lda.pred$class, Y.test)
mean(lda.pred$class==Y.test)


# QDA
qda.fit <- qda(MLB~HT+WT, data=sub.train)
qda.fit
qda.pred <- predict(qda.fit, sub.test)
table(qda.pred$class, Y.test)
mean(qda.pred$class==Y.test)

# Naive Bayes
nb.fit <- naiveBayes(MLB~HT+WT, data=sub.train)
nb.pred <- predict(nb.fit, sub.test)
table(nb.pred, Y.test)
mean(nb.pred==Y.test)

# KNN
train.mtx <- sub.train %>% dplyr::select(HT, WT) %>% as.matrix()
test.mtx <- sub.test %>% dplyr::select(HT, WT) %>% as.matrix()
cl.mtx <- as.matrix(sub.train$MLB)


percs <- c()
j <- 1
for (i in seq(from=3, to=9, by=2)) {
  knn.pred <- knn(train.mtx, test.mtx, cl.mtx, k=i)
  table(knn.pred, Y.test)
  percs[j] <- mean(knn.pred==Y.test)
  j <- j+1
}
which.max(percs)


svm.fit <- svm(factor(MLB)~HT+WT, data=sub.train)
svm.fit
svm.predict <- predict(svm.fit, sub.test[,c("HT", "WT")])
table(svm.predict, Y.test)
mean(svm.predict==Y.test)


# Neural Network
nn.fit <- neuralnet(MLB~HT+WT, data=sub.train, hidden=c(2, 2), threshold=0.05)
nn.pred <- rep(F, length(Y.test))
nn.prob <- predict(nn.fit, newdata=sub.test)
nn.pred[nn.prob>0.5] <- T
table(nn.pred, Y.test)
mean(nn.pred==Y.test)


# Log regression ROC
roc.plot(x=as.numeric(Y.test), pred=as.numeric(m.pred), main="ROC curve for MLB Classifcation")

# LDA ROC
roc.plot(x=as.numeric(Y.test), pred=as.numeric(lda.pred$class), main="ROC curve for LDA")

# QDA ROC
roc.plot(as.numeric(Y.test), as.numeric(qda.pred$class), main="ROC curve for QDA")

# NB ROC
roc.plot(as.numeric(Y.test), as.numeric(nb.pred), main="ROC curve for NB")

# KNN ROC
roc.plot(as.numeric(Y.test), as.numeric(knn.pred), main="ROC curve for KNN")

# NN ROC
roc.plot(as.numeric(Y.test), as.numeric(nn.pred), main="ROC Curve for NN")
