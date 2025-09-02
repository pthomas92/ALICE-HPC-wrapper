
##### setup #####

source('/home/ucbtpt0/Scratch/ALICE/ALICE.R')

library(tidyverse)
library(parallel)
library(doParallel)
library(foreach)

reformatDecomb <- function(x){
  
  x = x %>% 
    filter(productive == 'T') %>% 
    mutate(dedup_id = paste(v_call, j_call, junction)) %>% 
    group_by(dedup_id, v_call, j_call, junction, junction_aa) %>% 
    summarise(duplicate_count = sum(duplicate_count)) %>% 
    ungroup() %>% 
    distinct(dedup_id, .keep_all = T) %>% 
    select(-dedup_id) %>% 
    arrange(desc(duplicate_count)) %>% 
    mutate(Rank = 1:nrow(.),
           Read.proportion = duplicate_count / sum(duplicate_count)) %>% 
    dplyr::rename('Read.count' = duplicate_count,
                  'CDR3.nucleotide.sequence' = junction,
                  'CDR3.amino.acid.sequence' = junction_aa,
                  'bestVGene' = v_call,
                  'bestJGene' = j_call)
  
  return(x)
}
qcALICEList <- function(x){
  x[duplicated(names(x)) == F]
}
ALICE <- function(link, folder, nproc){
  
  f_ = as.data.table(reformatDecomb(data.table::fread(link)))
  f_ = split(f_, paste(f_$bestVGene, f_$bestJGene))
  f_ = f_[which(sapply(f_, nrow) > 1)]
  
  ALICE = ALICE_pipeline(DTlist = f_, folder = folder,
                         cores = nproc, iter = 10, nrec = 5e6)
  
  ALICE = qcALICEList(ALICE)
  ALICE = do.call('rbind', ALICE)
  return(ALICE)  
}

#####

##### parse command arguments #####

args = commandArgs(trailingOnly = T)

repertoire_loc = args[1]
repertoire_loc = gsub('/$', '', repertoire_loc) # trim trailing '/' for filepath creation
donor_classification_loc = args[2]
donor_classification_loc = gsub('/$', '', donor_classification_loc) # trim trailing '/' for filepath creation

#####

##### locate repertoires #####

outfiles = gsub('day', 'D', repertoire_loc)
outfiles = gsub('pre', 'D0', outfiles)

outfiles = basename(outfiles)
donor = sapply(strsplit(outfiles, '_'), function(x) x[3])
timepoint = sapply(strsplit(outfiles, '_'), function(x) x[4])
chain = unlist(sapply(strsplit(outfiles, '\\.'), function(x) gsub('^.*?_(\\w*?)$', '\\1', x[1])))

infile = repertoire_loc
outfile = paste(paste(donor, timepoint, chain, sep = '_'), 'ALICE-hits.csv', sep = '_')
outfolder = paste(donor, timepoint, sep = '-')

print(paste('Input file:', infile))
print(paste('Output file:', outfile))
print(paste('Output folder:', outfolder))
print(paste('Donor:', donor))
print(paste('Timepoint:', timepoint))
print(paste('Chain:', chain))

#####

##### read donor information and join information to beta_df #####

donor_types = lapply(list.files(donor_classification_loc,
                                full.names = T), read.delim, header = F)
names(donor_types) = sapply(strsplit(list.files(donor_classification_loc),
                                     '_'), function(x) x[1])

print(donor_types)

donor_types = do.call('rbind', donor_types) %>% 
  rownames_to_column('state') %>% 
  dplyr::rename('donor' = V1) %>% 
  mutate(state = gsub('\\..*?$', '', state),
         donor = as.character(donor))

print(donor_types)

state = donor_types$state[donor_types[, 2] == donor]

print(paste('State:', state))

#####

##### Run ALICE #####

n_cores <- as.integer(Sys.getenv("NSLOTS", unset = 1))
cl = makeCluster(n_cores)
registerDoParallel(cl)

cat('>Function input:\n\tInfile is: ', infile, '\n\tOutfolder is: ', outfolder, '\n\tCore count: ', n_cores, '\n\t: Outfile is: ', outfile, sep = '')

enriched = ALICE(link = infile,
                 folder = outfolder,
                 nproc = n_cores)

enriched$state = state

write.csv(enriched,
          file = paste(outfolder, outfile, sep = '/'),
          row.names = F)

stopCluster(cl)

#####


