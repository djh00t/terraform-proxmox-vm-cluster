#!/bin/bash
###
### Update & Download all per-boot scripts in cloudinit managed VM
###
DIR="/etc/cloud/scripts/per-boot"

URLS=(
https://gist.githubusercontent.com/fsg-gitbot/e8729b10e585992fdff35d247319d775/raw/01-storage.sh
https://gist.githubusercontent.com/fsg-gitbot/a54170a504b02e9f10be032689434646/raw/02-hostname.sh
https://gist.githubusercontent.com/fsg-gitbot/309947929f56abd075c644c000f01c8d/raw/03-resolvconf.sh
https://gist.githubusercontent.com/fsg-gitbot/2eda62264e829345678662bc5477ef05/raw/04-route.sh
)

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