library(swat)
library(ggplot2)
library(cowplot)
library(caret)

################
### SWAT Example
# Connect to the CAS Session
s <- CAS(hostname = "http://10.96.11.102/", 
         port = 8777, 
         username = "sasdemo", 
         password = "Orion123")

#Pull data in from SAS Server for R operations
sas_iris <- data.frame(
  to.casDataFrame(
    defCasTable(s, caslib = "open_source_iris",tablename = "Iris")))

################################################
### Run Iris Classification on Data using R code
# K-Means Cluster
irisCluster <- kmeans(sas_iris[,1:4], centers=3, nstart = 20)
irisCluster$cluster <- as.factor(irisCluster$cluster)

# View Accuracy
table(irisCluster$cluster, sas_iris$Species)

# Plot in GGplot2
my_pal <- RColorBrewer::brewer.pal(n=3, name = "Dark2")
Sepals <- ggplot(sas_iris, aes(x = Sepal_Length, y = Sepal_Width, color = irisCluster$cluster, fill = irisCluster$cluster)) + 
  geom_jitter(shape = 21, size = 4) +
  theme_classic() +
  scale_color_manual(values=c(my_pal)) +
  scale_fill_manual(values=c(paste(my_pal, "66", sep = ""))) +
  ggtitle("Sepal Dimensions by Cluster") +
  theme(legend.position = "none")
Petals <- ggplot(sas_iris, aes(x = Petal_Length, y = Petal_Width, color = irisCluster$cluster, fill = irisCluster$cluster)) + 
  geom_jitter(shape = 21, size = 4) +
  theme_classic() +
  scale_color_manual(values=c(my_pal)) +
  scale_fill_manual(values=c(paste(my_pal, "66", sep = ""))) +
  ggtitle("Petal Dimensions by Cluster") +
  theme(legend.position = "none")
Combined <- plot_grid(Sepals, Petals, labels = "", align = "h")
Combined

png("clusterPlot.png")
plot(Combined)
dev.off()


sas_iris$Rcluster <- irisCluster$cluster
sas_iris$R_RunTime <- Sys.time()

# Save the results to the SAS Server
cas.table.dropTable(s, name = "iris_from_r",
                    caslib = "open_source_iris",
                    quiet = T)
cas.upload.frame(s, sas_iris, casOut=list(caslib="open_source_iris", name="iris_from_r", promote="true"))


################################################################
### Run Iris Classification on Data using R code and CAS Actions
# Decision Tree

# Load the sampling actionset from CAS
loadActionSet(s, 'sampling')
cas.sampling.srs(s,
                 table=list(caslib="open_source_iris", name="iris"),
                 sampPct=70,
                 partind=TRUE,
                 output=list(casOut=list(name='temp_iris',replace=TRUE), copyvars='ALL'))

# Verify the partitioning
# Load the fedsql actionset
loadActionSet(s, 'fedsql')
# Create two CASTable instance and references using SQL filters
train <- defCasTable(s, 'temp_iris', where="_PartInd_=1")
valid <- defCasTable(s, 'temp_iris', where="_PartInd_=0")
# Confirm that filtered rows show the same counts

cat("Rows in training table:", nrow(train), "\n")
cat("Rows in validation table:", nrow(valid), "\n")

target <- "species"
nominals = c("Sepal_Length", "Sepal_Width", "Petal_Length", "Petal_Width")
inputs = nominals

# Load the decsion tree actionset
loadActionSet(s, 'decisionTree')
# Train the decision tree model
cas.decisionTree.dtreeTrain(train,
                            target = target,
                            inputs = inputs,
                            nominals = nominals,
                            varImp = TRUE,
                            casOut = list(name = 'dt_model', replace = T)
)
# Score the validation data
cas.decisionTree.dtreeScore(valid,
                            modelTable = list(name = 'dt_model'),
                            copyVars = list(target, '_PartInd_'),
                            assessonerow = TRUE,
                            casOut = list(name = 'dt_scored', replace = T)
)

################################################################
### Create model in R to be duplicated in Viya VDMML
sas_iris_train <- data.frame(
  to.casDataFrame(
    defCasTable(s, 'temp_iris', where="_PartInd_=1")))
sas_iris_validate <- data.frame(
  to.casDataFrame(
    defCasTable(s, 'temp_iris', where="_PartInd_=0")))


library(randomForest)
data_train <- sas_iris_train
data_full <- sas_iris
model_parameter <- as.factor(Species) ~ Sepal_Length + Sepal_Width + Petal_Length + Petal_Width 

# RandomForest
dm_model <- randomForest(model_parameter, ntree=100, mtry=4, data=data_train, importance=TRUE)

# Score
pred <- predict(dm_model, data_full, type="prob")
dm_scoreddf <- data.frame(pred)
colnames(dm_scoreddf) <- c("P_Speciessetosa", "P_Speciesversic", "P_Speciesvirgin")



