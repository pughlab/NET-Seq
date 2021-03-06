library(taRifx) #remove.factors
library(scales)
library(ltm)
library(plyr)
require(gglogo)

###################
#### FUNCTIONS ####
mutColours <- function(){
 list("INS"="#82CABC",
      "DEL"="#F56A68",
      "NON"="#157F7D",
      "MIS"="#72A3C5",
      "SPLICE"="#F1A85B",
      "START"="#F1A85B",
      "NA"="white") 
}

lohColours <- function(){
  c("0"=alpha('white', 0),
    "1"='dodgerblue',
    "2"='#1b9e77',
    "3"='red',
    "4"='#489C47')
}

transColours <- function(){
  c("positive"="#ABDAE3",
    "random"="#AFACB2",
    "negative"="#FFC86E")
}

log2Cols <- function(min.l2=-2, max.l2=2){
  crp.lvl <- seq(min.l2, max.l2, by=0.1)
  crp <- colorRampPalette(c("blue", "white", "red"))(length(crp.lvl))
  names(crp) <- crp.lvl
  crp
}

missegregateChr <- function(chrs=paste0("chr", 1:22)){
  ## Transcribed and estimated using Inkscape Scaling
  ## directly from Figure 1.I of the Worrell Paper
  ## representing % of Cells for single-cell nocodazole treatment
  chrcols <- c(4.75, 2.8, 2.8, 0.8, 0.8, 2.1,
               0, 2.1, 0.8, 1.5, 2.1, 1.5,
               2.1, 0, 0, 0, 0.8, 2.8, 0.8,
               2.1, 0.8, 0.8, 0.8)
  names(chrcols) <- c(chrs, "chrX")
  
  chrcols <- round(chrcols/max(chrcols), 3)
  chrcols
}

lohChr <- function(){
  loh=paste0("chr", c(1, 2, 3, 6, 8, 10, 11, 16, 18, 21, 22))
  ret=paste0("chr", c(4, 5, 7, 9, 12, 13, 14, 15, 17, 19, 20))

  chrcols <- rep(NA, length(chrs))
  names(chrcols) <- chrs
  chrcols[match(loh, chrs)] <- 'black'
  chrcols[match(ret, chrs)] <- 'white'
  chrcols
}

toFactor <- function(x){
  as.numeric(as.character(x))
}

plotBlank <- function(chr, xlim=c(0,1), ylim=NULL){
  if(is.null(ylim)) ylim <- (-1 * c(ucsc.spl[[chr]]$size, 1))
  plot(0, type='n', 
       xlim=xlim,  ylim=ylim, 
       axes=FALSE, lty=0, ylab='', xlab='')
}

plotChr <- function(chr, only.loh=FALSE, log2.range=FALSE){
  plotBlank(chr)
  
  .doPlot <- function(alpha=1, col.scheme=NULL){
    if(is.null(col.scheme)) cols <- lohColours() else cols <- col.scheme
    if(is.null(loh.tmp)) loh.tmp <- matrix(nrow = 0, ncol=1)
    if(nrow(loh.tmp) > 0){
      if(any(loh.tmp$CNt > 3) && each.disease != 'ccl') loh.tmp[which(loh.tmp$CNt > 3),]$CNt <- 3
      rect(xleft = 0, ybottom = (-1 * as.integer(loh.tmp$Start.bp)), 
           xright = 1, ytop = (-1 * as.integer(loh.tmp$End.bp)), 
           border=NA, 
           col=alpha(cols[as.character(loh.tmp$CNt)], alpha))
    }
  }
  if(only.loh){
    loh.tmp <- remove.factors(seg.spl[[chr]][which(seg.spl[[chr]]$LOH == 1),])
    .doPlot(alpha=1)
  } else if(log2.range){
    loh.tmp <- remove.factors(seg.spl[[chr]])
    loh.tmp$CNt <- round(loh.tmp$CNt, 1)
    .doPlot(alpha=1, col.scheme=log2Cols())
  } else if(!only.loh) {
    loh.tmp <- remove.factors(seg.spl[[chr]][which(seg.spl[[chr]]$LOH == 1),])
    .doPlot(alpha=1)
    loh.tmp <- remove.factors(seg.spl[[chr]][which(seg.spl[[chr]]$LOH == 0),])
    .doPlot(alpha=0.1)
  }
  
}

plotChrAxis <- function(chr){
  plot(0, type='n', 
       xlim=c(0,10),  ylim=c(0, 10.5), 
       axes=FALSE, lty=0, ylab='', xlab='')
  text(x=10, y = 5, labels = gsub("^chr", "", chr, ignore.case = TRUE), 
       pos = 2, cex=chr.cex)
  if(chr=='chr1') segments(x0 = 9,y0 = 10,x1 = 10,y1 = 10)
  segments(x0 = 9,y0 = 0,x1 = 10,y1 = 0)
  
  if(each.disease == 'pnets'){
    if(chr=='chr1') text(x=c(2,4), y=c(9.5, 9.5), labels=c("L", "M"), cex=0.5)
    #points(x=4, y=4, bg=alpha("black", missegregateChr()[chr]), pch=21)
    #points(x=2, y=4, bg=lohChr()[chr], pch=21)
  }
}

getMargins <- function(disease.idx){
  sample.id <- names(disease.list[[each.disease]])[disease.idx]
  if(length(sample.id) == 0) sample.id <- 'x'
  if(!is.na(match(sample.id, names(grp)))){
    p <- switch(grp[[sample.id]],
                "a"=c(0, sp1, 0, sp),
                "b"=c(0, sp, 0, sp1))
  } else {
    p <- c(0,sp,0,sp)
  }
  p
}

addRect <- function(inds, cols, ylim=c(0,2)){
  plotBlank('chr1', xlim=c(0,1), ylim=ylim)
  sapply(seq_along(inds), function(i){
    idx <- inds[[i]]
    rect(xleft = 0, ybottom = idx[1], 
         xright = 1, ytop = idx[2], 
         col=cols[i], border=FALSE)
  })
}

fixSeg <- function(seg, each.disease='x'){
  seg$modal_A1 <- rmFactor(seg$modal_A1)
  seg$Chromosome <- as.character(seg$Chromosome)
  seg$LOH <- rmFactor(seg$LOH)
  
  #modal_A2
  if(all(is.na(seg$modal_A2))){
    seg$modal_A2 <- 1
  }
  seg$modal_A2 <- rmFactor(seg$modal_A2)
  
  # Chromosome
  if(!any(grepl("chr", seg$Chromosome))){
    seg$Chromosome <- paste0("chr", seg$Chromosome)
  }
  seg <- seg[order(factor(seg$Chromosome, levels=chrs)),]
  
  # length
  seg$End.bp <- rmFactor(seg$End.bp) 
  seg$Start.bp <- rmFactor(seg$Start.bp)
  seg$length <- with(seg, End.bp - Start.bp)
  
  # CNt
  if(!any(grepl("CNt", colnames(seg)))){
    seg$modal_A1 <- rmFactor(seg$modal_A1) 
    seg$modal_A2 <- rmFactor(seg$modal_A2)
    seg$CNt <- with(seg, modal_A2 + modal_A1)
  }
  if(each.disease == 'ccl') seg$CNt <- '4'

  seg
}

rmFactor <- function(x){
  as.numeric(as.character(x))
}

## Compute all features by features cooccurence matrix
calcCo <- function(i,j,rand=FALSE){
  if(rand){
    i = i[sample(x=seq_along(i), size=length(i), replace = TRUE)]
    j = j[sample(x=seq_along(j), size=length(j), replace = TRUE)]
  }
  sum((i==1) & (j==1))/length(i)
}

genCoMat <- function(mat.x, rand=FALSE, N=1000){
  if(rand){
    co.mat <- lapply(1:N, function(n){
      apply(mat.x, 1, function(i, ...){
        apply(mat.x, 1, function(j, ...){
          round(calcCo(i, j, ...), 2)
        }, ...)
      }, rand=TRUE)
    })
  } else {
    co.mat <- apply(mat.x, 1, function(i, ...){
      apply(mat.x, 1, function(j, ...){
        round(calcCo(i, j, ...), 2)
      }, ...)
    }, rand=FALSE)
  }
  co.mat
}

getTransMats <- function(co.mat){
  .getTM <- function(co.mat){
    lapply(seq_along(chrs)[-1], function(chr.idx){
      chr.id1 <- paste0(chrs[chr.idx-1], "_")
      chr.id2 <- paste0(chrs[chr.idx], "_")
      
      co.mat[grep(chr.id2, colnames(co.mat)),
             grep(chr.id1, rownames(co.mat))]
    })
  }
  if(is.list(co.mat)) lapply(co.mat, .getTM) else .getTM(co.mat)
}

compChrCo <- function(tm, tn, thresh=c(0.33, 0.66), 
                      use.quant=TRUE, discretize=TRUE){
  lapply(seq_along(tm), function(chr.idx){
    dims <- dim(tm[[chr.idx]])
    tm.res <- sapply(1:dims[1], function(r.idx){
      sapply(1:dims[2], function(c.idx){
        null.vals <- sapply(tn, function(each.tn){
          if(length(tm) == 1){
            each.tn[r.idx, c.idx]
          } else {
            each.tn[[chr.idx]][r.idx, c.idx]
          }
          
        })
        if(use.quant){
          hi <- quantile(null.vals, thresh[2])
          lo <- quantile(null.vals, thresh[1])
        } else {
          hi <- median(null.vals) + (mad(null.vals) * thresh)
          lo <- median(null.vals) - (mad(null.vals) * thresh)
        }
        
        
        co.val <- tm[[chr.idx]][r.idx,c.idx]
        if(discretize){
          if(lo == hi){
            "negative"
          } else if(co.val >= lo & co.val <= hi){
            "random"
          } else if(co.val > hi){
            "positive"
          } else {
            "negative"
          }
        } else {
          if(lo == hi) null.vals <- c(500, 1000)
          round(ecdf(null.vals)(co.val),2) * 100
        }
        
      })
    })
    
    tm.res <- t(tm.res)
    colnames(tm.res) <- colnames(tm[[chr.idx]])
    rownames(tm.res) <- rownames(tm[[chr.idx]])
    tm.res
  })
}

###################
#### VARIABLES ####
mut.table <- read.csv("~/git/net-seq/cgh_analysis/data/pnet_mutations.csv",
                      header=TRUE, stringsAsFactors = FALSE, check.names = FALSE)
load("~/git/net-seq/cgh_analysis/data/chromInfo.Rdata")
load("~/git/net-seq/cgh_analysis/data/data.aggregateLoh.pnets.Rdata")
load("~/git/net-seq/cgh_analysis/data/genie_cn.Rdata")
load("~/git/net-seq/cgh_analysis/data/genie_mut.Rdata")
disease.list[['genie']] <- genie.cn_ord

out.dir <- file.path("/mnt/work1/users/pughlab/projects/NET-SEQ/loh_signature/plots", "loh_plots")
out.dir <- '~/Desktop/netseq/fig1_molProfile'
dir.create(out.dir)

only.loh <- FALSE # Set to FALSE if you want to plot nonLOH CN too

ucsc.spl <- split(ucsc.chrom, f=ucsc.chrom$chrom)
chrs <- paste0("chr", c(1:22))
sp <- 0.005
sp1 <- 0.5
chr.cex <- 0.7

cn.signature <- paste0("chr", c(paste0(c(1:3), "_Loss"),
                                paste0(c(4:5), "_Gain"),
                                paste0(c(6), "_Loss"),
                                paste0(c(7), "_Gain"),
                                paste0(c(8), "_Loss"),
                                paste0(c(9), "_Gain"),
                                paste0(c(10:11), "_Loss"),
                                paste0(c(12:14), "_Gain"),
                                paste0(c(15:16), "_Loss"),
                                paste0(c(17:20), "_Gain"),
                                paste0(c(21:22), "_Loss")))

######################
#### Plotting LOH ####
#disease.names <- c("pnets", "otb-pnet", "ccl")
for(each.disease in names(disease.list)){
  pdf(file.path(out.dir, paste0(each.disease, "_loh.pdf")), 
      height = 7, width = 2 + (0.02 * length(names(disease.list[[each.disease]]))))


  if(each.disease == 'pnets'){
    grp <- list("NET-003-T_1"="a",
                "NET-003-T_2"="b",
                "NET-009-T_1"="a",
                "NET-009-T_2"="b")
    
    sample.ord <- c('008', '001', '003', '009')
    sample.ord <- unlist(sapply(sample.ord, function(i) {
      grep(i, names(disease.list[[each.disease]]))
    }))
    disease.list[[each.disease]] <- disease.list[[each.disease]][sample.ord]
  } else if(each.disease == 'otb-pnet'){
    keep.idx <- names(disease.list[[each.disease]]) %in% colnames(mut.table)
    disease.list[[each.disease]] <- disease.list[[each.disease]][keep.idx]
    
    sample.ord <- order(factor(names(disease.list[[each.disease]]), 
                               levels=colnames(mut.table)))
    disease.list[[each.disease]] <- disease.list[[each.disease]][sample.ord]
  } else if(each.disease =='ccl'){
    names(disease.list[[each.disease]]) <- gsub("(?<!-)1$", "-1", 
                                                names(disease.list[[each.disease]]), perl=TRUE)
    
  }
  
  #######################
  #### VISUALIZATION ####
  {
    close.screen(all.screens=TRUE)
    main.spl <- split.screen(matrix(c(0,1,0.85,1,
                                      0,1,0.75,0.85,
                                      0,1,0.2,0.75,
                                      0,1,0,0.2), byrow = TRUE, ncol=4))
    mut.screen <- main.spl[1]
    frc.screen <- main.spl[2]; gen.loh <- list()
    loh.screen <- main.spl[3]
    sid.screen <- main.spl[4]
    
    #### Mutation ####
    ## Plot the Mutation track
    screen(mut.screen)
    dis.scrn <- split.screen(c(1, (length(disease.list[[each.disease]]) + 1)))
    for(disease.idx in dis.scrn){
      screen(disease.idx);
      
      disease.idx <- (disease.idx - min(dis.scrn))
      p <- getMargins(disease.idx)
      p[c(1, 3)] <- c(0.5, 1) # add bottom padding
      par(mar=p)
      
      if(disease.idx == 0){
        ## Plot the Diagnosis/Second biopsy labels
        plotBlank('chr1', xlim=c(0,10), ylim=c(0,4))
        text(x=rep(10, 4), y = c(0.5, 1.5, 2.5, 3.5), 
             cex=0.5, pos = 2, font=3,
             labels = c("TP53", "ATRX", "DAXX", "MEN1"))
      } else {
        ## Plot group inclusion
        sid <- names(disease.list[[each.disease]])[disease.idx]
        if(each.disease=='genie'){
          muts <- genie.mut_ord[,match(sid, colnames(genie.mut_ord))]
        } else {
          muts <- mut.table[,match(sid, colnames(mut.table))]
        }
        
        muts[is.na(muts)] <- "NA"
        idx <- list(c(0,1), c(1,2), c(2,3), c(3,4))
        
        addRect(idx, cols = rev(unlist(mutColours()[muts])), ylim=c(0,4))
        axis(side = 1, at=c(0,1), lwd.ticks = 0, labels=c("", ""))
      }
    }
    
    
    #### Sample ID ####
    ## Plot the Sample ID track
    screen(sid.screen)
    dis.scrn <- split.screen(c(1, (length(disease.list[[each.disease]]) + 1)))
    for(disease.idx in dis.scrn){
      screen(disease.idx);
      
      disease.idx <- (disease.idx - min(dis.scrn))
      p <- getMargins(disease.idx)
      p[c(1, 3)] <- c(4.1, 0.5) # add bottom padding
      par(mar=p)
      
      if(disease.idx == 0 & each.disease == 'pnets'){
        ## Plot the Diagnosis/Second biopsy labels
        plotBlank('chr1', xlim=c(0,10), ylim=c(0,2))
        text(rep(10, 2), y = c(0.5, 1.5), cex=0.5, pos = 2,
             labels = c("2nd biopsy", "Diagnosis"))
      } else if(disease.idx != 0) {
        ## Plot group inclusion
        sid <- names(disease.list[[each.disease]])[disease.idx]
        sid <- strsplit(sid, split="-")[[1]]
        idx <- switch(sid[3],
                      "T_1" = c(1, 2),
                      "T_2" = c(0, 1))
        if(each.disease == 'pnets') {
          addRect(list(idx), "black", ylim=c(0,2))
          axis(side = 3, at=c(0,1), lwd.ticks = 0, labels=c("", ""))
        } 
        if(each.disease == 'otb-pnet') sid[2] <- gsub("^0", "1", sid[2])
        axis(side = 1, at = 0.5, labels = paste(sid[1:2], collapse="-"), 
             las=2, cex.axis=0.7)
      }
    }
    
    #### LOH ####
    ## Plot the LOH Track
    screen(loh.screen)
    dis.scrn <- split.screen(c(1, (length(disease.list[[each.disease]]) + 1)))
    for(disease.idx in dis.scrn){
      screen(disease.idx);
      
      disease.idx <- (disease.idx - min(dis.scrn))
      p <- getMargins(disease.idx)
      
      if(disease.idx == 0){
        ## Plot the chromosome axes
        chr.scrn <- split.screen(c(length(chrs), 1))
        lapply(chrs, function(chr){
          screen(chr.scrn[match(chr, chrs)]); par(mar=c(0, 0, 0, 0))
          plotChrAxis(chr)
        })
      } else {
        ## Plot individual sample LOH per chromosome
        seg <- disease.list[[each.disease]][[disease.idx]]
        seg <- fixSeg(seg, each.disease=each.disease) # Sets CNt, length, and standardizes Chr name
        
        gen.loh[[disease.idx]] <- sum(seg[which(seg$LOH==1),]$length) / total.genome.size
        if(each.disease == 'genie') gen.loh[[disease.idx]] <- 0
        seg.spl <- split(seg, f=seg$Chromosome)
        
        chr.scrn <- split.screen(c(length(chrs), 1))
        lapply(chrs, function(chr){
          screen(chr.scrn[match(chr, chrs)]); par(mar=p)
          plotChr(chr, only.loh=only.loh, 
                  log2.range=if(each.disease == 'genie') TRUE else FALSE)
        })
      }
    }
    
    #### Fraction LOH ####
    ## Plot the Genomic LOH Track
    screen(frc.screen)
    dis.scrn <- split.screen(c(1, (length(disease.list[[each.disease]]) + 1)))
    for(disease.idx in dis.scrn){
      screen(disease.idx);
      
      disease.idx <- (disease.idx - min(dis.scrn))
      p <- getMargins(disease.idx)
      p[c(1,3)] <- c(0.5,0.1)
      par(mar=p)
      
      if(disease.idx == 0){
        ## Plot the Axis labels for the barplot
        plotBlank('chr1', xlim=c(0,10), ylim=c(0,11))
        gen.frac.scale <- seq(0, 10, by=2)
        text(x=rep(9, length(gen.frac.scale)), y=gen.frac.scale, 
             labels = gen.frac.scale*(100/max(gen.frac.scale)), 
             pos = 2, cex=0.5)
        segments(x0 = rep(9, length(gen.frac.scale)), y0 = gen.frac.scale ,
                 x1 = rep(10, length(gen.frac.scale)), y1 = gen.frac.scale)
      } else {
        ## Plot group inclusion
        plotBlank(chr, xlim=c(0,1), ylim=c(0,1.1))
        rect(xleft = 0, ybottom = 0,xright = 1,ytop = gen.loh[[disease.idx]],
             col="gray40", border=FALSE)
      }
    }
    close.screen(all.screens=TRUE)
  }
  dev.off()
}

###################
#### PWM: Functions ####
assignGroupIds <- function(mtbl, ids=NULL){
  mut.map <- c("MEN1"="M1", "DAXX"="D", "ATRX"="A", "TP53"="T")
  mut <- apply(mtbl, 2, function(i){
    paste(mut.map[names(which(!is.na(i)))], collapse="")
  })
  if(!is.null(ids)){
    id.bool <- sapply(ids, function(i) grep(i, mut))
    id.bool <- unique(sort(unlist(id.bool)))
    mut <- character(length(mut))
    mut[id.bool] <- paste(ids, collapse="")
    names(mut) <- colnames(mtbl)
  }
  mut
}
assignChromCnStat <- function(seg, stat, chr.thresh=0.6){
  .isWholeInt <- function(x){as.numeric(x)%%1==0}
  seg <- remove.factors(seg)
  seg <- fixSeg(seg)
  seg$Chromosome <- factor(as.character(seg$Chromosome), chrs)
  seg.spl <- split(seg, f=seg$Chromosome)
  
  sapply(seg.spl, function(seg.chr){
    seg.len <- sum(seg.chr$length)
    
    if(stat == 'loh'){
      loh.idx <- which(seg.chr$LOH == 1)
      loh.frac <- sum(seg.chr[loh.idx,]$length) / seg.len
      if(loh.frac > chr.thresh) 'LOH' else 'Het'
    } else if(stat == 'cn'){
      if(all(.isWholeInt(seg.chr$CNt))){
        l.idx <- seg.chr$CNt <= 1
        n.idx <- seg.chr$CNt == 2
        g.idx <- seg.chr$CNt >= 3
      } else {
        l.idx <- seg.chr$CNt <= -0.2
        n.idx <- with(seg.chr, CNt > -0.2 & CNt < 0.2)
        g.idx <- seg.chr$CNt >= 0.2
      }
      
      cn.frac <- c("Loss"=sum(seg.chr[l.idx,]$length) / seg.len,
                   "Neutral"=sum(seg.chr[n.idx,]$length) / seg.len,
                   "Gain"=sum(seg.chr[g.idx,]$length) / seg.len)
      names(which.max(cn.frac))
    } else {
      stop("'stat' must be either 'loh' or 'cn'")
    }
  })
}
splitMat <- function(grps, mats){
  lapply(grps, function(ids){
    m.idx <- match(names(ids), colnames(mats))
    if(any(is.na(m.idx))) m.idx <- m.idx[which(!is.na(m.idx))]

    if(length(m.idx) > 0){
      mats[,m.idx, drop=FALSE]
    } else { 
      na.m <- as.matrix(rep(NA, nrow(mats)))
      rownames(na.m) <- rownames(mats)
      na.m
    }
  })
}
plotPWM <- function(ppm, cols){
  ic <- ppm2ic(ppm)
  plot(0, type='n', xlim=c(0, ncol(ppm)), 
       ylim=c(0, log2(nrow(ppm))),
       xaxt='n', ylab='bits', las=2, xlab='')
  axis(side = 1, at = seq(0.5, ncol(ppm)-0.5, by=1),
       labels=colnames(ppm), las=2, cex.axis=0.7)
  ##Setup
  l <- substr(rownames(ppm), 1, 1)
  letters <- lapply(l, createPolygons, font='Arial')
  names(letters) <- l
  #cols <- c("red", "blue", "green"); #names(cols) <-  l
  
  
  # Go through each chromosome
  sapply(seq_along(ic), function(idx){
    ppm.ord <- sort(ppm[,idx])
    # Go through each letter and plot it for chr[X]
    sapply(seq_along(ppm.ord), function(ridx){
      y.height <- ic[idx] * ppm.ord
      y.scale <- y.height[ridx]
      y.adj <- sum(c(0, y.height[0:(ridx-1)]))
      
      letter.id <- substr(names(ppm.ord)[ridx], 1, 1)
      with(letters[[letter.id]], polygon(x=x + (idx - 1),
                                         y=(y*y.scale) + y.adj,
                                         col=cols[letter.id], border = NA))
      
    })
  })
}
ppm2ic <- function(pwm){
  npos <- ncol(pwm)
  ic <- numeric(length = npos)
  for (i in 1:npos) {
    ic[i] <- log2(nrow(pwm)) + sum(sapply(pwm[, i], function(x) {
      if (x > 0) {
        x * log2(x)
      } else {
        0
      }
    }))
  }
  ic
}
getPpm <- function(mat, lvl){
  .tbl2Df <- function(i){as.data.frame(t(as.matrix(i)))}

  cnts <- apply(mat, 1, function(i) .tbl2Df(table(i)))
  cnts[['levels']] <- data.frame(t(rep(NA, length(lvl))))
  colnames(cnts[['levels']]) <- lvl
  mat.cnt <- rbind.fill(cnts)[-length(cnts),]
  
  mat.ppm <- apply(mat.cnt, 1, function(i) i / sum(i, na.rm=TRUE))
  colnames(mat.ppm) <- rownames(mat)
  mat.ppm[is.na(mat.ppm)] <- 0
  
  mat.ppm
}

###################
#### PWM: Main ####
rownames(mut.table) <- mut.table$Genes
loh.grp.ids <- assignGroupIds(mut.table[,-1])
loh.mad.ids <- assignGroupIds(mut.table[,-1], c('M1', 'A', 'D'))
genie.grp.ids <- assignGroupIds(genie.mut_ord)
genie.mad.ids <- assignGroupIds(genie.mut_ord, c('M1', 'A', 'D'))
loh.grp.spl <- split(loh.grp.ids, f=loh.grp.ids)
loh.grp.spl[['M1AD']] <- split(loh.mad.ids, f=loh.mad.ids)[['M1AD']]
cn.grp.spl <- split(genie.grp.ids, f=genie.grp.ids)
cn.grp.spl[['M1AD']] <- split(genie.mad.ids, f=genie.mad.ids)[['M1AD']]

loh.mat <- lapply(disease.list[1:2], function(d) sapply(d, assignChromCnStat, stat='loh'))
cn.mat <- lapply(disease.list[c(1,2,4)], function(d) sapply(d, assignChromCnStat, stat='cn'))
loh.mat <- do.call("cbind", loh.mat)
cn.mat <- do.call("cbind", cn.mat)

cn.spl <- splitMat(cn.grp.spl, cn.mat)
cn.loh.spl <- splitMat(loh.grp.spl, cn.mat)
loh.spl <- splitMat(loh.grp.spl, loh.mat)

.getLevels <- function(x) {unique(sort(unlist(x)))}
cn.ppms <- lapply(cn.spl, getPpm, lvl=.getLevels(cn.mat))
cn.loh.ppms <- lapply(cn.loh.spl, getPpm, lvl=.getLevels(cn.mat))
loh.ppms <- lapply(loh.spl, getPpm, lvl=.getLevels(loh.mat))

pdf(file.path(out.dir, "cn-bits.pdf"), width=8, height=3)
cn.cols <- lohColours()
names(cn.cols) <- c("x", "L", "N", "G", "y")
sapply(cn.ppms[c(1, length(cn.ppms))], plotPWM, cols=cn.cols)
sapply(cn.loh.ppms[c(1, length(cn.loh.ppms))], plotPWM, cols=cn.cols)
dev.off()

pdf(file.path(out.dir, "loh-bits.pdf"), width=8, height=3)
loh.cols <- c("black", "grey")
names(loh.cols) <- c("L", "H")
sapply(loh.ppms['M1AD'], plotPWM, cols=loh.cols)
dev.off()

#############################
#### Co-occurence Matrix ####
## Binarize the feature by sample matrix
lvl <- c("Loss", "Neutral", "Gain") # lvl <- .getLevels(cn.mat)
lvl.cn.tmp <-lapply(lvl, function(lvl, cn.tmp){
  cn.tmp[cn.tmp==lvl] <- 1
  cn.tmp[cn.tmp!= 1] <- 0
  storage.mode(cn.tmp) <- "numeric"
  rownames(cn.tmp) <- paste(rownames(cn.tmp), lvl, sep="_")
  cn.tmp
}, cn.tmp = cn.spl[['M1AD']])
lvl.cn.tmp <- do.call("rbind", lvl.cn.tmp)

## Generate an all-by-all feature co-occurence matrix
co.mat <- genCoMat(lvl.cn.tmp, rand=FALSE)
null.mats <- genCoMat(lvl.cn.tmp, rand=TRUE) # Bootstraps segments WITHIN a sample

## Generate the transition matrix between chromosomes
trans.mat <- getTransMats(co.mat)
trans.nulls <- getTransMats(null.mats)

## Compare the transition matrix to a random null matrix
sig.trans <- compChrCo(trans.mat, trans.nulls, c(0.33, 0.66))
sig.co <- compChrCo(list(co.mat), null.mats, thresh=1, 
                    use.quant = FALSE, discretize = FALSE)

pdf(file.path(out.dir, "large_transition_mat.pdf"), width=40, height=10)
split.screen(c(1,4))
grps <- c("self", "Loss", "Neutral", "Gain")
sapply(grps, function(cn.change){
  screen(grep(cn.change, grps)); par(mar=c(6, 6, 4.1, 2.1))
  if(cn.change=='self'){
    cn.signature.comp <- cn.signature
  } else {
    cn.signature.comp <- paste0("chr", c(1:22), "_", cn.change)
  }
  sub.sig.co <- sig.co[[1]][cn.signature, cn.signature.comp]
  
  m <- sub.sig.co
  cols <- transColours()
  cols.ramp <- colorRampPalette(rev(cols[c(1,rep(2,3),3)]))(101)
  for(each.col in seq_along(cols)){
    m[m==names(cols)[each.col]] <- cols[each.col]
  }
  image(x=c(1:dim(m)[1]), y=c(1:dim(m)[2]),
        z=t(sub.sig.co), axes=FALSE, 
        col=cols.ramp, breaks=c(0:101),
        ylab='', xlab='', sub=cn.change)
  #cols=transColours()[t(sub.sig.co)]
  abline(h=seq(0.5, dim(m)[1]+0.5, by=1), col="white")
  abline(v=seq(0.5, dim(m)[1]+0.5, by=1), col="white")
  
  axis(side=1, at=c(1:22), labels = gsub("_.*", "", colnames(m)), las=2)
  axis(side=2, at=c(1:22), labels = rownames(m), las=1)
})
close.screen(all.screens=TRUE); dev.off()


pdf(file.path(out.dir, "transitionStates.pdf"), width = 14, height = 2.5)
split.screen(c(1, length(sig.trans)+2))
sapply(seq_along(sig.trans), function(idx){
  screen(idx+1); par(mar=c(5.1, 0.15, 4.1, 0.15))
  m <- sig.trans[[idx]]
  cols <- transColours()
  for(each.col in seq_along(cols)){
    m[m==names(cols)[each.col]] <- cols[each.col]
  }
  image(matrix(1:9, ncol=3), axes=FALSE, 
        col=transColours()[t(sig.trans[[idx]])])
  title(main=paste0(idx, "-", idx+1), line=0.2, cex=0.7)
  abline(h=c(0.25, 0.75), col="white")
  abline(v=c(0.25, 0.75), col="white")
})
close.screen(all.screens=TRUE);
dev.off() 

set.seed(1)
pdf(file.path(out.dir, "transitionLegend.pdf"), width = 3, height = 3)
image(matrix(1:9, ncol=3), axes=FALSE,
      ylab="chrB",
      col=sample(transColours(), 9, replace = TRUE))
title(main="A-B", line=0.2, cex=0.7)
title(xlab="chrA", line=1)
abline(h=c(0.25, 0.75), col="white")
abline(v=c(0.25, 0.75), col="white")
axis(side = 1, at = c(0, 0.5, 1), tick = FALSE,
     labels=c("Loss", "Neutral", "Gain"), line=-1)
axis(side = 2, at = c(0, 0.5, 1), tick = FALSE,
     labels=c("Loss", "Neutral", "Gain"), line=-1, las=2)

plot(0, type='n', axes=FALSE, xlab='', ylab='',
     xlim=c(0,10), ylim=c(0,3))
legend(x = 0, y = 3, fill = transColours(), legend = names(transColours()))
dev.off()


################
#### Legend ####
cols <- transColours()
colfunc <- colorRampPalette(rev(cols[c(1,rep(2,3),3)]))
legend_image <- rev(as.raster(matrix(colfunc(101), ncol=1)))
pdf(file.path(out.dir, "cooccur-legend.pdf"), width=3, height=6)
plot(c(0,4),c(0,1),type = 'n', axes = F,xlab = '', ylab = '')
text(x=1.2, y = seq(0,1,by=0.2), labels = seq(0,1,by=0.2), cex=0.7, adj=0)
text(x=1.9, y = c(0, 0.5, 1.0), labels = c("Mutually exclusive", "Random", "Co-occur"), adj=0, cex=0.7)
rasterImage(legend_image, 0, 0, 1,1)
dev.off()


cn.cols <- lohColours()
names(cn.cols) <- c("x", "L", "N", "G", "y")
mut.col <- mutColours()

pdf(file.path(out.dir, "legend.pdf"))
plot(0, type='n', xlim=c(1,10), ylim=c(1,10), axes=FALSE, xlab="", ylab="")
legend("topleft", fill=unlist(mut.col)[1:5], 
       legend = c("Insertion", "Deletion", "Nonsense", "Missense", "Splice"), 
       border = 0, box.lwd = 0)
legend("topright", fill=c(cn.cols[2:4], alpha(cn.cols[2:4], 0.1)), 
       legend = rep(c("Loss", "Neutral", "Gain"), 2), 
       border = 0, box.lwd = 0, ncol=2)
dev.off()