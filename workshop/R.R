library(swat)
library(ggplot2)
library(GGally)
library(gridExtra)
library(Rcpp)

#Connect to the CAS Session
s <- CAS(hostname = "http://10.96.8.225/", 
         port = 8777, 
         username = "sasdemo", 
         password = "Orion123")

#Pull data in from SAS Server for R operations
sas_iris <- data.frame(
  to.casDataFrame(
    defCasTable(s, caslib = "public",tablename = "formatted_iris")))

# Run EDA [summary, box plot, correlation plots]
summary(sas_iris)
sl <- ggplot(sas_iris, aes(x=species, y=sepal_length, fill=species)) + 
  geom_boxplot()+
  labs(title="Plot of Measurement by Species",x="Species") + 
  scale_fill_brewer(palette="Dark2") + theme_classic()
sw <- ggplot(sas_iris, aes(x=species, y=sepal_width, fill=species)) + 
  geom_boxplot()+
  labs(title="Plot of Measurement by Species",x="Species") + 
  scale_fill_brewer(palette="Dark2") + theme_classic()
pl <- ggplot(sas_iris, aes(x=species, y=petal_length, fill=species)) + 
  geom_boxplot()+
  labs(title="Plot of Measurement by Species",x="Species") + 
  scale_fill_brewer(palette="Dark2") + theme_classic()
pw <- ggplot(sas_iris, aes(x=species, y=petal_width, fill=species)) + 
  geom_boxplot()+
  labs(title="Plot of Measurement by Species",x="Species") + 
  scale_fill_brewer(palette="Dark2") + theme_classic()

# Create the box plot
boxplot <- grid.arrange(sl,sw,pl,pw, ncol = 2)
boxplot
# Save the plot
png("boxplot.png")
plot(boxplot)
dev.off()

corr <- cor(sas_iris[,1:4])
round(corr,3)
corr_plot <- ggpairs(sas_iris, columns = 1:4, ggplot2::aes(colour=species)) 
png("corr_plot.png")
corr_plot
dev.off()

################################################
### Run Iris Classification on Data using R code
# K-Means Cluster
irisCluster <- kmeans(sas_iris[,1:4], centers=3, nstart = 20)
irisCluster$cluster <- as.factor(irisCluster$cluster)

# View Accuracy
table(irisCluster$cluster, sas_iris$Species)

# Plot in GGplot2
my_pal <- RColorBrewer::brewer.pal(n=3, name = "Dark2")
ggplot(sas_iris, aes(x = Sepal.Length, y = Sepal.Width, color = irisCluster$cluster, fill = irisCluster$cluster)) + 
  geom_jitter(size = 4, shape = 21) +
  theme_classic() +
  scale_color_manual(values=c(my_pal)) +
  scale_fill_manual(values=c(paste(my_pal, "66", sep = ""))) +
  ggtitle("Clustering Results Visualized in GGPlot2")

sas_iris$Rcluster <- irisCluster$cluster

#Save the results to the SAS Server
cas.upload.frame(s, sas_iris, casOut=list(caslib="public", name="iris_from_r", promote="true"))


################################################################
### Run Iris Classification on Data using R code and CAS Actions
# Decision Tree

# Load the sampling actionset
loadActionSet(s, 'sampling')
cas.sampling.srs(s,
                 table=list(caslib="public", name="iris_from_r"),
                 sampPct=70,
                 partind=TRUE,
                 output=list(casOut=list(name='temp_iris',replace=TRUE), copyvars='ALL'))
# Verify the partitioning
# Load the fedsql actionset
loadActionSet(s, 'fedsql')
# Create two CASTable instances
train <- defCasTable(s, 'temp_iris', where="_PartInd_=1") # 1
valid <- defCasTable(s, 'temp_iris', where="_PartInd_=0")
# Confirm that filtered rows show the same counts
cat("\n")
cat("Rows in training table:", nrow(train), "\n")
cat("Rows in validation table:", nrow(valid), "\n")

target = "species"
nominals = c("Sepal.Length", "Sepal.Width")
inputs = nominals

# Load the decsion tree actionset
loadActionSet(s, 'decisionTree')
# Train the decision tree model
cas.decisionTree.dtreeTrain(train,
                            target = target,
                            inputs = inputs,
                            nominals = nominals,
                            varImp = TRUE,
                            casOut = list(name = 'dt_model', replace = TRUE)
)
# Score the validation data
cas.decisionTree.dtreeScore(valid,
                            modelTable = list(name = 'dt_model'),
                            copyVars = list(target, '_PartInd_'),
                            assessonerow = TRUE,
                            casOut = list(name = 'dt_scored', replace = T)
)
# Assess the decision tree model
results <- cas.percentile.assess(s,
                                 table="dt_scored",
                                 inputs = c('_DT_P_ 1'),
                                 response = target,
                                 event = '1'
)


