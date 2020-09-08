library("tidyverse")
setwd("~/work/score_calculate/")

generalplot <- function(g,name){
    pdf(paste0("./pdf/",name,".pdf"))
    plot(g)
    dev.off()
    png(paste0("./png/",name,".png"),width = 480*2,height = 480*2)
    plot(g)
    dev.off()
}

rawdata <- read_csv("./result/scoreerr",col_names = FALSE)
score <- rawdata %>% rename(type = X2,score = X1) %>% mutate(type = as.factor(type))
summary <- score %>% nest(-type) %>%
    mutate(data = map(data,function(x)x %>% summarize(mean = mean(score),sd = sd(score)))) %>%
    unnest()

rawdata <- read_csv("./result/scoreout",col_names=FALSE)
result <- rawdata %>% rename(score = X1,pred=X2,which=X3)

g <- score %>% ggplot(mapping = aes(x = score,y = ..density..,fill = type)) + 
    geom_histogram(position="identity",alpha=0.5)

generalplot(g,"200Kscoutingscore")

g <- result %>% filter(which == "positive") %>% ggplot(mapping = aes(x = score,fill=pred)) +
    geom_histogram(position="identity",alpha=0.5)

generalplot(g,"200Kresult")

result <- result %>% mutate(is_pos = (pred == "true" & which == "positive") | (pred == "false" & which == "negative"))

g <- result %>% ggplot(mapping = aes(x = score,y = ..density..,fill = is_pos)) +
    geom_histogram(position = "identity",alpha=0.5)
generalplot(g,"200Ktestset_density")

result %>% nest(-is_pos) %>% mutate(data = map(data,function(x) x %>% summarize(mean = mean(score),sd = sd(score)))) %>% unnest()
