# Backup Photos and Videos to Google Photos without using cloud storage

The scripts are designed to back up photos and videos from your phone via a remote server to your OG Pixel. It uses rsync to efficiently transfer only new or changed files, saving bandwidth and time. The script also checks for files deleted on the server (or are backed=up to Google Photos) and moves the corresponding files on your phone to a backup directory. This prevents accidental permanent deletion of your photos and videos.

## Workflow
- Take photos/videos on your main phone
- execute the [script](https://github.com/stephanschorer/googlephotos-unlimited/tree/main/scripts)
- photos/videos are uploaded to the remote server
- Syncthing Docker container syncs the photos/videos to the Pixel / Pixel XL
- Pixel / Pixel XL will upload the photos/videos to Google Photos
- [Automate](https://www.reddit.com/r/AutomateUser/) will auto 'Free Up Space' after defined time period
- At next [script](https://github.com/stephanschorer/googlephotos-unlimited/tree/main/scripts) execution all 'Freed up images/videos' will be moved into backup directory on the phone (can be changed ofc to be deleted).
- repeat

## Setup Client
- Install [Termux](https://f-droid.org/de/packages/com.termux/)
- Install [Termux:API](https://f-droid.org/de/packages/com.termux.api/)
- Install [Termux:Widget](https://f-droid.org/de/packages/com.termux.widget/)
- [Activate the storage in 
  Termux](https://wiki.termux.com/wiki/Internal_and_external_storage) with `termux-setup-storage`
- [Activate background activity in 
  Termux](https://wiki.termux.com/wiki/Termux-wake-lock) with `termux-wake-lock`
- Install the dependencies in Termux shell `apt install rsync openssh jq`.
- Create a SSH key for passwordless login
- Copy private key into local directory on the phone `$HOME/.ssh/id_rsa`
- Copy both scripts into `$HOME/.shortcuts/` folder
- Adjust the variables in scripts
- Use [Termux:Widget](https://f-droid.org/de/packages/com.termux.widget/) to create a shortcut of the script to your homescreen

## Setup Server
- Create new Linux user for the following
- Setup Syncthing Docker Container for example the one from [LinuxServer.io](https://docs.linuxserver.io/images/docker-syncthing/#application-setup:~:text=must%20be%20provided.-,docker%2Dcompose%20(recommended%2C%20click%20here%20for%20more%20info),-%C2%B6)
- Remeber to set the correct ownership: `chown -R user:user /path/to/dir`

## Setup Pixel / Pixel XL
Read through these Reddit posts, there you will find all you need to know:
- [Free Unlimited Google Photos Storage with an OG Pixel: A Detailed Setup](https://www.reddit.com/r/googlephotos/comments/1g1ryxb/free_unlimited_google_photos_storage_with_an_og/)
- [My Unlimited GooglePhotos setup (Details in Comment)](https://www.reddit.com/r/DataHoarder/comments/wy6r18/my_unlimited_googlephotos_setup_details_in_comment/)
