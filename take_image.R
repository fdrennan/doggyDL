#

time = Sys.time()
time = gsub(" ", "-", time)
filename = paste0('image',time,'.jpg')
system(paste0('fswebcam -r 1000X1000 --jpeg 85 -D 1 ',filename ,' -S 20'))
aws_path = paste0('/home/pi/.local/bin/aws s3 cp ', filename, ' s3://couch-dog-photos/', filename)
system(aws_path)
system(paste0('rm ', filename))
