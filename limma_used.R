library(limma)
# source('https://bioconductor.org/biocLite.R')
# biocLite("edgeR")
library(edgeR)

path = 'C:/Users/FREEDOM/Desktop/TCGA_data/after_note2.csv'
path1 ='C:/Users/FREEDOM/Desktop/TCGA_data/group_text.csv'
express_rec <- read.csv(path,headers <- T)#��ȡ�������;
group_text <- read.csv(path1,headers <- T)#��ȡ�������

rownames(group_text) <- group_text[,1]
group_text <- group_text[c(-1)]

Group <- factor(group_text$group,levels = c('Tumor','Normal'))
design <- model.matrix(~0+Group)
colnames(design) <- c('Tumor','Normal')
rownames(design) <- rownames(group_text)#�����������

express_rec <- express_rec[,-1]
rownames(express_rec) <- express_rec[,1]
express_rec <- express_rec[(-1)]#�����������
express_rec[express_rec == 0] <- 1
express_rec <-log(express_rec,2)

fit <- lmFit(express_rec,design)

contrast.matrix <- makeContrasts(Tumor - Normal,levels=design)
fit2 <- contrasts.fit(fit,contrast.matrix)

fit2 <- eBayes(fit2)

all_diff <- topTable(fit2, adjust.method = 'fdr',coef=1,p.value = 1,lfc <- log(1,2),number = 30000,sort.by = 'logFC')#�Ӹߵ���������

dge <- DGEList(counts = express_rec)
dge <- calcNormFactors(dge)#���������б�׼����

v <- voom(dge, design,plot=TRUE)#����limma_voom�������в��������
fit <- lmFit(v, design)#���Թ�ϵ������
fit <- eBayes(fit)#��Ҷ˹�㷨�齨
all <- topTable(fit, coef=ncol(design),n=Inf)#�Ӹߵ���������
sig.limma <- subset(all_diff,abs(all$logFC)>1.5&all$P.Value<0.05)#���в������ɸѡ��
write.csv(sig.limma,'C:/Users/FREEDOM/Desktop/TCGA_data/limm_diff.csv')#д��csv�ļ��У�

write.csv(all,'C:/Users/FREEDOM/Desktop/TCGA_data/limm_rec.csv')


all <- read.csv('C:/Users/FREEDOM/Desktop/TCGA_data/limm_rec.csv')

colnames(all)[1] <- c('name')
#���ƻ�ɽͼ��
library(ggplot2)#���ػ�ɽͼ����
library(ggrepel)

rank_data <- all[order(all[,5]),]#��������pvalue��С��������
rownames(rank_data) <-rank_data[,1]
rank_data <- rank_data[c(-1)]
rank_data$names <- rownames(rank_data)
volcano_names <- rownames(rank_data)[1:5]#ȡpvalue��С���������

rank_data$ID2 <- ifelse((rank_data$names %in% volcano_names)&abs(rank_data$logFC)>3
    ,as.character(rank_data$names),NA)#�ھ���res_data�����д���һ���ĵ��У���������|log2folchange|����3 �Ļ����������򱣴�ΪNA��
png(file="C:/Users/FREEDOM/Desktop/TCGA_data/limma_voloun_log1.png", bg="transparent")#�ȴ���һ��ͼƬ
boundary = ceiling(max(abs(rank_data$logFC)))#ȷ��x��ı߽磻
threshold <- ifelse(rank_data$P.Value<0.05,ifelse(rank_data$logFC >=3,'UP',ifelse(rank_data$logFC<=(-3),'DW','NoDIFF')),'NoDIFF')#���÷ֽ緧ֵ
ggplot(rank_data,aes(x=rank_data$logFC,y =(-1)*log10(rank_data$P.Value),color=threshold),abline(v=c(-log(1.5,2),log(1.5,2))),h =-log10(0.05))+geom_point(size=1, alpha=0.5) + theme_classic() +
  xlab('log2 fold_change')+ylab(' -log10 p-value') +xlim(-1 * boundary, boundary) + theme(legend.position="top", legend.title=element_blank())  + geom_text_repel(aes(label=rank_data$ID2))#��ɽͼ���ı���ǩ��ע��
dev.off()#�����ɽͼͼƬ��






