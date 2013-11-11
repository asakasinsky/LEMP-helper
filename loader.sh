
wget https://github.com/asakasinsky/LEMP-helper/archive/master.tar.gz 

tar xpvf master.tar.gz && mv LEMP-helper-master lemp-helper

for file in `find lemp-helper/tools -type f -name "*.sh"`
do
  chmod +x $file 
done

rm lemp-helper/loader.sh

# Ought to do the trick. $0 is a magic variable for the full path of the executed script.
# Thanks to http://stackoverflow.com/questions/8981164/self-deleting-shell-script
rm -- "$0"

