#!/bin/bash
#Download the latest release frome github
wget https://glare.now.sh/timvisee/ffsend/linux-x64-static

# Rename binary to ffsend
mv ./linux-x64-static ./ffsend

# Mark binary as executable
chmod a+x ./ffsend

# Move binary into path, to make it easily usable
mv ./ffsend /usr/local/bin/
echo -e "Congratulations, ffsend install completed!"

echo
echo "Welcome to visit:https://teddysun.com/357.html"
echo "Enjoy it!"