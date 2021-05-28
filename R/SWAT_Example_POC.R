#install.packages('swat','/opt/anaconda3/lib/R/library/')
#install.packages('https://github.com/sassoftware/R-swat/releases/download/vX.X.X/R-swat-X.X.X-platform.tar.gz',
#                 repos=NULL, type='file')

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

# Plot in GGplot2
my_pal <- RColorBrewer::brewer.pal(n=3, name = "Dark2")
Sepals <- ggplot(sas_iris, aes(x = Sepal_Length, y = Sepal_Width, color = irisCluster$cluster, fill = irisCluster$cluster)) + 
  geom_jitter(shape = 21, size = 4) +
  theme_classic() +
  scale_color_manual(values=c(my_pal)) +
  scale_fill_manual(values=c(paste(my_pal, "66", sep = ""))) +
  ggtitle("Sepal Dimensions by Cluster", subtitle = Sys.time()) +
  theme(legend.position = "none")
Petals <- ggplot(sas_iris, aes(x = Petal_Length, y = Petal_Width, color = irisCluster$cluster, fill = irisCluster$cluster)) + 
  geom_jitter(shape = 21, size = 4) +
  theme_classic() +
  scale_color_manual(values=c(my_pal)) +
  scale_fill_manual(values=c(paste(my_pal, "66", sep = ""))) +
  ggtitle("Petal Dimensions by Cluster", subtitle = Sys.time()) +
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
