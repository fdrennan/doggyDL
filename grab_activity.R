rm(list = ls())
library(tidyverse)
library(imager)
library(lubridate)

local = "/Users/digitalfirstmedia/Documents/R/doggyDL"
if(getwd() == local) {
  path = local
  aws = "aws"
} else {
  path = '/home/keras/doggyDL/'
  aws = '/home/keras/.local/bin/aws'
}


  
system(
  paste0(aws, ' s3 sync s3://couch-dog-photos/images ', path, '/images')
)

filenames = base::list.files('images')

if(length(filenames) < 2) {
  
  stop(paste0("Not enough files ", length(filenames)))
}



run_batch = function(filenames, path) {
    couch_images = map(
    filenames,
      function(x) {
        print(x)
        x %>% 
          paste0(path, '/images/', .) %>% 
          load.image() %>% 
          as.array()
    }
  )
    
    couch_images = map2_df(
    couch_images,
    filenames,
    function(x, y) {
      data = bind_cols(nest(as_tibble(x[,,,1])), 
                       nest(as_tibble(x[,,,2])), 
                       nest(as_tibble(x[,,,3])), 
                       nest(as_tibble(dim(x)[[1]])),
                       nest(as_tibble(y)))
      colnames(data) = c('f1', 'f2', 'f3', 'size', 'name')
      data
    }
  )
  
  clean_images <- couch_images %>% 
  unnest(size) %>% 
  unnest(name) %>% 
  dplyr::rename(size = value, 
         name = value1) %>%
  filter(size == 1920) %>% 
  mutate(time = str_remove(name, "image") %>% ymd_hms)
  
  
  for(i in 1:(nrow(clean_images) - 1)) {
  new_mat = as.matrix(abs(clean_images$f1[[i+1]]) - abs(as.matrix(clean_images$f1[[i]])))
  print(i)
  new_mat[abs(new_mat) < .2] = 0
  diff = abs(sum(new_mat))
  print(diff)
  if(diff >= 100) {
    
    f1 = clean_images$name[[i+1]]
    f2 = clean_images$name[[i]]
    
    file.copy(
      paste0(path, '/images/',f1),
      paste0(path, '/activity/',f1)
    )
    
    file.copy(
      paste0(path, '/images/',f2),
      paste0(path,'/activity/',f2)
    )
    
    # plot(as.cimg(new_mat))
  }

}


  
}

n_batches = length(filenames) - 1
batch_step = 2

for(i in (1:n_batches - 1)) {
  run_batch(filenames = filenames[(1:batch_step) + i][!is.na(filenames[(1:batch_step) + i] )], path = path)
}


system(
  paste0(aws, ' s3 rm s3://couch-dog-photos/images/ --recursive')
) 

system(
  paste0('rm ', path, '/images/*.jpg')
) 
# 
system(
  paste0(aws, ' s3 cp ', path, '/activity/ s3://couch-dog-photos/activity/ --recursive')
)

# 
# 
# 
system(
   paste0("rm ", path, "/activity/*.jpg")
) 
# 
# 
# 
# system(
#    paste0('/home/keras/.local/bin/aws s3 sync s3://couch-dog-photos/activity /home/keras/doggyDL/activity')
# )
# 


