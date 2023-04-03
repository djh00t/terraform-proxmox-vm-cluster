#!/bin/bash
###
### Update & Download all per-boot scripts in cloudinit managed VM
###
DIR="/etc/cloud/scripts/per-boot"

URLS=(
https://gist.githubusercontent.com/djh00t/d0005cb21471ed2108e72b2f4b532322/raw/01-storage.sh
https://gist.githubusercontent.com/djh00t/989f370e04f37ed5de05987df7616d40/raw/02-hostname.sh
https://gist.githubusercontent.com/djh00t/d2afe0aa6237da8c9c87673b56755e68/raw/03-resolvconf.sh
https://gist.githubusercontent.com/djh00t/7ea05500acdbcf201df4057e436d8851/raw/04-route.sh
)

# Make sure $DIR exists, if it doesn't, create it otherwise skip
if [ ! -d $DIR ]; then
        mkdir -p $DIR
fi


# Download gists
for url in ${URLS[@]};do
        # Extract filename from URL
        FILE=$(basename $url)

        # Get file, saving to $DIR/$FILE
        curl -s -o $DIR/$FILE $url

        # Run all files direct from URL
        curl -s $url | bash
done

# Make executable
chmod +x $DIR/*.sh