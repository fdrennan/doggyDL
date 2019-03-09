
library(tidyverse)
library(imager)
library(lubridate)



system(
  paste0('aws s3 sync s3://couch-dog-photos/images ~/Documents/R/doggyDL/images')
)


filenames = base::list.files('images')

couch_images = map(
  filenames,
  function(x) {
    print(x)
    x %>% 
      paste0('images/', .) %>% 
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
  rename(size = value, 
         name = value1) %>%
  filter(size == 1920) %>% 
  mutate(time = str_remove(name, "image") %>% ymd_hms)


for(i in 1:(nrow(clean_images) - 1)) {
  new_mat = as.matrix(abs(clean_images$f1[[i+1]]) - abs(as.matrix(clean_images$f1[[i]])))
  print(i)
  new_mat[abs(new_mat) < .2] = 0
  diff = abs(sum(new_mat))
  print(diff)
  if(diff >= 500) {
    
    f1 = clean_images$name[[i+1]]
    f2 = clean_images$name[[i]]
    
    file.copy(
      paste0('images/',f1),
      paste0('activity/',f1)
    )
    
    file.copy(
      paste0('images/',f2),
      paste0('activity/',f2)
    )
    
    plot(as.cimg(new_mat))
  }
  
}



system(
  paste0('aws s3 cp activity/ s3://couch-dog-photos/activity/ --recursive')
)


system(
  "rm activity/*.jpg"
)
# 
# 
# 
# system(
#   paste0('aws s3 sync s3://couch-dog-photos/activity ~/Documents/R/doggyDL/activity')
# )
# 
# 
# 
